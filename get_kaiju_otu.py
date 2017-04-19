#!/usr/bin/env python3

"""
MIT License
Copyright (c) 2017 Thom Griffioen

Author: Thom Griffioen
Date: 2017-04-12
"""
epilog="""
This program parses the results from Kaiju and attempts to bin the reads. It uses a file containing Taxonomy IDs
and checks if the TaxID assigned to the read falls under it and bins it accordingly. Processing paired-end reads
should not be a problem as long as the reads are ordered (i.e. the first and second read are a pair, the third and fourth the second pair, etc.)
"""

import argparse
import gzip
import logging
import os
import sys

from Bio import SeqIO
from ete3 import NCBITaxa


def main(args):
    if not os.path.exists(args.input):
        raise FileNotFoundError("FASTQ file %s does not exist." % args.input)
    if not os.path.exists(args.kaiju):
        raise FileNotFoundError("Kaiju result file %s does not exist." % args.kaiju)
    os.makedirs(args.output, exist_ok=True)
    if not os.access(args.output, os.W_OK):
        raise PermissionError("Writing to the output directory %s is not permitted." % args.output)

    logging.info("Loading ete3 NCBI Taxonomy database ...")
    taxdb = NCBITaxa()
    if args.update:
        logging.info("Updating ete3 NCBI Taxonomy database ...")
        taxdb.update_taxonomy_database()
    
    otutaxid2name = get_otu_names(taxdb, args.otu)
    binfiles = get_bin_output_files(otutaxid2name, args.output, args.prefix, args.overwrite)
    fqid2otu = get_fqid_taxid(taxdb, otutaxid2name, args.kaiju)
    bin_reads(fqid2otu, args.input, binfiles)


def get_bin_output_files(otutaxid2name, outdir, prefix, overwrite):
    """
    Assigns an output file to each bin.
    """
    logging.debug("Check if bin files conflict with existing files ...")
    binfiles = {}
    for key, value in otutaxid2name.items():
        binfiles[value] = os.path.join(outdir, prefix + value.lower() + ".fastq")
    for path in binfiles.values():
        if os.path.exists(path):
            logging.warning("Output file %s exists" % path)
            if not overwrite:
                raise FileExistsError("The file %s already exists. Use --overwrite to ignore this." % path)
            logging.info("Truncating file %s ..." % path)
            with open(path, 'w'):
                pass
        else:
            logging.debug("Output file %s not created yet" % path)
    return binfiles


def bin_reads(fqid2bin, fqfile, outfile):
    """
    Bins the reads in separate files based on the OTU linked to the read ID.
    """
    logging.info("Binning reads ...")
    with gzip.open(fqfile, "rt") as fin:
        previd = ""
        prevotu = "root"
        for record in SeqIO.parse(fin, "fastq"):
            if record.id == previd: # Bins PE reads together
                write_bin(outfile[prevotu], record)
            else:
                otu = fqid2bin.get(record.id, "root")
                write_bin(outfile[otu], record)
                previd = record.id
                prevotu = otu


def write_bin(binfile, read):
    """
    Appends a FASTQ read to the given file.
    """
    with open(binfile, "a+") as fout:
        SeqIO.write(read, fout, "fastq")


def get_fqid_taxid(taxdb, tax2name, kaijufile):
    """
    Maps the IDs of the reads to an OTU.
    """
    logging.info("Assigning reads to OTUs ...")
    fqids = {}

    with open(kaijufile, "r") as fin:
        for line in fin:
            line = line.split()
            binned = line[0][0] == 'C'
            taxid = line[2].strip()
            otu = "root"
            if binned:
                otu = get_otu_bin(taxdb, tax2name, taxid)
            fqid = line[1].strip()
            fqids[fqid] = otu
    return fqids


def get_otu_names(taxdb, otufile):
    """
    Returns a dictionary containing the name of the clade for each TaxID in the file containing the OTUs.
    """
    logging.info("Creating the OTU table ...")
    taxids = [1]
    with open(otufile, "r") as fin:
        for line in fin:
            taxids.append(int(line.strip()))
    return taxdb.get_taxid_translator(list(filter(bool, taxids)))


def get_otu_bin(taxdb, otutaxid2name, taxid):
    """
    Returns the name of the taxonomic clade of the given OTUs where the given TaxID falls under.
    """
    lineage = [1]
    try:
        lineage = taxdb.get_lineage(taxid)[::-1]
    except ValueError:
#       logging.warning("Taxonomy ID %s not found" % taxid) # Generates a LOT of noise in the logs
        pass
    otu = taxdb.get_taxid_translator([1])[1]
    for node in lineage:
        if node in otutaxid2name:
            otu = otutaxid2name[node]
            break
    return otu


if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog=sys.argv[0], description="Generates OTUs from Kaiju output.", epilog=epilog)
    optional = parser._action_groups.pop()
    required = parser.add_argument_group("required arguments")
    # Required arguments
    required.add_argument("-t", "--otu", help="File with OTU TaxIDs (newline separated) to base binning on", action="store", type=str, required=True)
    required.add_argument("-k", "--kaiju", help="The Kaiju result file", action="store", type=str, required=True)
    required.add_argument("-i", "--input", help="The gunzipped FASTQ file used for the Kaiju analysis", action="store", type=str, required=True)
    required.add_argument("-o", "--output", help="Output location for the OTUs", action="store", type=str, required=True)
    # Optional arguments
    optional.add_argument("-p", "--prefix", help="File prefix to use when creating FASTQ files", type=str, default="")
    optional.add_argument("-f", "--overwrite", help="Overwrite existing files", action="store_true")
    optional.add_argument("-u", "--update", help="Checks the NCBI Taxonomy database for updates", action="store_true")
    # Standard arguments
    optional.add_argument("-v", "--verbose", help="Increase verbosity level", action="count")
    optional.add_argument("-q", "--silent", help="Suppresses output messages, overriding the --verbose argument", action="store_true")
    optional.add_argument("-l", "--log", help="Set the logging output location", action="store", type=argparse.FileType('w'), default=sys.stderr)
    optional.add_argument("-V", "--version", action="version", version="1.0")
    parser._action_groups.append(optional)
    args = parser.parse_args()

    loglvl = logging.WARNING
    if args.silent:
        loglvl = logging.ERROR
    elif not args.verbose:
        loglvl = logging.WARNING
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
        logging.debug(sys.exc_info())
    finally:
        logging.debug("Shutting down logging system ...")
        logging.shutdown()
    sys.exit(exitcode)
