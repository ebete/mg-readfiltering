# Merges forward and reverse FASTQ files
rule reformat_paired:
    input:
        forward = "{project}/trimmomatic/{sample}_forward_paired.fq.gz",
        reverse = "{project}/trimmomatic/{sample}_reverse_paired.fq.gz"
    output:
        "{project}/reformatted/{sample}_paired.fq.gz" # TODO: make temp later
    conda:
        "envs/bbmap.yaml"
    log:
        "{project}/logs/bbmap/{sample}_reformat_pairs.log"
    threads: 4
    resources: high_diskio=4 # Limit disk IO
    shell:
        "reformat.sh t={threads} in={input.forward} in2={input.reverse} out={output} 2> {log}"


rule merge_unpaired:
    input:
        forward = "{project}/trimmomatic/{sample}_forward_unpaired.fq.gz",
        reverse = "{project}/trimmomatic/{sample}_reverse_unpaired.fq.gz"
    output:
        "{project}/reformatted/{sample}_unpaired.fq.gz" # TODO: make temp later
    threads: 1
    resources: high_diskio=4 # Limit disk IO
    shell:
        "cat {input} > {output}"
