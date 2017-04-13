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
        "kaiju -z {threads} {params.kaiju_files} -a {params.mode} -e {params.max_substitutions} -m {params.min_matchlen} -s {params.min_matchscore} -i <(pigz -t 1 -cd {input.forward}) -j <(pigz -t 1 -cd {input.reverse}) -v -o {output} 2> {log}"


rule kaiju_krona:
    input:
        "{project}/kaiju/paired/{sample}.tsv"
    output:
        html = protected("{project}/krona/{sample}.html"),
        krona = "{project}/krona/{sample}.krona"
    conda:
        "envs/kaiju.yaml"
    log:
        "logs/krona/{sample}.log"
    threads: 1
    params:
        kaiju_files = "-t {0}/nodes.dmp -n {0}/names.dmp".format(config["kaiju"]["db"])
    shell:
        "kaiju2krona {params.kaiju_files} -i {input} -o {output.krona} && "
        "ktImportText -o {output.html} {output.krona}"
