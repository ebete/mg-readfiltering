#!/usr/bin/env Rscript

# Author: Thom Griffioen <t.griffioen@nioo.knaw.nl>
# 
# 
# Reads the histogram file from BBTools khist.sh and
# displays a plot signifying the depth distribution.
# 
# Modified to use in a Snakemake workflow

pdf(NULL)
library(ggplot2)

hist_file <- snakemake@input[[1]]
graph_out <- snakemake@output[[1]]

# https://github.com/stas-g/findPeaks
find_peaks <- function (x, m = 3) {
    shape <- diff(sign(diff(x, na.pad = FALSE)))
    pks <- sapply(which(shape < 0), FUN = function(i) {
        z <- i - m + 1
        z <- ifelse(z > 0, z, 1)
        w <- i + m + 1
        w <- ifelse(w < length(x), w, length(x))
        if(all(x[c(z : i, (i + 2) : w)] <= x[i + 1])) return(i + 1) else return(numeric(0))
        })
    pks <- unlist(pks)
    pks
}

yscale <- function(x) { sprintf("%.0e%%", x*100) }

# #Depth Raw_Count  Unique_Kmers
indata <- as.data.frame(read.csv(hist_file, sep='\t'))
# depth abundance frac cumulative_fraction
indata[,ncol(indata)] <- NULL
colnames(indata) <- c("depth", "abundance")
kmersum <- sum(indata$abundance)
indata$frac <- indata$abundance/kmersum
indata$cumulative_fraction <- cumsum(indata$frac)


peaks <- indata[find_peaks(indata$frac, 10), ]

ggplot(indata, aes(x=depth, y=frac, colour="Kmer abundance")) +
    geom_line() +
    xlim(1, 1000) +
    scale_y_continuous(trans="log10", labels=yscale) +
    geom_point(data=peaks, aes(colour="Peaks")) +
    geom_text(data=peaks, aes(label=ifelse(cumulative_fraction<0.999, depth, "")), hjust=0, vjust=-0.5) +
    scale_colour_manual("", breaks=c("Kmer abundance", "Peaks"), values=c("black", "red")) +
    xlab("duplicates found") +
    ylab("depth frequency") +
    ggtitle(sprintf("Duplicate k-mer density graph for '%s' (%.1f%% unique k-mers)", hist_file, indata$cumulative_fraction[2]*100))

ggsave(graph_out, width=10, height=7, device=cairo_pdf)
