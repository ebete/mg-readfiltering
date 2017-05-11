#!/usr/bin/env python3

import sys
import os

"""
MIT License
Copyright (c) 2017 Thom Griffioen

Author: Thom Griffioen
Date: 2017-05-11


Usage: finddups.py SEARCHDIR [SEARCHDIR2 ...] OUTDIR
"""


def main(args):
    dirs = args[:-1]
    outdir = args[-1]
    for dir in dirs:
        if not os.path.isdir(dir):
            raise ArgumentException("The given path %s is not a valid directory" % dir)
    os.makedirs(outdir, exist_ok=True)
    if not os.access(outdir, os.W_OK):
        raise PermissionError("Writing to the output directory %s is not permitted." % outdir)

    fileoccurences = {}
    for dir in dirs:
        for root, directories, files in os.walk(dir):
            for fname in files:
                if not fname.endswith(".fq.gz"):
                    print("Skipping %s ... (not a gzipped FASTQ file)" % fname, file=sys.stderr)
                    continue
                fpath = os.path.join(root, fname)
                fileoccurences[fname] = fileoccurences.setdefault(fname, 0) + 1
                fout = os.path.join(outdir, fname)
                print("Appending %s to %s (contains reads from %d bins) ..." % (fpath, fout, fileoccurences[fname]), file=sys.stderr)
                if os.path.exists(fout) and fileoccurences[fname] <= 1:
                    raise FileExistsError("The output file %s already exists." % fpath)
                # append/create output file
                with open(fpath, "rb") as fin, open(fout, "a+b") as fout:
                    fout.write(fin.read())


if __name__ == '__main__':
    main(sys.argv[1:])
