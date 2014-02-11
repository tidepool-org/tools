#!/usr/bin/env python
# encoding: utf-8
"""
addLicense.py

Originally created by Kent Quirk on 09/20/13.
Copyright (c) 2013 Tidepool.org. 
"""

import os
import re
import sys
import glob
import fnmatch
import argparse
import datetime

# Retrieves the license body from a file by tagname, and if that fails, gets the generic version.
def getLicenseBody(tagtext, fallbackname):
    def tryopen(fname):
        try:
            licensebody = open(fname).readlines()
        except IOError:
            p = os.path.split(sys.argv[0])[0]
            licfile = os.path.join(p, fname)
            try:
                licensebody = open(licfile).readlines()
            except IOError:
                licensebody = None
        return licensebody

    fname = tagtext.replace(' ', '_').upper() + '.tmpl'
    ret = tryopen(fname)
    if not ret:
        ret = tryopen(fallbackname)
    return ret

# Processes a single file, writing the output to outfile if specified (outfile can be
# the same as infile)
# Tag is the pattern we search for -- it should include parentheses to identify a regex group
# containing the portion of the tag that identifies the license name. 
# Fallbackname is the name of the license to use if we don't find the one named in the tag.
def process(infile, outfile, tag, fallbackname):
    tagpat = re.compile("(.*)" + tag + "(.*)")   # so we can extract comment markers
    coprpat = re.compile("[Cc]opyright|[Cc]opr|\([Cc]\)|©")
    yearpat = re.compile("[0-9]{4}")

    # we want to process as lines, not a stream
    contents = open(infile).readlines()
    tag1 = -1
    tag2 = -1

    # find the begin / end tags
    for i, line in enumerate(contents):
        match = tagpat.match(line)
        if match:
            if tag1 == -1:
                prefix, tagtext, suffix = match.groups()
                tag1 = i
            else:
                p2, tagtext, suffix = match.groups()
                tag2 = i
                break

    # no first tag? We're done
    if tag1 == -1:
        return False

    licensebody = getLicenseBody(tagtext, fallbackname)
    if not licensebody:
        return False

    if tag2 == -1:
        # no second tag
        tag2 = tag1
        if suffix:
            startblock = prefix + tag + '\n'
            endblock = (" " * len(prefix)) + tag + suffix + '\n'
        else:
            startblock = contents[tag1]
            endblock = startblock
    else:
        startblock = contents[tag1]
        endblock = contents[tag2]

    if suffix:
        prefix = " " * len(prefix)

    # extract the copyright years if there were any
    years = set()
    # start with this year
    years.add(str(datetime.datetime.now().year))
    # and see if there are others
    for line in contents[tag1+1: tag2-1]:
        if coprpat.search(line):
            years.update([y for y in yearpat.findall(line)])
            break

    # now generate an updated license with all the years mentioned
    y = dict(years=', '.join(sorted(years)))
    inserttext = [prefix + (l % y) for l in licensebody]
    newcontents = contents[:tag1] + [startblock] + inserttext + [endblock] + contents[tag2+1:]
    if outfile:
        f = open(outfile, 'w')
        for l in newcontents:
            f.write(l)
        f.close()
    return True

# Look for .gitignore; this only looks in the current directory.
# Properly handling .gitignore in a parent directory is painful, so 
# we'll leave that for some future time.
def find_ignorefile(p, ignorefile='.gitignore'):
    f = os.path.join(p, ignorefile)
    if os.path.exists(f):
        return f
    else:
        #sys.stderr.write('No %s found.\n' % ignorefile)
        return None

# Does the equivalent of a glob, except it walks directory trees and 
# returns all the files that match.
def deep_glob(start, pat):
    matches = []
    for path, dirnames, filenames in os.walk(start):
        # print path, dirnames, filenames
        dirnames[:] = [d for d in dirnames if not d.startswith('.')]
        # print dirnames
        for filename in fnmatch.filter(filenames, pat):
            matches.append(os.path.join(path, filename))
    return matches

# reads .gitignore if it exists and gets a list of files to exclude
# Every file returned has the full path
def get_exclude_patterns():
    ignorepats = set()
    for fname in ['.gitignore', '.licignore']:
        ignorepath = find_ignorefile(os.path.realpath('.'), ignorefile=fname)
        if ignorepath:
            ignorepats.update(open(ignorepath).read().split('\n'));
    return ignorepats

# Generates a set of files according to a bunch of patterns like you 
# see in .gitignore. It does not support the full syntax of .gitignore
# but filenames, directory names, and file patterns with or without 
# subdirectories are supported. ! lines are ignored which in this 
# use case won't matter.
def process_pats(pats):
    files = set()
    root = os.path.realpath('.')
    for i in pats:
        if (not i) or i.startswith('!'):
            continue
        if '/' in i:
            p, f = os.path.split(i)
            files.update(deep_glob(os.path.join(root, p), f))
        elif os.path.isdir(i):
            files.update(deep_glob(os.path.join(root, i), '*'))
        else:
            files.update(deep_glob(root, i))
    return files

# Does the real work -- generate a set of excludes and includes, and 
# subtract one from the other.
def get_filelist(pats):
    excludes = process_pats(get_exclude_patterns())
    includes = process_pats(pats)
    result = includes.difference(excludes)
    # print result
    return result

def main(argv=None):
    parser = argparse.ArgumentParser(description='''Adds or updates the license text in one or more files.
                    Looks for tag matching the tag pattern in the files specified; if it finds it once,
                    appends the contents of the license file plus a second marker; if it finds it 
                    twice, replaces the text between.
                    All the text is wrapped in the same characters from the line that contains the first 
                    tag (which are presumably the comment markers).
                    If the text between contains a pattern that looks like years after a copyright
                    statement, the copyright years will be extracted. 
                    The pattern %(years)s in the copyright template will be replaced with the list 
                    of years, including the current year.
                    Any files or folders listed in .gitignore or in .licignore (same syntax) will be ignored.
                    ''')
    parser.add_argument(dest='files', metavar='FILE', nargs='*',
                    help='A list of files to be processed. OS-style wildcards are allowed.')
    parser.add_argument('--tag', dest='tag', nargs=1, 
                    default="== ([A-Z0-9 ]+ LICENSE) ==",  
                    help="set the regex used to find a license marker in a file '%(default)s'. "
                    "The regex must include parentheses to mark the filename matching part.", 
                    metavar="REGEX")
    parser.add_argument("--license", dest="license", nargs=1, default="license.tmpl",
                    help="define the license template file", metavar="LICENSE")
    parser.add_argument("--dry-run", dest="dryrun", default=False, action="store_true",
                    help="scan the files and emit the names that match the tag, but make no changes.")
    parser.add_argument("--missing", "-m", dest="missing", default=False, action="store_true",
                    help="generate a list of the files in the list that are missing license tags"
                    "(makes no changes)")

    args = parser.parse_args()

    if args.missing:
        args.dryrun = True

    if not args.files:
        args.files = ['*.js', '*.py', '*.coffee', 'LICENSE']
    files = get_filelist(args.files)
    for f in files:
        if os.path.isfile(f):
            if args.dryrun:
                outfile = None
            else:
                outfile = f
            if process(f, outfile, args.tag, args.license) != args.missing:
                print(f)

    return 0

if __name__ == "__main__":
    rv = main()
    if rv:
        sys.stderr.write("Failed. Use --help for full instructions.\n")
        sys.exit(rv)
    else:
        sys.exit(0)
        