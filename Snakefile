__author__ = "Thom Griffioen"
__copyright__ = "Copyright 2017 Thom Griffioen"
__email__ = "t.griffioen@nioo.knaw.nl"
__license__ = "MIT"

from snakemake.utils import min_version

min_version("3.11.0")

configfile: "config.yaml"

PROJECT = config["project"]

rule all:
    input:
        expand("{project}/multiqc/qc_report.html", project=config["project"])
#        "{project}/multiqc/qc_report.html"

include: "read_qc.snakefile"
