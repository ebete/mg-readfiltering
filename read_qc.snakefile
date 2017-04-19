rule qc_reads:
    input:
        lambda wildcards: config["data"][wildcards.sample][wildcards.direction][wildcards.paired]
    output:
        html="{project}/fastqc/{sample}_{direction}_{paired}_fastqc.html",
        zip="{project}/fastqc/{sample}_{direction}_{paired}_fastqc.zip"
    conda:
        "envs/fastqc.yaml"
    log:
        "logs/fastqc/{sample}_{direction}_{paired}.log"
    threads: 6 # Limits the amount of parallel jobs possible to prevent excessive disk IO
    params:
        outdir="{project}/fastqc/"
    shell:
        "fastqc --noextract -q -f fastq -t {threads} -o {params.outdir} {input} 2> {log}"


rule aggegrate_results:
    input:
        expand("{{project}}/fastqc/{sample}_{direction}_{paired}_fastqc.zip", sample=config["data"], direction=["forward", "reverse"], paired=["paired", "unpaired"])
    output:
        html="{project}/multiqc/qc_report.html",
        zip="{project}/multiqc/qc_report_data.zip"
    conda:
        "envs/multiqc.yaml"
    log:
        "logs/multiqc/multiqc.log"
    threads: 1
    params:
        fastqc_results="{project}/fastqc/",
        outdir="{project}/multiqc/",
        html="qc_report.html",
        trimmomatic_results="../data/"
    shell:
        "multiqc --interactive -n {params.html} -o {params.outdir} -z {params.fastqc_results} {params.trimmomatic_results} 2> {log}"
