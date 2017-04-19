rule khmer_diginorm:
    input:
        paired = "{project}/reformatted/{sample}_paired.fq.gz",
        unpaired = "{project}/reformatted/{sample}_unpaired.fq.gz"
    output:
        fastq = protected("{project}/khmer/{sample}.fq.gz"),
        report = protected("{project}/khmer/{sample}.report.csv")
    conda:
        "envs/khmer.yaml"
    log:
        "logs/khmer/{sample}_diginorm.log"
    threads: 1
    resources: high_diskio=2 # Limit disk IO
    params:
        kmer = config["khmer"]["k-size"],
        cutoff_depth = config["khmer"]["depth-cutoff"],
        max_mem = "{}e9".format(config["khmer"]["max-gb-ram"])
    shell:
        "normalize-by-median.py -p -k {params.kmer} -M {params.max_mem} -C {params.cutoff_depth} -R {output.report} -o {output.fastq} --gzip -u {input.unpaired} {input.paired} 2> {log}"
