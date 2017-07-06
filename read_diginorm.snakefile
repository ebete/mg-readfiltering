rule kmer_histogram:
    input:
        "{project}/reformatted/{sample}_{paired}.fq.gz"
    output:
        "{project}/khmer/{sample}_{paired}.hist"
    conda:
        "envs/bbmap.yaml"
    log:
        "{project}/logs/bbmap/{sample}_{paired}_khist.log"
    threads: 8
    resources: high_diskio=4 # Limit disk IO
    params:
        kmer = config["khmer"]["k-size"],
        max_mem = "-Xmx{}G".format(config["khmer"]["max-gb-ram"])
    shell:
        "khist.sh {params.max_mem} threads={threads} in={input} hist={output} k={params.kmer} 2> {log}"


rule kmer_histo_graph:
    input:
        expand("{{project}}/khmer/{sample}_{paired}.hist", sample=SAMPLES, paired=PAIRED)
    output:
        done = touch("{project}/khmer/kdepth.done"),
        pdf = "{project}/khmer/multi_hist.pdf"
    conda:
        "envs/r.yaml"
    threads: 1
    script:
        "khist_plot_retention.R"


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
        "{project}/logs/khmer/{sample}_diginorm.log"
    threads: 1
    resources: high_diskio=2 # Limit disk IO
    params:
        kmer = config["khmer"]["k-size"],
        cutoff_depth = config["khmer"]["depth-cutoff"],
        max_mem = "{}e9".format(config["khmer"]["max-gb-ram"])
    shell:
        "normalize-by-median.py -p -k {params.kmer} -M {params.max_mem} -C {params.cutoff_depth} -R {output.report} -o {output.fastq} --gzip -u {input.unpaired} {input.paired} 2> {log}"
