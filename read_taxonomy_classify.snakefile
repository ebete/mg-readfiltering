rule kaiju_paired:
    input:
        forward = "{project}/trimmomatic/{sample}_forward_paired.fq.gz",
        reverse = "{project}/trimmomatic/{sample}_reverse_paired.fq.gz"
    output:
        "{project}/kaiju/{sample}_paired.tsv"
    conda:
        "envs/kaiju.yaml"
    log:
        "{project}/logs/kaiju/{sample}_paired.log"
    threads: 8
    params:
        kaiju_files = "-t {0}/nodes.dmp -f {0}/kaiju_db_nr_euk.fmi".format(config["kaiju"]["db"]),
        mode = config["kaiju"]["match-mode"],
        max_substitutions = config["kaiju"]["max-sub"],
        min_matchlen = config["kaiju"]["min-matchlen"],
        min_matchscore = config["kaiju"]["min-matchscore"]
    shell:
        "kaiju -z {threads} {params.kaiju_files} -a {params.mode} -e {params.max_substitutions} -m {params.min_matchlen} -s {params.min_matchscore} -i <(pigz -p2 -cd {input.forward}) -j <(pigz -p2 -cd {input.reverse}) -v -o {output} 2> {log}"


rule kaiju_unpaired:
    input:
        "{project}/reformatted/{sample}_unpaired.fq.gz"
    output:
        "{project}/kaiju/{sample}_unpaired.tsv"
    conda:
        "envs/kaiju.yaml"
    log:
        "{project}/logs/kaiju/{sample}_unpaired.log"
    threads: 8
    params:
        kaiju_files = "-t {0}/nodes.dmp -f {0}/kaiju_db_nr_euk.fmi".format(config["kaiju"]["db"]),
        mode = config["kaiju"]["match-mode"],
        max_substitutions = config["kaiju"]["max-sub"],
        min_matchlen = config["kaiju"]["min-matchlen"],
        min_matchscore = config["kaiju"]["min-matchscore"]
    shell:
        "kaiju -z {threads} {params.kaiju_files} -a {params.mode} -e {params.max_substitutions} -m {params.min_matchlen} -s {params.min_matchscore} -i <(pigz -p2 -cd {input}) -v -o {output} 2> {log}"


rule kaiju_binning:
    input:
        kaiju = "{project}/kaiju/{sample}_{paired}.tsv",
        fastq = "{project}/reformatted/{sample}_{paired}.fq.gz"
    output:
        touch("{project}/bins/{sample}_{paired}/binning.done")
    conda:
        "envs/kaiju.yaml"
    log:
        "{project}/logs/bins/{sample}_{paired}_binning.log"
    threads: 8
    params:
        tax_rank = config["kaiju"]["tax-rank"],
        outdir = "{project}/bins/{sample}_{paired}"
    shell:
        "get_kaiju_otu.py -t {params.tax_rank} -k {input.kaiju} -i {input.fastq} -o {params.outdir} --threads {threads} -f -vv --log {log}"


rule bin_merge:
    input:
        expand("{{project}}/bins/{sample}_paired/binning.done", sample=config["data"])
    output:
        touch("{project}/bins/merged/binmerge.done")
    log:
        "{project}/logs/bins/merge.log"
    threads: 1
    resources:
        high_diskio = 1
    params:
        indirs = expand("{project}/bins/{sample}_paired/", project=config["project"], sample=config["data"]),
        outdir = "{project}/bins/merged/"
    shell:
        "finddups.py {params.indirs} {params.outdir} 2> {log}"


rule kaiju_krona:
    input:
        "{project}/kaiju/{sample}_{paired}.tsv"
    output:
        html = "{project}/krona/{sample}_{paired}.html",
        krona = "{project}/krona/{sample}_{paired}.krona"
    conda:
        "envs/kaiju.yaml"
    log:
        "{project}/logs/krona/{sample}_{paired}.log"
    threads: 1
    params:
        kaiju_files = "-t {0}/nodes.dmp -n {0}/names.dmp".format(config["kaiju"]["db"])
    shell:
        "(kaiju2krona {params.kaiju_files} -i {input} -o {output.krona} && "
        "ktImportText -o {output.html} {output.krona}) 2> {log}"
