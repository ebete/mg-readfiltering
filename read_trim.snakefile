rule compress_raw_and_merge_lanes:
    input:
        lambda wildcards: config["data"][wildcards.sample][wildcards.readdirection]
    output:
        "{project}/unpack/{sample}_{readdirection}.fq.gz"
    message:
        "Compressing (raw > gzip) and merging lanes of sample {wildcards.sample}, direction {wildcards.readdirection} ..."
    conda:
        "envs/compression.yaml"
    threads: 8
    resources: high_diskio=4 # Limit disk IO
    shell:
        "pigz -p{threads} -kc {input} > {output}"


rule recompress_gz_and_merge_lanes:
    input:
        lambda wildcards: config["data"][wildcards.sample][wildcards.readdirection]
    output:
        "{project}/unpack/{sample}_{readdirection}.fq.gz"
    message:
        "Recompressing (gzip > gzip) and merging lanes of sample {wildcards.sample}, direction {wildcards.readdirection} ..."
    conda:
        "envs/compression.yaml"
    threads: 8
    resources: high_diskio=4 # Limit disk IO
    shell:
        # Decompression speed does not increase nearly as much as compression with more cores, so keep the core count lower than the compression.
        "pigz -p2 -dkc {input} | pigz -p{threads} -c > {output}"


rule recompress_bz2_and_merge_lanes:
    input:
        lambda wildcards: config["data"][wildcards.sample][wildcards.readdirection]
    output:
        "{project}/unpack/{sample}_{readdirection}.fq.gz"
    message:
        "Recompressing (bzip2 > gzip) and merging lanes of sample {wildcards.sample}, direction {wildcards.readdirection} ..."
    conda:
        "envs/compression.yaml"
    threads: 8
    resources: high_diskio=4 # Limit disk IO
    shell:
        # Decompression speed does not increase nearly as much as compression with more cores, so keep the core count lower than the compression.
        "pbzip2 -p2 -dkc {input} | pigz -p{threads} -c > {output}"


rule trimmomatic:
    input:
        forward = "{project}/unpack/{sample}_r1.fq.gz",
        reverse = "{project}/unpack/{sample}_r2.fq.gz"
    output:
        fw_paired = "{project}/trimmomatic/{sample}_forward_paired.fq.gz",
        fw_unpaired = "{project}/trimmomatic/{sample}_forward_unpaired.fq.gz",
        rev_paired = "{project}/trimmomatic/{sample}_reverse_paired.fq.gz",
        rev_unpaired = "{project}/trimmomatic/{sample}_reverse_unpaired.fq.gz"
    message:
        "Trimming adapters from sample {wildcards.sample} ..."
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
