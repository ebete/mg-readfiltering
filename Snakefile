__author__ = "Thom Griffioen"
__copyright__ = "Copyright 2017 Thom Griffioen"
__email__ = "t.griffioen@nioo.knaw.nl"
__license__ = "MIT"

from snakemake.utils import min_version

min_version("3.11.0")

configfile: "config.yaml"
OUTFILES = []
if config["run-fastqc"]:
    OUTFILES.append("{project}/multiqc/qc_report.html")        # FastQC and MultiQC
OUTFILES.append("{project}/kaiju/paired/{sample}.tsv")         # Kaiju paired
OUTFILES.append("{project}/kaiju/unpaired/{sample}.tsv")       # Kaiju unpaired
if config["run-krona"]:
    OUTFILES.append("{project}/krona/{sample}_paired.html")    # Krona paired
    OUTFILES.append("{project}/krona/{sample}_unpaired.html")  # Krona unpaired


rule all:
    input:
        expand(OUTFILES, project=config["project"], sample=config["data"])


include: "read_qc.snakefile"
include: "read_taxonomy_classify.snakefile"
