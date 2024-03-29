# MG-READFILTERING
[![build status](https://gitlab.bioinf.nioo.knaw.nl/ThomG/mg-readfiltering/badges/master/build.svg)](https://gitlab.bioinf.nioo.knaw.nl/ThomG/mg-readfiltering/commits/master)

Snakemake pipeline for processing and assembling metagenomic Illumina HiSeq PE read data.

## How-To
Please follow the [NIOO project skeleton](https://gitlab.bioinf.nioo.knaw.nl/nioo-bioinformatics/nioo-project-skeleton) format for new analyses.

Start off by cloning the git project into the `analysis/` directory and moving into the project directory:
```sh
$ git clone git@gitlab.bioinf.nioo.knaw.nl:ThomG/mg-readfiltering.git analysis/
$ cd analysis/
```
Activate the Conda environment by running the following command in the directory you just cloned the pipeline to:
```sh
$ conda env create -f environment.yml
```
You should now see `(mg-preprocess)` in your primary prompt string (e.g. `(mg-preprocess) thomg@nioo0002:~/project $ `). This means that the environment has been loaded correctly.

### Naming raw read files
The file names for the raw data has to follow some rules so the program understands what the data is.
- The only allowed compression methods are gzip (`.gz`) and bzip (`.bz2`).
- The same compression method has to be used for all files.
- They have to be in FASTQ format (`.fq`/`.fastq`).
- The pairs have to have the same name except for the `_R1`/`_R2` part (also allowed: `_r1`/`_r2`, `_1`/`_2`).
- The reads need an unique sample ID in the format `MGXX` or `MTXX`, where the X is a number.
- The same sample in a different lane need to have the same sample ID.

Example of valid file names for paired-end samples with multiple lanes:
```
Read direction 1:
  I16-1249-27-MT27_CAGGCGAT-TCTTTCCC_L001_R1_001.fastq.bz2
  I16-1249-27-MT27_CAGGCGAT-TCTTTCCC_L002_R1_001.fastq.bz2
Read direction 2:
  I16-1249-27-MT27_CAGGCGAT-TCTTTCCC_L001_R2_001.fastq.bz2
  I16-1249-27-MT27_CAGGCGAT-TCTTTCCC_L002_R2_001.fastq.bz2
```
The identifier for this pair will be `MT27`.
Place these files in the `data/` directory of your project.
You may place the files in subdirectories and `gen_conf.py` will attempt to find all the reads.

### Creating and editing the configuration files
Snakemake needs to understand where the files are and which parameters to use in the pipeline.
We use the script `gen_conf.py` to generate a configuration file like this:
```sh
# we assume that the raw reads are stored in ../data/
$ python3 gen_conf.py ../data/ readdata.yaml
```
If all goes well, this script should generate the file `readdata.yaml`.
It contains the location and some metadata about the raw read files.

The file [config.yaml](config.yaml) contains the parameters used by the pipeline and should not be moved/renamed.
You can view/edit this file with a text editor like `nano`:
```sh
$ nano config.yaml
```
By default, the contents of this file look like this:
```yaml
project: mg-readfiltering
run-fastqc: false
run-krona: false
run-khist: false
run-diginorm: false
run-binning: false
trimmomatic:
  adapters: /mnt/zfs/data_other/tools/Trimmomatic/0.36/adapters/NexteraPE-PE.fa
  seed-mismatch: 2
  palindrome-clip-threshold: 30
  simple-clip-threshold: 10
  min-adapter-length: 8
  keep-both-reads: false
  window-size: 4
  required-quality: 30
  leading-min-quality: 3
  trailing-min-quality: 3
  min-length: 100
kaiju:
  db: /mnt/zfs/data_other/db/kaiju_nr
  match-mode: greedy
  max-sub: 2
  min-matchlen: 11
  min-matchscore: 65
  tax-rank: phylum
khmer:
  depth-cutoff: 2
  k-size: 20
  max-gb-ram: 256
```
You can edit the name of the output directory by editing the `project` entry.
The `run-*` entries can be set to `true` or `false` and will enable/disable parts of the pipeline.
The `trimmomatic`, `kaiju` and `khmer` entries contain some parameters you can change that are passed to the programs.
Check the documentation of the tools to learn what the parameters do.
Be careful when editing this file.
You should not remove/rename entries and the indentation should also stay the same.

### Running the pipeline
Once the project has been set up, use the following command to run the pipeline:
```sh
$ snakemake --use-conda --resources high_diskio=4 --configfile readdata.yaml --cores 8
```
You can increase/decrease the core count if you like, but please do not increase the `high_diskio=4` flag.
This is to prevent excessive hard disk load.
It is also possible to execute a dry-run (only showing what the pipeline intents to run without doing anything) by adding the `-n` flag (use `-p` if you want to see the actual commands).

Depending on the amount of data and your settings, it will take some time to finish running (days to weeks).
Once finished, all the results can be found in the project directory you specified in the [config.yaml](config.yaml) file.
