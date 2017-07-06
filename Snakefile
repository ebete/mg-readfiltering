# Usage: snakemake --use-conda -p --cores 16 --resources high_diskio=4 --configfile your_config.yaml

__author__ = "Thom Griffioen"
__copyright__ = "Copyright 2017 Thom Griffioen"
__email__ = "t.griffioen@nioo.knaw.nl"
__license__ = "MIT"


from snakemake.utils import min_version

min_version("3.11.0")


configfile: "config.yaml"


# decide the recompression method
if config["compression"] == "bz2":
    ruleorder:
        recompress_bz2_and_merge_lanes >
        recompress_gz_and_merge_lanes >
        compress_raw_and_merge_lanes
elif config["compression"] == "gz":
    ruleorder:
        recompress_gz_and_merge_lanes >
        recompress_bz2_and_merge_lanes >
        compress_raw_and_merge_lanes
elif config["compression"] in ["fastq", "fq"]:
    ruleorder:
        compress_raw_and_merge_lanes >
        recompress_gz_and_merge_lanes >
        recompress_bz2_and_merge_lanes


# constants used in expand functions
PROJECT = config["project"]
SAMPLES = config["data"]
PAIRED = ["paired", "unpaired"]
DIRECTION = ["forward", "reverse"]
READDIR = ["r1", "r2"]


# target files for rule all
OUTFILES = []
OUTFILES.append("{project}/reformatted/{sample}_{paired}.fq.gz")
if config["run-fastqc"]:
    OUTFILES.append("{project}/multiqc_pre/qc_report.html")             # FastQC > MultiQC
    OUTFILES.append("{project}/multiqc_post/qc_report.html")            # FastQC > MultiQC
if config["run-krona"]:
    OUTFILES.append("{project}/kaiju/{sample}.report.tsv") # Kaiju > Report
    OUTFILES.append("{project}/krona/{sample}_{paired}.html")       # Kaiju > Krona
if config["run-khist"]:
    OUTFILES.append("{project}/khmer/kdepth.done")                  # BBMap khist > R
#if config["run-diginorm"]:
#    OUTFILES.append("{project}/khmer/{sample}.fq.gz")               # Khmer digital normalisation
if config["run-binning"]:
    OUTFILES.append("{project}/bins/merged/binmerge.done")          # Kaiju > Binning


rule all:
    input:
        expand(OUTFILES, project=PROJECT, sample=SAMPLES, paired=PAIRED, direction=DIRECTION, readdirection=READDIR)


include: "read_trim.snakefile"
include: "read_reformat.snakefile"
include: "read_qc.snakefile"
include: "read_taxonomy_classify.snakefile"
include: "read_diginorm.snakefile"
