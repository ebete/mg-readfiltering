# MG-READFILTERING
[![build status](https://gitlab.bioinf.nioo.knaw.nl/ThomG/mg-readfiltering/badges/master/build.svg)](https://gitlab.bioinf.nioo.knaw.nl/ThomG/mg-readfiltering/commits/master)

Snakemake pipeline for processing and assembling metagenomic Illumina HiSeq PE read data.

## How-To
Please follow the [NIOO project skeleton](https://gitlab.bioinf.nioo.knaw.nl/nioo-bioinformatics/nioo-project-skeleton) format for new analyses.

Start off by cloning the git project into the `analysis/` directory and moving into the project directory:
```sh
$ git clone git@gitlab.bioinf.nioo.knaw.nl:ThomG/mg-readfiltering.git
$ cd analysis/
```

### Naming raw read files
The file names for the raw data has to follow some rules so the program understands what the data is.
- The files have to be gzipped (`.gz`) or bzipped (`.bz2`).
- They have to be in FASTQ format (`.fq`/`.fastq`).
- The pairs have to have the same name except for the `_R1`/`_R2` part (also allowed: `_r1`/`_r2`, `_1`/`_2`).
Example of valid file names:
```
Read file 1:
  I16-1249-27-MT27_CAGGCGAT-TCTTTCCC_L002_R1_001.fastq.bz2
Read file 2:
  I16-1249-27-MT27_CAGGCGAT-TCTTTCCC_L002_R2_001.fastq.bz2
```
The identifier for this pair will be `MT27`.
Place these files in the `data/` directory of your project.

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
kaiju:
  db: /mnt/zfs/data/kaiju_nr
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
The `kaiju` and `khmer` entries both contain some parameters you can change that are passed to the programs.
Be careful when editing this file.
You cannot remove/rename entries and the indentation should also stay the same.

### Running the pipeline
Once the project has been set up, use the following command to run the pipeline:
```sh
$ snakemake --use-conda --resources high_diskio=4 --configfile readdata.yaml --cores 8
```
You can increase/decrease the core count if you like, but please do not increase the `high_diskio=4` flag.
This is to prevent excessive hard disk load.
It is also possible to execute a dry-run (only showing what the pipeline intents to run without doing anything) by adding the `-n` flag (use `-p` if you want to see the actual commands).

Depending on the amount of data and your settings, it will take some time to finish running (days to weeks).
Once finished, all the results can be found in the project directory you specified in the `config.yaml` file.
