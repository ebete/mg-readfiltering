rule recompress:
    input:
        lambda wildcards: config["data"][wildcards.sample][wildcards.direction]["path"]
    output:
        forward = temp("{project}/unpack/{sample}_{direction}.fq.gz")
    conda:
        "envs/compression.yaml"
    threads: 16
    resources: high_diskio=4 # Limit disk IO
    params:
        algo = lambda wildcards: config["data"][wildcards.sample][wildcards.direction]["compression"]
    shell:
        "{params.algo} -p{threads} -dc {input} | pigz -p{threads} > {output}"


rule trimmomatic:
    input:
        forward = "{project}/unpack/{sample}_forward.fq.gz",
        reverse = "{project}/unpack/{sample}_reverse.fq.gz"
    output:
        fw_paired = "{project}/trimmomatic/{sample}_forward_paired.fq.gz",
        fw_unpaired = "{project}/trimmomatic/{sample}_forward_unpaired.fq.gz",
        rev_paired = "{project}/trimmomatic/{sample}_reverse_paired.fq.gz",
        rev_unpaired = "{project}/trimmomatic/{sample}_reverse_unpaired.fq.gz"
    conda:
        "envs/trimmomatic.yaml"
    params:
        adapters = config["trimmomatic"]["adapters"],
        max_mismatch = config["trimmomatic"]["seed-mismatch"],
        palindrome_threshold = config["trimmomatic"]["palindrome-clip-threshold"],
        simple_threshold = config["trimmomatic"]["simple-clip-threshold"],
        min_adapter_len = config["trimmomatic"]["min-adapter-length"],
        keep_pair = config["trimmomatic"]["keep-both-reads"],
        window_size = config["trimmomatic"]["window-size"],
        avg_quality = config["trimmomatic"]["required-quality"],
        leading = config["trimmomatic"]["leading-min-quality"],
        trailing = config["trimmomatic"]["trailing-min-quality"],
        min_len = config["trimmomatic"]["min-length"]
    log:
        "{project}/logs/trimmomatic/{sample}.log" 
    threads: 16
    shell:
        "trimmomatic PE -threads {threads} -phred33 {input.forward} {input.reverse} {output.fw_paired} {output.fw_unpaired} {output.rev_paired} {output.rev_unpaired} ILLUMINACLIP:{params.adapters}:{params.max_mismatch}:{params.palindrome_threshold}:{params.simple_threshold}:{params.min_adapter_len}:{params.keep_pair} LEADING:{params.leading} TRAILING:{params.trailing} SLIDINGWINDOW:{params.window_size}:{params.avg_quality} MINLEN:{params.min_len} 2> {log}"
