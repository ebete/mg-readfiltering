#!/usr/bin/env python3

# standard libraries
import argparse
import gzip
import logging
import os
import re
import sys
from traceback import format_exc
# biopython and etetoolkit
from Bio import SeqIO
from ete3 import NCBITaxa
# local libraries
import lineage_lookup

"""
MIT License
Copyright (c) 2017 Thom Griffioen

Author: Thom Griffioen
Date: 2017-05-09
"""
_epilog = """
This program parses the results from Kaiju and attempts to bin the reads. It
splits based on the taxonomic rank. Processing paired-end reads should not
be a problem as long as the reads are ordered (i.e. the first and second read
are a pair, the third and fourth the second pair, etc.). Please make sure that
the amount of bins created will not exceed the file limit (shown by ulimit -Hn).
"""


def main(args):
    if not os.path.exists(args.input):
        raise FileNotFoundError("FASTQ file %s does not exist." % args.input)
    if not os.path.exists(args.kaiju):
        raise FileNotFoundError("Kaiju result file %s does not exist." % args.kaiju)
    if args.taxon_rank not in lineage_lookup.tax_ranks:
        raise ArgumentError("The given rank '%s' is not supported." % args.taxon_rank)
    os.makedirs(args.output, exist_ok=True)
    if not os.access(args.output, os.W_OK):
        raise PermissionError("Writing to the output directory %s is not permitted." % args.output)
    if len(os.listdir(args.output)) > 0:
        logging.warning("The output directory %s is not empty. Files may be overwritten if --overwrite is passed. "
                        "Otherwise, the program will fail without outputting results!" % args.output)

    # Keep for database initialisation/updating.
    logging.info("Loading ete3 NCBI Taxonomy database ...")
    taxdb = NCBITaxa()
    if args.update:
        logging.info("Updating ete3 NCBI Taxonomy database ...")
        taxdb.update_taxonomy_database()

    fqid2otu, binnames = get_fqid_taxid(args.taxon_rank, args.kaiju, args.threads)
    binfiles = get_bin_output_files(binnames, args.output, args.prefix, args.overwrite)

    fhandles = {}
    try:
        logging.info("Opening file handles for %d bins ..." % len(binfiles))
        fhandles = {binname: gzip.open(filename, "wt", compresslevel=4) for binname, filename in binfiles.items()}
        bin_reads(fqid2otu, args.input, fhandles)
    except:
        raise
    finally:
        logging.info("Closing file handles ...")
        for fhandle in fhandles.values():
            fhandle.close()


def get_bin_output_files(binnames, outdir, prefix, overwrite):
    """
    Assigns an output file to each bin.

    {binname: filedir}
    """
    logging.debug("Check if bin files conflict with existing files ...")
    binfiles = {}
    namepattern = re.compile("[\W]+")
    for names in binnames:
        fname = prefix + names.lower()
        fname = namepattern.sub("", fname)
        flocation = os.path.join(outdir, fname + ".fq.gz")
        binfiles[names] = flocation
    for path in binfiles.values():
        if os.path.exists(path):
            logging.debug("Output file %s exists" % path)
            if not overwrite:
                raise FileExistsError("The file %s already exists. Use --overwrite to ignore this." % path)
        else:
            logging.debug("Output file %s not created yet" % path)
    return binfiles


def bin_reads(fqid2bin, fqfile, filehandles):
    """
    Bins the reads in separate files based on the OTU linked to the read ID.
    """
    logging.info("Binning reads ...")
    with gzip.open(fqfile, "rt") as fin:
        previd = ""
        prevotu = "root"
        for record in SeqIO.parse(fin, "fastq"):
            if record.id == previd:  # Bins PE reads together
                # logging.debug("Writing record %s to %s" % (record.id, prevotu))
                SeqIO.write(record, filehandles[prevotu], "fastq")
            else:
                otu = fqid2bin.get(record.id, "root")
                # logging.debug("Writing record %s to %s" % (record.id, otu))
                SeqIO.write(record, filehandles[otu], "fastq")
                previd = record.id
                prevotu = otu


def get_fqid_taxid(taxrank, kaijufile, workerthreads):
    """
    Maps the IDs of the reads to an OTU in a dict. Also returns all the names
    of the bins in a list.
    """
    logging.info("Assigning reads to OTUs ...")
    fqids = {}

    logging.info("Loading %s into memory ..." % kaijufile)
    with open(kaijufile, "r") as fin:
        for line in fin:
            if line[0] != 'C':
                continue
            line = line.split()
            taxid = line[2].strip()
            fqid = line[1].strip()
            fqids[fqid] = taxid

    # multithreaded taxonomy lookups
    logging.info("Resolving lineages of taxa (slow) ...")
    logging.debug("Amount of worker threads set to %d" % workerthreads)
    lineage_pool = lineage_lookup.ThreadPool(workerthreads)
    for fqid in fqids:
        lineage_pool.add_task(lineage_lookup.get_bin, taxrank, fqid, fqids)
    logging.debug("Waiting for workers to finish ...")
    lineage_pool.wait_completion()

    logging.info("Parsing indentified bins ...")
    binnames = set(x for x in fqids.values())

    return fqids, binnames


if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog=sys.argv[0], description="Generates OTUs from Kaiju output.", epilog=_epilog)
    optional = parser._action_groups.pop()
    required = parser.add_argument_group("required arguments")
    # Required arguments
    required.add_argument("-t", "--taxon-rank",
                          help="The taxonomic rank used for separation (any of %s)" % ", ".join(lineage_lookup.tax_ranks),
                          action="store", type=str, required=True)
    required.add_argument("-k", "--kaiju", help="The Kaiju result file", action="store", type=str, required=True)
    required.add_argument("-i", "--input", help="The gzipped FASTQ file used for the Kaiju analysis", action="store",
                          type=str, required=True)
    required.add_argument("-o", "--output", help="Output location for the OTUs (gzipped FASTQ files)", action="store",
                          type=str, required=True)
    # Optional arguments
    optional.add_argument("-p", "--prefix", help="File prefix to use when creating output files", type=str, default="")
    optional.add_argument("-f", "--overwrite", help="Overwrite existing files", action="store_true")
    optional.add_argument("-u", "--update", help="Checks the NCBI Taxonomy database for updates", action="store_true")
    optional.add_argument("--threads", help="Specify the number of threads to use", type=int, action="store", default=1)
    # Standard arguments
    optional.add_argument("-v", "--verbose", help="Increase verbosity level", action="count")
    optional.add_argument("-q", "--silent", help="Suppresses output messages, overriding the --verbose argument",
                          action="store_true")
    optional.add_argument("-l", "--log", help="Set the logging output location", action="store",
                          type=argparse.FileType('w'), default=sys.stderr)
    optional.add_argument("-V", "--version", action="version", version="1.0")
    parser._action_groups.append(optional)
    args = parser.parse_args()

    loglvl = logging.WARNING
    if args.silent:
        loglvl = logging.ERROR
    elif not args.verbose:
        pass
    elif args.verbose >= 2:
        loglvl = logging.DEBUG
    elif args.verbose == 1:
        loglvl = logging.INFO
    logging.basicConfig(format="[%(asctime)s] %(levelname)s: %(message)s", level=loglvl, stream=args.log)
    logging.debug("Setting verbosity level to %s" % logging.getLevelName(loglvl))

    exitcode = 0
    try:
        main(args)
    except Exception as ex:
        exitcode = 1
        logging.error(ex)
        logging.debug(format_exc())
    finally:
        logging.debug("Shutting down logging system ...")
        logging.shutdown()
    sys.exit(exitcode)
