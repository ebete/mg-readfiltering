#!/usr/bin/env python3

import logging
import multiprocessing
import re
import os
import sys
import tempfile
import yaml
from collections import OrderedDict


# Adapted from: https://github.com/pnnl/atlas/blob/master/atlas/conf.py
# http://stackoverflow.com/a/3675423
def replace_last(source_string, replace_what, replace_with):
    head, _sep, tail =  source_string.rpartition(replace_what)
    if _sep == '':
        return tail
    else: 
        return head + replace_with + tail


def get_sample_files(path):
    samples = OrderedDict()
    seen = set()
    for dir_name, sub_dirs, files in os.walk(path):
        print(dir_name, sub_dirs, files)
        for fname in files:
            if ".fastq" in fname or ".fq" in fname:
                sample_id = fname.partition(".fastq")[0]
                if ".fq" in sample_id:
                    sample_id = fname.partition(".fq")[0]
                sample_id = sample_id.replace("_R1", "").replace("_r1", "").replace("_R2", "").replace("_r2", "")
                sample_id = re.sub("_1$", "", sample_id)
                sample_id = re.sub("_2$", "", sample_id)
                sample_id = sample_id.replace("_", "-").replace(" ", "-")
                fq_path = os.path.join(dir_name, fname)
                fastq_paths = {}


                if fq_path in seen:
                    continue

                if "_R1" in fname or "_r1" in fname or "_1" in fname:
                    fname = replace_last(fname,"_1.","_2.")
                    r2_path = os.path.join(dir_name, fname.replace("_R1", "_R2").replace("_r1", "_r2"))
                    if not r2_path == fq_path:
                        seen.add(r2_path)
                        fastq_paths["forward"] = file_metadata(fq_path)
                        fastq_paths["reverse"] = file_metadata(r2_path)

                if "_R2" in fname or "_r2" in fname or "_2" in fname:
                    strand = "reverse"
                    fname = replace_last(fname,"_2.","_1.")
                    r1_path = os.path.join(dir_name, fname.replace("_R2", "_R1").replace("_r2", "_r1"))
                    if not r1_path == fq_path:
                        seen.add(r1_path)
                        fastq_paths["forward"] = file_metadata(r1_path)
                        fastq_paths["reverse"] = file_metadata(fq_path)

                if sample_id in samples:
                    logging.warn("Duplicate sample %s was found after renaming; skipping..." % sample_id)
                    continue

                sample_id = re.search("(MT[\d]{1,2})", sample_id).group(1)
                samples[sample_id] = fastq_paths
    return samples


def file_metadata(fpath):
    metadata = {
        "path": fpath
    }
    if fpath.endswith(".bz2"):
        metadata["compression"] = "pbzip2"
    elif fpath.endswith(".gz"):
        metadata["compression"] = "pigz2"
    else:
        raise Exception("Unknown file extension")
    return metadata


def make_config(config, dataloc):
    """Write the file 'config' and complete the sample names and paths for all files in 'path'."""
    represent_dict_order = lambda self, data:  self.represent_mapping('tag:yaml.org,2002:map', data.items())
    yaml.add_representer(OrderedDict, represent_dict_order)
    conf = OrderedDict()
    # conf["project"] = "mg-preprocess"
    samples = get_sample_files(dataloc)
    logging.info("Found %d samples under %s" % (len(samples), dataloc))
    conf["data"] = samples
    with open(config, "w") as f:
        print(yaml.dump(conf, default_flow_style=False), file=f)
    logging.info("Configuration file written to %s" % config)


if __name__ == "__main__":
    make_config(config=sys.argv[2], dataloc=sys.argv[1])
