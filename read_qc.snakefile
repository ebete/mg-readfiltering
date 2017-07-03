rule qc_reads_pre:
    input:
        "{project}/reformatted/{sample}_{paired}.fq.gz"
    output:
        html = "{project}/fastqc_pre/{sample}_{paired}_fastqc.html",
        zip = "{project}/fastqc_pre/{sample}_{paired}_fastqc.zip"
    conda:
        "envs/fastqc.yaml"
    log:
        "{project}/logs/fastqc/{sample}_{paired}.log"
    threads: 4
    resources: high_diskio=1 # Limit disk IO
    params:
        outdir = "{project}/fastqc_pre/"
    shell:
        "fastqc --noextract -q -f fastq -t {threads} -o {params.outdir} {input} 2> {log}"


rule qc_reads_post:
    input:
        "{project}/trimmomatic/{sample}_{direction}_{paired}.fq.gz"
    output:
        html = "{project}/fastqc_post/{sample}_{direction}_{paired}_fastqc.html",
        zip = "{project}/fastqc_post/{sample}_{direction}_{paired}_fastqc.zip"
    conda:
        "envs/fastqc.yaml"
    log:
        "{project}/logs/fastqc/{sample}_{direction}_{paired}.log"
    threads: 4
    resources: high_diskio=1 # Limit disk IO
    params:
        outdir = "{project}/fastqc_post/"
    shell:
        "fastqc --noextract -q -f fastq -t {threads} -o {params.outdir} {input} 2> {log}"


rule aggegrate_results_pre:
    input:
        expand("{{project}}/fastqc_pre/{sample}_{paired}_fastqc.zip", sample=config["data"], paired=PAIRED)
    output:
        html = "{project}/multiqc_pre/qc_report.html",
        zip = "{project}/multiqc_pre/qc_report_data.zip"
    conda:
        "envs/multiqc.yaml"
    log:
        "{project}/logs/multiqc/multiqc_pre.log"
    threads: 1
    params:
        fastqc_results = "{project}/fastqc_pre/",
        outdir = "{project}/multiqc_pre/",
        html = "qc_report.html"
    shell:
        "multiqc --interactive -n {params.html} -o {params.outdir} -z {params.fastqc_results} 2> {log}"


rule aggegrate_results_post:
    input:
        expand("{{project}}/fastqc_post/{sample}_{direction}_{paired}_fastqc.zip", sample=config["data"], direction=DIRECTION, paired=PAIRED)
    output:
        html = "{project}/multiqc_post/qc_report.html",
        zip = "{project}/multiqc_post/qc_report_data.zip"
    conda:
        "envs/multiqc.yaml"
    log:
        "{project}/logs/multiqc/multiqc_post.log"
    threads: 1
    params:
        fastqc_results = "{project}/fastqc_post/",
        outdir = "{project}/multiqc_post/",
        html = "qc_report.html",
        trimmomatic_results = "{project}/logs/trimmomatic/"
    shell:
        "multiqc --interactive -n {params.html} -o {params.outdir} -z {params.fastqc_results} {params.trimmomatic_results} 2> {log}"
