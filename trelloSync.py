#!/usr/bin/env python
# encoding: utf-8
"""
trelloSync.py

Originally created by Kent Quirk on 05/15/14.
Copyright (c) 2014 Kent J. Quirk. All rights reserved.

To get a trello token, do this:

https://trello.com/1/authorize?key=THEKEY&name=trelloSync&expiration=30days&response_type=token&scope=read,write
See https://trello.com/docs/gettingstarted/index.html#getting-a-token-from-a-user

This uses the trolly library for trello access from python:
https://github.com/plish/Trolly

It uses the github3 library for github access from python:
http://github3py.readthedocs.org/
"""

import os
import re
import sys
import json
import argparse

from github3 import login

from trolly.client import Client
from trolly.organisation import Organisation
from trolly.board import Board
from trolly.list import List
from trolly.card import Card
from trolly.checklist import Checklist
from trolly.member import Member
from trolly import ResourceUnavailable



class GitClient(object):
    """docstring for GitClient"""
    def __init__(self, gitConfig):
        super(GitClient, self).__init__()
        self.gitConfig = gitConfig
        self.gitClient = login(token=gitConfig['token'])
        self.orgname = gitConfig['org']
        self.repos = gitConfig['repos']
        self.org = self.gitClient.organization(self.orgname)

    def getIssue(self, repo, issueNum):
        issue = self.gitClient.issue(self.orgname, repo, issueNum)
        return issue

# dir(issue) 
# ['__class__', '__delattr__', '__dict__', '__doc__', '__eq__',
# '__format__', '__getattribute__', '__hash__', '__init__', '__module__',
# '__ne__', '__new__', '__reduce__', '__reduce_ex__', '__repr__', '__setattr__',
# '__sizeof__', '__str__', '__subclasshook__', '__weakref__', '_api',
# '_boolean', '_build_url', '_delete', '_get', '_github_url', '_iter', '_json',
# '_json_data', '_patch', '_post', '_put', '_remove_none', '_session',
# '_strptime', '_uniq', '_update_', '_uri', 'add_labels', 'assign', 'assignee',
# 'body', 'body_html', 'body_text', 'close', 'closed_at', 'closed_by',
# 'comment', 'comments', 'comments_url', 'create_comment', 'created_at', 'edit',
# 'etag', 'events_url', 'from_json', 'html_url', 'id', 'is_closed',
# 'iter_comments', 'iter_events', 'labels', 'labels_urlt', 'last_modified',
# 'milestone', 'number', 'pull_request', 'ratelimit_remaining', 'refresh',
# 'remove_all_labels', 'remove_label', 'reopen', 'replace_labels', 'repository',
# 'state', 'title', 'to_json', 'updated_at', 'user']

    def backlinkToTrello(self, repo, issueNum, trellolink, trelloname):
        cardlinkpat = re.compile("(https://trello.com/c/[a-zA-Z0-9]+)")
        # we're going to ignore boardlinks for now
        # boardlink = "(https://trello.com/b/[a-zA-Z0-9])+"
        issue = self.getIssue(repo, issueNum)
        if not issue.closed_at:
            issueText = issue.body + '\n' + '\n'.join([cmt.body for cmt in issue.iter_comments()])
            cardlinks = cardlinkpat.findall(issueText)
            if trellolink not in cardlinks:
                print issueText
                print trellolink
                print cardlinks
                xxx
                name = trelloname[:40]
                if len(trelloname) > 40:
                    name += '...'
                newbody = issue.body + '\n\nTrello: [%s](%s)\n' % (name, trellolink)
                print "%s / %s" % (repo, issueNum)
                issue.edit(body=newbody)

        # if not issue.closed_at:
            # we only modify open issues


class MyCard(object):
    """Adapts a Card to make it easier to do a couple of things missing from the Trolly API"""
    def __init__(self, card):
        self.card = card

    def getComments(self):
        """
        Get all comments attached to this card. Returns a list of strings.
        """
        query = self.card.fetchJson(
                uri_path = self.card.base_uri,
                http_method = 'GET',
                query_params = { "actions": "all" }
            )

        comments = []
        for item in query['actions']:
            if item['type'] == 'commentCard':
                comments.append(item['data']['text'])
        return comments

        

class TrelloClient(object):
    """Manages a connection to Trello and loads the desired boards"""
    def __init__(self, trConfig):
        super(TrelloClient, self).__init__()
        self.trConfig = trConfig
        self.trClient = Client(self.trConfig['key'], self.trConfig['token'])
        self.org = Organisation(self.trClient, self.trConfig['orgid'])
        self.getBoards(self.trConfig['boards'].keys())

    def getOrgInfo(self):
        orginfo = self.org.getOrganisationInformation()
        return orginfo

    def getBoards(self, names=[]):
        # caches the board information in self.boards
        self.boards = dict()
        boards = self.org.getBoards()
        for b in boards:
            binfo = b.getBoardInformation()
            if binfo['name'] in names:
                self.boards[binfo['name']] = b
            elif binfo['id'] in names:
                # you can specify the hex id instead of the name in case someone edits the name
                self.boards[binfo['id']] = b
        return self.boards
        
    def getLists(self, boardId):
        exclude = self.trConfig['boards'][boardId].get('exclude', [])
        include = self.trConfig['boards'][boardId].get('include', [])
        board = self.boards[boardId]
        # print dir(board)
        lists = board.getLists()
        def isIncluded(l):
            return (
                (include and l.name in include) or 
                (exclude and l.name not in exclude) or 
                (not (include or exclude))
                )

        return [l for l in lists if isIncluded(l)]

    def getCards(self, list):
        cards = list.getCards()
        return cards

    def dumpCard(self, card):
        print card.getCardInformation()  #['shortUrl']

    def getCommentsForCard(self, card):
        mc = MyCard(card)
        return mc.getComments()
        
    def updateLinksToGit(self, card, repos, gitClient):
        '''
        This fetches all the comments and the card description, and then parses them
        all for things that look like github links or references. If it finds any, it
        adds a link to the description (if it doesn't already exist). A link is a normal
        url, while a reference looks like hub #23 -- reponame #number. Only repos that
        are listed in the repos parameter are used.
        '''
        allrepos = '|'.join(repos)
        comments = '\n'.join(self.getCommentsForCard(card))
        # https://github.com/tidepool-org/hub/issues/20
        longonly = re.compile("https?://github.com/tidepool-org/(?P<repo>%s)/issues/(?P<issue>[0-9]+)" % allrepos)
        longandshort = re.compile("(?:https?://github.com/tidepool-org/)?(?P<repo>%s)(?:/issues/|[ ]*#)(?P<issue>[0-9]+)" % allrepos)
        hits = longandshort.findall(comments)
        if hits:
            info = card.getCardInformation()
            desc = info['desc']
            links = longonly.findall(desc)
            changed = False
            for h in hits:
                gitClient.backlinkToTrello(h[0], h[1], info['shortUrl'], info['name'])
                if h not in links:
                    desc += '\nhttps://github.com/tidepool-org/%s/issues/%s' % h
                    changed = True
            if changed:
                card.updateCard({"desc": desc})
                print "    Updated '%s'" % info['name']

def main(argv=None):
    parser = argparse.ArgumentParser(description='App to sync trello cards and github issues')
    # arg*<tab>
    parser.add_argument("--config", "-c", dest="config", nargs='?', type=argparse.FileType('r'), 
                    default='trelloSync.json', const=None, metavar="CONFIG",
                    help="Specify the configuration file (%default)")

    args = parser.parse_args()
    #print args
    config = json.loads(args.config.read())


    ghc = GitClient(config['github'])
    # xxx


    trc = TrelloClient(config['trello'])
    for boardname in config['trello']['boards'].keys():
        print "-- Trello board %s --" % boardname
        lists = trc.getLists(boardname)
        for l in lists:
            print "  %s" % l.name
            cards = trc.getCards(l)
            for c in cards:
                # trc.dumpCard(c)
                trc.updateLinksToGit(c, config['github']['repos'], ghc)

    return 0

if __name__ == "__main__":
    rv = main()
    if rv:
        sys.stderr.write("Failed. Use --help for full instructions.\n")
        sys.exit(rv)
    else:
        sys.exit(0)
    