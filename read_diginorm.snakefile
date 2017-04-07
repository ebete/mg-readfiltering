rule khmer_diginorm:
    input:
        forward = "{project}/otu-filtered/{sample}_forward.fastq",
        reverse = "{project}/otu-filtered/{sample}_reverse.fastq",
        unpaired = "{project}/otu-filtered/{sample}_unpaired.fastq"
    output:
        fasta = protected("{project}/khmer/{sample}.fasta.gz"),
        report = protected("{project}/khmer/{sample}.report.gz")
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
        "normalize-by-median.py -p -k {params.kmer} -M {params.max_mem} -C {params.cutoff_depth} -R {output.report} -o {output.fasta} --gzip -u {input.unpaired} {input.forward} {input.reverse}"
