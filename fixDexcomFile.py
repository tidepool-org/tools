#!/usr/bin/env python
# encoding: utf-8
"""
fixDexcomFile.py

Originally created by Kent Quirk on 07/13/14.
Copyright (c) 2014 Tidepool Project. All rights reserved.
"""

import re
import os
import sys
import argparse
from datetime import datetime, timedelta

class ArgumentError(Exception):
    def __init__(self, txt):
        self.value = txt
    def __str__(self):
        return self.value

def calculateTimeAdjustment(adds, subs):
    times = dict(
        d=timedelta(days=1), 
        h=timedelta(hours=1), 
        m=timedelta(minutes=1), 
        s=timedelta(seconds=1)
    )
    pat = re.compile("([0-9]+)([dhms])")
    total = timedelta()
    def process(arr):
        t = timedelta()
        for a in arr:
            m = pat.match(a)
            if not m:
                raise ArgumentError("%s isn't understood -- offsets must be a number followed by d, h, m, or s" % a)
            amt, units = m.groups()
            t = t + (times[units] * int(amt))
        return t
    total += process(adds)
    total -= process(subs)
    return total

def parseDate(d):
    dpat = re.compile("([0-9]{4})-([0-9]{2})-([0-9]{2})")
    m = dpat.match(d)
    if not m:
        raise ArgumentError("%s isn't a valid date. Use YYYY-MM-DD." % d)
    year, month, day = m.groups()
    return dict(year=int(year), month=int(month), day=int(day))

def parseTime(t):
    tpat = re.compile("([0-9]{2}):([0-9]{2}):([0-9]{2})")
    m = tpat.match(t)
    if not m:
        raise ArgumentError("%s isn't a valid time. Use hh:mm:ss." % d)
    hour, minute, second = m.groups()
    return dict(hour=int(hour), minute=int(minute), second=int(second))

def readDexcomFile(f):
    contents = [l.split('\t') for l in f]
    header = contents[0]
    data = contents[1:]
    return header, data

def writeDexcomFile(f, hdr, data):
    f.write("%s" % '\t'.join(hdr))
    for d in data:
        f.write("%s" % '\t'.join(d))

def adjustDexcomData(hdr, data, adjustBy, first, last):
    hdict = dict(zip(hdr, range(len(hdr))))
    count = 0
    for d in data:
        t = d[hdict["GlucoseDisplayTime"]].split(' ')
        td = parseDate(t[0])
        td.update(parseTime(t[1]))
        time = datetime(**td)
        if (not first or time >= first) and (not last or time <= last):
            count += 1
            newt = time + adjustBy
            d[hdict["GlucoseDisplayTime"]] = newt.strftime("%Y-%m-%d %H:%M:%S")
    print "Adjusted %d rows." % count

def deleteDexcomRows(hdr, data, first, last):
    hdict = dict(zip(hdr, range(len(hdr))))
    deletes = []
    row = 0
    for d in data:
        t = d[hdict["GlucoseDisplayTime"]].split(' ')
        td = parseDate(t[0])
        td.update(parseTime(t[1]))
        time = datetime(**td)
        if (not first or time >= first) and (not last or time <= last):
            deletes.append(row)
        row += 1
    for d in reversed(deletes):
        del data[d]
    print "deleted %d rows" % len(deletes)

def main(argv=None):
    parser = argparse.ArgumentParser(description='Tool to adjust the GlucoseDisplayTime values in a text file from Dexcom.')
    # arg*<tab>
    parser.add_argument("--input", "-i", dest="input", nargs='?', type=argparse.FileType('r'), 
                    default=None, const=None, metavar="INPUT",
                    help="Specify the file to be used for input (use - for stdin).")
    parser.add_argument("--output", "-o", dest="output", nargs='?', type=argparse.FileType('w'), 
                    default=None, const=None, metavar="OUTPUT", 
                    help="Specify the output file (use - for stdout). "
                    "It should not be the same as the input file."
                    "If output is not specified, statistics are printed but nothing happens.")
    parser.add_argument("--first", "-f", dest="first", default=None, nargs=2,
                    help="Date/time of first time to adjust. "
                    "Use YYYY-MM-DD hh:mm:ss to specify times.", metavar="FIRST")
    parser.add_argument("--last", "-l", dest="last", default=None, nargs=2,
                        help="Date/time of last time to adjust"
                    "Use YYYY-MM-DD hh:mm:ss to specify times.", metavar="LAST")    
    parser.add_argument("--add", "-a", dest="add", default=[], nargs='*',
                    help="Amount to add to the times in the range of elements. "
                    "Specify nnd, h, m for days/hours/minutes. "
                    "Example: --add 3h 5m", metavar="ADD")
    parser.add_argument("--sub", "-s", dest="sub", default=[], nargs='*',
                    help="Amount to subtract from the times in the range of elements. "
                    "Specify nnd, h, m for days/hours/minutes. "
                    "Example: --sub 1d", metavar="SUB")
    parser.add_argument("--delete", "-d", dest="delete", default=False, action="store_true",
                    help="Delete the range of records specified.")

    args = parser.parse_args()
    print args
    adjust = timedelta()
    if args.add or args.sub:
        adjust = calculateTimeAdjustment(args.add, args.sub)
    if args.delete and adjust:
            print("You cannot specify both adjustment and delete. Nothing was done.")
            return

    if (args.first):
        f = parseDate(args.first[0])
        f.update(parseTime(args.first[1]))
        first = datetime(**f)
        print first
    else:
        print "First time not specified -- starting at beginning of file."
    if (args.last):
        l = parseDate(args.last[0])
        l.update(parseTime(args.last[1]))
        last = datetime(**l)
        print last
    else:
        print "Last time not specified -- processing through end of file."

    if not args.input:
        print "No input file specified!"
        exit(1)


    hdr, data = readDexcomFile(args.input)
    n = len(hdr)
    for d in data:
        if len(d) != n:
            print "malformed dexcom file!"
            exit(2)

    if adjust:
        print "adjustment by %d seconds" % adjust.total_seconds()
        adjustDexcomData(hdr, data, adjust, first, last)

    if args.delete:
        deleteDexcomRows(hdr, data, first, last)

    if args.output:
        writeDexcomFile(args.output, hdr, data)

    return 0

if __name__ == "__main__":
    rv = main()
    if rv:
        sys.stderr.write("Failed. Use --help for full instructions.\n")
        sys.exit(rv)
    else:
        sys.exit(0)
        