rule kaiju_paired:
    input:
        forward = lambda wildcards: config["data"][wildcards.sample]["forward"]["paired"],
        reverse = lambda wildcards: config["data"][wildcards.sample]["reverse"]["paired"]
    output:
        "{project}/kaiju/{sample}_paired.tsv"
    conda:
        "envs/kaiju.yaml"
    log:
        "logs/kaiju/{sample}_paired.log"
    threads: 8
    params:
        kaiju_files = "-t {0}/nodes.dmp -f {0}/kaiju_db_nr_euk.fmi".format(config["kaiju"]["db"]),
        mode = config["kaiju"]["match-mode"],
        max_substitutions = config["kaiju"]["max-sub"],
        min_matchlen = config["kaiju"]["min-matchlen"],
        min_matchscore = config["kaiju"]["min-matchscore"]
    shell:
        "kaiju -z {threads} {params.kaiju_files} -a {params.mode} -e {params.max_substitutions} -m {params.min_matchlen} -s {params.min_matchscore} -i <(pigz -t 1 -cd {input.forward}) -j <(pigz -t 1 -cd {input.reverse}) -v -o {output} 2> {log}"


rule kaiju_unpaired:
    input:
        "{project}/reformatted/{sample}_unpaired.fq.gz"
    output:
        "{project}/kaiju/{sample}_unpaired.tsv"
    conda:
        "envs/kaiju.yaml"
    log:
        "logs/kaiju/{sample}_unpaired.log"
    threads: 8
    params:
        kaiju_files = "-t {0}/nodes.dmp -f {0}/kaiju_db_nr_euk.fmi".format(config["kaiju"]["db"]),
        mode = config["kaiju"]["match-mode"],
        max_substitutions = config["kaiju"]["max-sub"],
        min_matchlen = config["kaiju"]["min-matchlen"],
        min_matchscore = config["kaiju"]["min-matchscore"]
    shell:
        "kaiju -z {threads} {params.kaiju_files} -a {params.mode} -e {params.max_substitutions} -m {params.min_matchlen} -s {params.min_matchscore} -i <(pigz -t 1 -cd {input}) -v -o {output} 2> {log}"


rule kaiju_binning:
    input:
        kaiju = "{project}/kaiju/{sample}_{paired}.tsv",
        fastq = "{project}/reformatted/{sample}_{paired}.fq.gz"
    output:
        "{project}/bins/{sample}_{paired}"
    conda:
        "envs/kaiju.yaml"
    log:
        "logs/binning/{sample}_{paired}_binning.log"
    threads: 1
    params:
        otu_file = config["kaiju"]["otu-file"]
    shell:
        "get_kaiju_otu.py -t {params.otu_file} -k {input.kaiju} -i {input.fastq} -o {output} -f -vv --log {log}"


rule kaiju_krona:
    input:
        "{project}/kaiju/{sample}_{paired}.tsv"
    output:
        html = "{project}/krona/{sample}_{paired}.html",
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
