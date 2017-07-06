#!/usr/bin/env python3

# standard libraries
import argparse
import logging
import os
import re
import sys
from collections import OrderedDict
from traceback import format_exc
# PyYAML
import yaml
# natsort
from natsort import natsorted

"""
MIT License
Copyright (c) 2017 Mattias de Hollander / Thom Griffioen
# natsort
from natsort import natsorted
Author: Mattias de Hollander <m.dehollander@nioo.knaw.nl>
Author: Thom Griffioen <t.griffioen@nioo.knaw.nl>
Date: 2017-05-19
"""
_epilog = """
Generate configuration files in YAML format of your NGS samples. To be used in
the Snakemake pipeline. This program expects paired samples. The filename of a
pair should be the same except for the '_R1'/'_R2' part (or '_1'/'_2'). The ID
of the pair will be the rest of the filename (i.e. test_r1.fq.gz will get the
ID 'test').
"""


# Adapted from: https://github.com/pnnl/atlas/blob/master/atlas/conf.py
# http://stackoverflow.com/a/3675423
def replace_last(source_string, replace_what, replace_with):
    head, _sep, tail = source_string.rpartition(replace_what)
    if _sep == '':
        return tail
    else:
        return head + replace_with + tail


def get_sample_files(path):
    path = os.path.realpath(path)
    # set valid file extensions
    valid_formats = [".fastq", ".fq"]
    valid_compressions = ["", ".bz2", ".gz"]
    valid_ext = []
    for x in valid_formats:
        for y in valid_compressions:
            valid_ext.append(x + y)
    valid_ext = tuple(valid_ext)
    logging.debug("Valid file extensions set to %s" % ", ".join(valid_ext))

    samples = OrderedDict()
    seen = set()
    compress_algo = []
    for dir_name, sub_dirs, files in os.walk(path):
        logging.debug("dir_name: %s" % dir_name)
        logging.debug("sub_dirs: %s" % sub_dirs)
        logging.debug("files:    %s" % files)
        for fname in files:
            if not fname.endswith(valid_ext):
                logging.info("File %s does not have a valid extension." % fname)
                continue

            # remove file extension
            sample_id = fname
            while sample_id.endswith(valid_ext):
                sample_id = os.path.splitext(sample_id)[0]

            # parse sample ID
            sample_id = sample_id.replace("_R1", "").replace("_r1", "").replace("_R2", "").replace("_r2", "")
            sample_id = re.sub("_1$", "", sample_id)
            sample_id = re.sub("_2$", "", sample_id)
            sample_id = sample_id.replace("_", "-").replace(" ", "-")
            fq_path = os.path.join(dir_name, fname)
            fastq_paths = {}

            if fq_path in seen:
                continue

            # try to find the R2 read in the pair
            if "_R1" in fname or "_r1" in fname or "_1" in fname:
                fname = replace_last(fname, "_1.", "_2.")
                r2_path = os.path.join(dir_name, fname.replace("_R1", "_R2").replace("_r1", "_r2"))
                if not r2_path == fq_path:
                    seen.add(r2_path)
                    fastq_paths["r1"] = fq_path
                    fastq_paths["r2"] = r2_path

            # try to find the R1 read in the pair
            if "_R2" in fname or "_r2" in fname or "_2" in fname:
                strand = "reverse"
                fname = replace_last(fname, "_2.", "_1.")
                r1_path = os.path.join(dir_name, fname.replace("_R2", "_R1").replace("_r2", "_r1"))
                if not r1_path == fq_path:
                    seen.add(r1_path)
                    fastq_paths["r1"] = r1_path
                    fastq_paths["r2"] = fq_path

            if sample_id in samples:
                logging.warning("Duplicate sample %s was found after renaming; skipping..." % sample_id)
                continue
            
            # note compression method
            compress_algo.append(os.path.splitext(fastq_paths["r1"])[1])
            compress_algo.append(os.path.splitext(fastq_paths["r2"])[1])

            
            id_match = re.search("(M[GT][\d]{1,2})", sample_id)
            try:
                sample_id = id_match.group(1)
            except AttributeError:
                logging.warning("The sample '%s' does not follow the correct naming scheme. Skipping ..." % sample_id)
                continue
            logging.info("Found sample pair %s + %s with ID %s" % (fastq_paths["r1"], fastq_paths["r2"], sample_id))
            samples.setdefault(sample_id, {})
            samples[sample_id].setdefault("r1", []).append(fastq_paths["r1"])
            samples[sample_id].setdefault("r2", []).append(fastq_paths["r2"])

    compress_algo = list(set(compress_algo))
    if len(compress_algo) > 1:
        raise Exception("Multiple compression methods used at the same time. This is not supported.")

    samples = OrderedDict(natsorted(samples.items()))
    return samples, str(compress_algo[0])[1:]


def make_config(config, dataloc):
    """Write the file 'config' and complete the sample names and paths for all files in 'path'."""
    represent_dict_order = lambda self, data: self.represent_mapping('tag:yaml.org,2002:map', data.items())
    yaml.add_representer(OrderedDict, represent_dict_order)
    conf = OrderedDict()
    samples, compressmethod = get_sample_files(dataloc)
    logging.info("Found %d samples under %s" % (len(samples), dataloc))
    logging.info("Compression method detected: %s" % compressmethod)
    conf["compression"] = compressmethod
    conf["data"] = samples
    with open(config, "w") as f:
        logging.info("Writing config to %s ..." % config)
        f.write(yaml.dump(conf, default_flow_style=False))
    logging.info("Configuration file written to %s" % config)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(prog=sys.argv[0], description="Generates configs from NGS samples.", epilog=_epilog)
    optional = parser._action_groups.pop()
    required = parser.add_argument_group("required arguments")
    # Required arguments
    required.add_argument("SAMPLES", help="The location of your NGS samples", action="store")
    required.add_argument("CONFIGFILE", help="The name of the generated configuration file", action="store")
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
        make_config(config=args.CONFIGFILE, dataloc=args.SAMPLES)
    except Exception as ex:
        exitcode = 1
        logging.error(ex)
        logging.debug(format_exc())
    finally:
        logging.debug("Shutting down logging system ...")
        logging.shutdown()
    sys.exit(exitcode)

