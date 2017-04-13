rule khmer_diginorm:
    input:
#        forward = "{project}/reformatted/{sample}_forward.fq.gz",
#        reverse = "{project}/reformatted/{sample}_reverse.fq.gz",
        paired = "{project}/reformatted/{sample}_paired.fq.gz",
        unpaired = "{project}/reformatted/{sample}_unpaired.fq.gz"
    output:
        fastq = protected("{project}/khmer/{sample}.fq.gz"),
        report = protected("{project}/khmer/{sample}.report.csv"),
        kmergraph = protected("{project}/khmer/{sample}.kmers")
    conda:
        "envs/khmer.yaml"
    log:
        "logs/khmer/{sample}_diginorm.log"
    threads: 8 # Limit disk IO to a reasonable level
    params:
        kmer = config["khmer"]["k-size"],
        cutoff_depth = config["khmer"]["depth-cutoff"],
        max_mem = "{}e9".format(config["khmer"]["max-gb-ram"])
    shell:
        "normalize-by-median.py -p -k {params.kmer} -M {params.max_mem} -C {params.cutoff_depth} -R {output.report} -s {output.kmergraph} -o {output.fastq} --gzip -u {input.unpaired} {input.paired} 2> {log}"
