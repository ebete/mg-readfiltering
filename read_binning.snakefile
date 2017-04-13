rule metacluster:
    input:
        forward = lambda wildcards: config["data"][wildcards.sample]["forward"]["paired"],
        reverse = lambda wildcards: config["data"][wildcards.sample]["reverse"]["paired"]
    output:
        protected("{project}/kaiju/paired/{sample}.tsv")
    conda:
        "envs/metacluster.yaml"
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
