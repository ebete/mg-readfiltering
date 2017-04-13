__author__ = "Thom Griffioen"
__copyright__ = "Copyright 2017 Thom Griffioen"
__email__ = "t.griffioen@nioo.knaw.nl"
__license__ = "MIT"

from snakemake.utils import min_version

min_version("3.11.0")

configfile: "config.yaml"
OUTFILES = []
if config["run-fastqc"]:
    OUTFILES.append("{project}/multiqc/qc_report.html") # FastQC and MultiQC
if config["run-krona"]:
    OUTFILES.append("{project}/kaiju/paired/{sample}.tsv")  # Kaiju
    OUTFILES.append("{project}/krona/{sample}.html")    # Krona
OUTFILES.append("{project}/khmer/{sample}.fq.gz")       # Khmer


rule all:
    input:
        expand(OUTFILES, project=config["project"], sample=config["data"])


include: "read_qc.snakefile"
include: "read_taxonomy_classify.snakefile"
include: "read_reformat.snakefile"
include: "read_diginorm.snakefile"
