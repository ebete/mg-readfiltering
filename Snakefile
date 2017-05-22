# Usage: snakemake --use-conda -p --cores 16 --resources high_diskio=4 --configfile your_config.yaml

__author__ = "Thom Griffioen"
__copyright__ = "Copyright 2017 Thom Griffioen"
__email__ = "t.griffioen@nioo.knaw.nl"
__license__ = "MIT"

from snakemake.utils import min_version

min_version("3.11.0")

configfile: "config.yaml"
OUTFILES = []
OUTFILES.append("{project}/reformatted/{sample}_{paired}.fq.gz")
if config["run-fastqc"]:
    OUTFILES.append("{project}/multiqc/qc_report.html")           # FastQC > MultiQC
if config["run-krona"]:
    OUTFILES.append("{project}/krona/{sample}_{paired}.html")     # Kaiju > Krona
if config["run-khist"]:
    OUTFILES.append("{project}/khmer/kdepth.done")                # BBMap khist > R
#if config["run-diginorm"]:
#    OUTFILES.append("{project}/khmer/{sample}.fq.gz")             # Khmer digital normalisation
if config["run-binning"]:
    OUTFILES.append("{project}/bins/merged/binmerge.done")        # Kaiju > Binning


rule all:
    input:
        expand(OUTFILES, project=config["project"], sample=config["data"], paired=["paired", "unpaired"], direction=["forward", "reverse"], readdirection=["r1", "r2"])


include: "read_trim.snakefile"
include: "read_reformat.snakefile"
include: "read_qc.snakefile"
include: "read_taxonomy_classify.snakefile"
include: "read_diginorm.snakefile"
