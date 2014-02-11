#!/usr/bin/env python
# encoding: utf-8
"""
extractDocs.py

Originally created by Kent Quirk on 02/06/14.
Copyright (c) 2014 Tidepool.org. 
"""

import os
import re
import sys
import glob
import json
import fnmatch
import argparse
import datetime

# we use this global variable to maintain the current order value
g_cur_order = 1000

# Processes a single file
# textbody is the contents of the file
def blockgen(textbody):
    blockpat = re.compile("/\*\*\*+(.*?)\s*\*+/", re.DOTALL)
    blocks = blockpat.findall(textbody)
    for block in blocks:
        yield block

def chunkgen(block, formatters):
    chunkpat = re.compile("[ *\t]* (?P<name>[A-Z][A-Za-z0-9_-]+):\s*(?P<body>.*)")
    directivepat = re.compile("\(\[(?P<directive>[a-z]+)\s*[=:]\s*(?P<value>.*)\]\)")
    id = ''
    body = []
    cur_formatter = None
    global g_cur_order
    for line in block.split('\n'):
        # first see if there's a directive on the line; if so, process it
        #print ('order: %s line: "%s"' % (g_cur_order, line))
        directive = directivepat.search(line)
        if directive:
            if directive.groupdict()['directive'] == 'order':
                g_cur_order = int(directive.groupdict()['value'])
            # remove the directive from the output
            line = line[:directive.start()] + line[directive.end():]

        # now look for chunks
        m = chunkpat.match(line)
        if m:
            # if there's an id, we're already processing a chunk, so end it
            if id:
                yield id, cur_formatter, body

            # and start a new one
            id = m.groupdict()['name']
            body = [m.groupdict()['body']]
            g_cur_order = int(m.groupdict().get('order', g_cur_order+1))
            cur_formatter = formatters.get(id, formatters['_default'])
        else:
            # this is a line in a block that not the start of a chunk
            #print "raw line, no chunk"
            body.append(line)
            # if we have no id, it's at the start of a block with no chunk, so set one up
            if not id:
                id = '_'
            cur_formatter = formatters.get(id, formatters['_default'])
            g_cur_order += 1

    # make sure we yield the last chunk in the block
    yield id, cur_formatter, body

def process(infile, formatters):
    global g_cur_order
    textbody = open(infile).read()
    result = {}
    print "************" + infile

    for block in blockgen(textbody):
        for id, formatter, body in chunkgen(block, formatters):
            if body:
                text = ''
                for line in body:
                    newtext = None
                    # print('id: %s, line: "%s"' % (id, line))
                    found = False
                    for item in formatter:
                        m = re.search(item['pattern'], line)
                        if m:
                            d = dict(blockid=id)
                            d.update(m.groupdict())
                            newtext = item['formatter'] % d
                            # print("Formatter found: newtext='%s'" % newtext)
                            found = True
                            break
                    if newtext is None and line:
                        # print("No formatter found.")
                        newtext = '%s\n' % line
                    # if not found:
                    #     print("NOT FOUND '%s'" % newtext)

                    if newtext is not None:
                        text += newtext
                result[g_cur_order] = text
    return result



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
        if i.startswith('/'):
            i = os.path.join(root, i[1:])
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
    parser = argparse.ArgumentParser(description='''
        Reads a set of source files and extracts documentation.

        The files explored are specified either on the command line with the --files switch
        or in an options file. OS-style wildcards are supported.

        Files listed in .gitignore or .docignore are always ignored (even if included in the
        include list).

        Files are searched for blocks between documentation markers. Documentation blocks 
        start with /*** (3 or more *s) and end with */ (1 or more stars).
        All lines between these markers are extracted.

        The text in blocks is searched to find lines that start with a single
        word that begins with a capital letter and ends with a colon (:). These lines
        are used to define chunks that begin after the colon and end with the last line
        before the next chunk. 

        The starting word is a label that is used to look up a formatter, then the 
        block is passed through the formatter to produce a chunk of output text, along with 
        sequence information.

        The output text is then sent to the output file. Before being written to, the output 
        file is scanned for a special tag (by default, "# Docs"). If the tag is found, everything
        that comes before it is preserved (and everything after it is overwritten).

        Formatters are defined in an options file, called "docoptions.json" by default. 

        The options file is a dictionary with several keys. Valid keys include:

        output: The name of the output file
        files: An array containing filenames or filename patterns to process
        tag: The string used to mark the header in the output file
        formats: A dictionary defining formats (see below)

        -- The formats dictionary --

        Each formatter has a key of the label (the name of the label being matched, without the
        colon), and the value being an array containing one or more dictionaries, each with keys of 
        pattern, formatter, and possibly order.

        If the label specified by the chunk is not found, then the formatter with the name
        of "_default" is used. 

        After finding the formatter for a chunk, the array of formats is compared in sequence with
        the pattern (a regular expression) against each line of the output; when the first match is 
        found, the corresponding formatter is used to render the matched pattern.

        The order property, if it exists, must be an integer, and is used to establish the relative
        ordering of the output. If it does not exist, the default value will be one more than the 
        previous entry.

        If the value corresponding to a label is a string instead of an object, then it's considered 
        to be an alias.

        Example:

        "Function": [{
            pattern: "(?P<funcname>[A-Za-z0-9$_]+)\s*\((?P<args>[^\)]*)\)",
            formatter: "* ```**%%(funcname)s** (%%(args)s)```"
        }],
        "Method": "Function"

        Directives to the system can be embedded in comment blocks and have 
        the form: ([keyword=value])

        So far, the only directive is 'order'. If specified, the current value of
        order is set to value at the point when it is evaluated. This can 
        be used to sequence a set of multiple files or to reorder items within 
        a file. Order starts at a value of 1000.

        Any files or folders listed in .gitignore or in .docignore (same syntax) 
        will be ignored, even if specified on the command line or in the options file.

        The output file defaults to docs.md, but can be overridden by an option or by
        a command line switch.
        ''')
    parser.add_argument(dest='files', metavar='FILE', nargs='*',
                    help='A list of files to be processed. OS-style wildcards are allowed.')
    parser.add_argument("--output", "-O", dest="output", nargs=1, default="docs.md",
                    help="define the output template file", metavar="LICENSE")
    parser.add_argument("--options", "-o", dest="options", default='docoptions.json', 
                    help="Specify the JSON file containing option definitions.", 
                    metavar="OPTIONS")
    parser.add_argument("--tag", "-t", dest="tag", default='# Docs', 
                    help="The output file is searched for this tag; if found, it and everything"
                    " before it is preserved.", metavar="TAG")
    parser.add_argument("--debug", "-d", dest="debug", default=False, action="store_true",
                    help="Set this if you're trying to debug your formatters and extra info"
                    "will be written to the output file.")

    args = parser.parse_args()
    app_path = os.path.split(sys.argv[0])[0]

    # look for the option file either in the current folder or, if that fails, in the 
    # folder containing the .py file
    try:
        optfile = open(args.options)
    except IOError:
        try:
            optfile = open(os.path.join(app_path, args.options))
        except IOError:
            print("Couldn't find %s to load options." % args.options)
            exit(1)

    options = json.loads(optfile.read())

    formatters = options['formats']
    # if there are indirect formats, make them direct
    for f in formatters:
        if not isinstance(formatters[f], list):
            formatters[f] = formatters[formatters[f]]

    # load the files specified
    # command line wins, then options file -- or if all else fails, just
    # read all the .js files
    if not args.files:
        if 'files' in options:
            args.files = options['files']
        else:
            args.files = ['*.js']
    files = get_filelist(args.files)

    # iterate over all the files and compile all the output data
    output = {}
    for f in files:
        if os.path.isfile(f):
            readfile = f
            output.update(process(f, formatters=formatters))

    # import pprint
    # pprint.pprint(output)

    if 'tag' in options:
        args.tag = options['tag']

    # search for the tag in the output file; if it exists, write the prefix
    # to the output file before we do anything else
    try:
        outfilename = options['output']
    except KeyError:
        outfilename = args.output

    contents = ''
    try:
        filedata = open(outfilename).read()
        tagloc = filedata.index(args.tag)
        contents = filedata[:tagloc + len(args.tag)]
    except IOError:
        pass  # output hasn't been created yet
    except ValueError:
        pass  # tag wasn't found in the file

    outfile = open(outfilename, 'w')
    outfile.write(contents)
    for name in sorted(output.keys()):
        if args.debug:
            outfile.write('%s: %s' % (name, output[name]))
        else:
            outfile.write('%s' % output[name])
    outfile.close()

    return 0

if __name__ == "__main__":
    rv = main()
    if rv:
        sys.stderr.write("Failed. Use --help for full instructions.\n")
        sys.exit(rv)
    else:
        sys.exit(0)
        