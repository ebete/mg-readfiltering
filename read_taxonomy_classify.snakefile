rule kaiju_paired:
    input:
        forward = lambda wildcards: config["data"][wildcards.sample]["forward"]["paired"],
        reverse = lambda wildcards: config["data"][wildcards.sample]["reverse"]["paired"]
    output:
        protected("{project}/kaiju/paired/{sample}.tsv")
    conda:
        "envs/kaiju.yaml"
    log:
        "logs/kaiju/{sample}_paired.log"
    threads: 6
    params:
        kaiju_files = "-t {0}/nodes.dmp -f {0}/kaiju_db_nr_euk.fmi".format(config["kaiju"]["db"]),
        mode = config["kaiju"]["match-mode"],
        max_substitutions = config["kaiju"]["max-sub"],
        min_matchlen = config["kaiju"]["min-matchlen"],
        min_matchscore = config["kaiju"]["min-matchscore"]
    shell:
        "kaiju -z {threads} {params.kaiju_files} -a {params.mode} -e {params.max_substitutions} -m {params.min_matchlen} -s {params.min_matchscore} -i <(gunzip -c {input.forward}) -j <(gunzip -c {input.reverse}) -v -o {output} 2> {log}"


rule merge_unpaired:
    input:
        forward = lambda wildcards: config["data"][wildcards.sample]["forward"]["unpaired"],
        reverse = lambda wildcards: config["data"][wildcards.sample]["reverse"]["unpaired"]
    output:
        "{project}/unpaired-merged/{sample}_unpaired.fq.gz" # TODO: make temp later
    threads: 1
    shell:
        "cat {input.forward} {input.reverse} > {output}"


rule kaiju_unpaired:
    input:
        "{project}/unpaired-merged/{sample}_unpaired.fq.gz"
    output:
        protected("{project}/kaiju/unpaired/{sample}.tsv")
    conda:
        "envs/kaiju.yaml"
    log:
        "logs/kaiju/{sample}_unpaired.log"
    threads: 6
    params:
        kaiju_files = "-t {0}/nodes.dmp -f {0}/kaiju_db_nr_euk.fmi".format(config["kaiju"]["db"]),
        mode = config["kaiju"]["match-mode"],
        max_substitutions = config["kaiju"]["max-sub"],
        min_matchlen = config["kaiju"]["min-matchlen"],
        min_matchscore = config["kaiju"]["min-matchscore"]
    shell:
        "kaiju -z {threads} {params.kaiju_files} -a {params.mode} -e {params.max_substitutions} -m {params.min_matchlen} -s {params.min_matchscore} -i <(gunzip -c {input}) -v -o {output} 2> {log}"


rule kaiju_paired_binning:
    input:
        kaiju = "{project}/kaiju/paired/{sample}.tsv",
        fastq = lambda wildcards: config["data"][wildcards.sample][wildcards.direction]["paired"]
    output:
        "{project}/bins/{sample}_{direction}"
    conda:
        "envs/kaiju.yaml"
    log:
        "logs/binning/{sample}_{direction}_binning.log"
    threads: 1
    params:
        otu_file = config["kaiju"]["otu-file"]
    shell:
        "get_kaiju_otu.py -t {params.otu_file} -k {input.kaiju} -i {input.fastq} -o {output} -f -vv 2> {log}"


rule kaiju_unpaired_binning:
    input:
        kaiju = "{project}/kaiju/unpaired/{sample}.tsv",
        fastq = "{project}/unpaired-merged/{sample}_unpaired.fq.gz"
    output:
        "{project}/bins/{sample}_unpaired"
    conda:
        "envs/kaiju.yaml"
    log:
        "logs/binning/{sample}_unpaired_binning.log"
    threads: 1
    params:
        otu_file = config["kaiju"]["otu-file"]
    shell:
        "get_kaiju_otu.py -t {params.otu_file} -k {input.kaiju} -i {input.fastq} -o {output} -f -vv 2> {log}"


rule kaiju_krona:
    input:
        "{project}/kaiju/{paired}/{sample}.tsv"
    output:
        html = protected("{project}/krona/{sample}_{paired}.html"),
        krona = "{project}/krona/{sample}_{paired}.krona"
    conda:
        "envs/kaiju.yaml"
    log:
        "logs/krona/{sample}_{paired}.log"
    threads: 1
    params:
        kaiju_files = "-t {0}/nodes.dmp -n {0}/names.dmp".format(config["kaiju"]["db"])
    shell:
        "(kaiju2krona {params.kaiju_files} -i {input} -o {output.krona} && "
        "ktImportText -o {output.html} {output.krona}) 2> {log}"
