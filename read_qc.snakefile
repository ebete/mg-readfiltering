rule extract_fq_fwd:
    input:
        forward = lambda wildcards: config["data"][wildcards.rawread]["forward"]
    output:
        forward = temp("{project}/scratch/raw_fq/{rawread}_1.fastq")
    threads: 1
    shell:
        "bzip2 -kdqc {input.forward} > {output.forward}"


rule extract_fq_rev:
    input:
        reverse = lambda wildcards: config["data"][wildcards.rawread]["reverse"]
    output:
        reverse = temp("{project}/scratch/raw_fq/{rawread}_2.fastq")
    threads: 1
    shell:
        "bzip2 -kdqc {input.reverse} > {output.reverse}"


rule qc_reads:
    input:
        "{project}/scratch/raw_fq/{rawread_stranded}.fastq"
    output:
        protected("{project}/fastqc/{rawread_stranded}")
    conda:
        "envs/fastqc.yaml"
    log:
        "logs/fastqc/{rawread_stranded}.log"
    threads: 1
    shell:
        "mkdir -p {output} && "
        "fastqc --noextract -q -f fastq -t {threads} -o {output} {input} 2> {log}"


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
        "multiqc --interactive -n {params.html} -o {params.data} -z {input} 2> {log}"
