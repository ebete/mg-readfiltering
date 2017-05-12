#!/usr/bin/env Rscript

# Author: Thom Griffioen <t.griffioen@nioo.knaw.nl>
# 
# 
# Reads the histogram files from BBMap khist.sh and
# displays a plot signifying the k-mer retention rate for
# a given minimum k-mer depth.

pdf(NULL)
library(ggplot2)
library(scales)
library(tools)

yscale <- function(x) { sprintf("%.2f%%", x*100) }

filesin <- snakemake@input
pdfout <- snakemake@output[["pdf"]]

histdata <- data.frame(histfile=NA, depth=NA, kcount=NA, kfreq=NA, cfreq=NA)

# Iterate over all the input files and calculate k-mer retention rates
for(arg in 1:length(filesin)) {
    # indata: #Depth | Raw_Count | Unique_Kmers
    indata <- as.data.frame(read.csv(filesin[[arg]], sep='\t'))
    kmersum <- sum(as.numeric(indata[, 2]))
    kmerfreq <- indata[, 2]/kmersum
    cumulative_frac <- cumsum(kmerfreq)
    gname <- file_path_sans_ext(basename(filesin[[arg]]))
    histdata <- rbind(histdata, data.frame(histfile=gname, depth=indata[, 1], kcount=indata[, 2], kfreq=kmerfreq, cfreq=1-cumulative_frac))
}
histdata <- histdata[complete.cases(histdata), ]

# Position of labels on the line plots
endrange <- 100
#labelpoints <- floor(seq(1, endrange, length.out=10))
labelpoints <- c(1, 5, 10, 25, 50)
points <- histdata[histdata$depth %in% labelpoints, ]

ggplot(histdata, aes(x=depth, y=cfreq, colour=histfile)) +
    geom_line() +
#    geom_hline(yintercept=0.00001) +
    geom_point(data=points) +
    geom_label(data=points, aes(label=sprintf("%d: %.1f%%", depth, cfreq*100)), hjust=-0.1, vjust=0.5, show.legend=FALSE) +
    scale_x_continuous(breaks=pretty_breaks(), limits=c(0, endrange)) +
    scale_y_continuous(labels=yscale, breaks=pretty_breaks(), limits=c(0, 1)) +
    xlab("minimum k-mer depth") +
    ylab("k-mer retention rate") +
    ggtitle("K-mer retention rate for a minimum depth") +
    guides(fill=guide_legend(nrow=2, byrow=TRUE)) +
    theme(
        plot.title = element_text(size=18, face="bold", hjust=0.5),
        legend.position = "bottom",
        legend.title = element_blank(),
        legend.key = element_rect(fill=NA), legend.background=element_rect(fill=NA)
    )

ggsave(pdfout, width=10, height=7)
