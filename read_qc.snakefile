rule extract_fq:
    input:
        forward = lambda wildcards: config["data"][wildcards.sample]["forward"],
        reverse = lambda wildcards: config["data"][wildcards.sample]["reverse"]
    output:
        forward = temp("{project}/scratch/raw_fq/{sample}_1.fastq"),
        reverse = temp("{project}/scratch/raw_fq/{sample}_2.fastq")
    threads: 1
    shell:
        "bzip2 -kdqc {input.forward} > {output.forward} && "
        "bzip2 -kdqc {input.reverse} > {output.reverse}"


rule qc_reads:
    input:
        forward = "{project}/scratch/raw_fq/{sample}_1.fastq",
        reverse = "{project}/scratch/raw_fq/{sample}_1.fastq"
    output:
        forward = protected("{project}/fastqc/{sample}_1"),
        reverse = protected("{project}/fastqc/{sample}_2")
    conda:
        "envs/fastqc.yaml"
    log:
        forward = "logs/fastqc/{sample}_1.log",
        reverse = "logs/fastqc/{sample}_2.log"
    threads: 1
    shell:
        "mkdir -p {output.forward} && "
        "fastqc --noextract -q -f fastq -t {threads} -o {output.forward} {input.forward} 2> {log.forward} && "
        "mkdir -p {output.reverse} && "
        "fastqc --noextract -q -f fastq -t {threads} -o {output.reverse} {input.reverse} 2> {log.reverse}"


rule aggegrate_results:
    input:
        expand("{{project}}/fastqc/{sample}_{strand}", sample=config["data"], strand=[1, 2])
    output:
        html="{project}/multiqc/qc_report.html",
        zip="{project}/multiqc/qc_report_data.zip"
    conda:
        "envs/multiqc.yaml"
    log:
        "logs/multiqc/multiqc.log"
    threads: 1
    params:
        data="{project}/multiqc/",
        html="qc_report.html"
    shell:
        "multiqc -n {params.html} -o {params.data} -z {input} 2> {log}"
