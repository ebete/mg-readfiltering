#!/usr/bin/env python3

import logging
import os
import sys
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

# Only works for the trimmomatic output files of the erasmus_metagenome workflow
def get_sample_files(path):
    samples = OrderedDict()
    for subdir, root, files in os.walk(path):
        for fname in files:
            if ".fq" in fname:
                print(fname)
                sample = fname.partition(".fq")[0].split('_')

                fq_path = os.path.join(subdir, fname)
                samples.setdefault(sample[0], {}).setdefault(sample[1], {})[sample[2]] = fq_path
                logging.info("Adding file for sample %s ..." % sample[0])
    return samples


def make_config(config, dataloc):
    """Write the file 'config' and complete the sample names and paths for all files in 'path'."""
    represent_dict_order = lambda self, data:  self.represent_mapping('tag:yaml.org,2002:map', data.items())
    yaml.add_representer(OrderedDict, represent_dict_order)

    conf = OrderedDict()
    conf["project"] = "mg-preprocess"
    conf["run-fastqc"] = True

    samples = get_sample_files(dataloc)
    logging.info("Found %d samples under %s" % (len(samples), dataloc))
    conf["data"] = samples

    with open(config, "w") as f:
        print(yaml.dump(conf, default_flow_style=False), file=f)
    logging.info("Configuration file written to %s" % config)

if __name__ == "__main__":
    path = os.path.abspath(sys.argv[1])
    make_config(config="config.yaml", dataloc=path)
