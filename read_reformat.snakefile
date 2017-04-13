# Reformats headers of FASTQ files and interleaves the pairs
rule merge_unpaired:
    input:
        forward = lambda wildcards: config["data"][wildcards.sample]["forward"]["unpaired"],
        reverse = lambda wildcards: config["data"][wildcards.sample]["reverse"]["unpaired"]
    output:
        "{project}/reformatted/{sample}_unpaired.fq.gz" # TODO: make temp later
    conda:
        "envs/bbmap.yaml"
    log:
        "logs/bbmap/{sample}_reformat_unpaired.log"
    threads: 8 # Limit disk IO
    shell:
        "(reformat.sh t={threads} in={input.forward} out=stdout.fq.gz trd > {output} && "
        "reformat.sh t={threads} in={input.reverse} out=stdout.fq.gz trd >> {output}) 2> {log}"


rule reformat_paired:
    input:
        forward = lambda wildcards: config["data"][wildcards.sample]["forward"]["paired"],
        reverse = lambda wildcards: config["data"][wildcards.sample]["reverse"]["paired"]
    output:
        interleaved = "{project}/reformatted/{sample}_paired.fq.gz" # TODO: make temp later
    conda:
        "envs/bbmap.yaml"
    log:
        "logs/bbmap/{sample}_reformat_pairs.log"
    threads: 8 # Limit disk IO
    shell:
        "(reformat.sh t={threads} in={input.forward} in2={input.reverse} out=stdout.fq trd addslash int | sed -e 's/ //g' | pigz -p {threads} -c > {output.interleaved}) 2> {log}"