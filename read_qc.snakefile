rule qc_reads:
    input:
        lambda wildcards: config["data"][wildcards.sample][wildcards.direction][wildcards.paired]
    output:
        protected("{project}/fastqc/{paired}/{sample}_{direction}")
    conda:
        "envs/fastqc.yaml"
    log:
        "logs/fastqc/{sample}_{direction}_{paired}.log"
    threads: 6 # Limits the amount of parallel jobs possible to prevent excessive disk IO
    shell:
        "mkdir -p {output} && "
        "fastqc --noextract -q -f fastq -t {threads} -o {output} {input} 2> {log}"


rule aggegrate_results:
    input:
        expand("{{project}}/fastqc/{paired}/{sample}_{direction}", paired=["paired", "unpaired"], sample=config["data"], direction=["forward", "reverse"])
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
        html="qc_report.html",
        trimmomatic_results="../data/"
    shell:
        "multiqc --interactive -n {params.html} -o {params.data} -z {input} {params.trimmomatic_results} 2> {log}"
