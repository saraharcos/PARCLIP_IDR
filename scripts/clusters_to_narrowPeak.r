#!/usr/bin/env Rscript
#Script to convert PARalyzer clusters output into ENCODE narrowPeak format

#Error handling copied from this blog post: https://www.r-bloggers.com/passing-arguments-to-an-r-script-from-command-lines/
#install.packages("readr", repos = "http://cran.us.r-project.org")
#install.packages("dplyr", repos = "http://cran.us.r-project.org")
#library(readr)
#library(dplyr)

# test if there is at least one argument: if not, return an error (from https://www.r-bloggers.com/passing-arguments-to-an-r-script-from-command-lines/)
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else if (length(args)==1) {
  # default output file
  args[2] = paste(args[1], ".narrowPeak", sep = "")
  args[2] = gsub(".clusters", "", args[2])
}

#testing

## Adapted from https://www.r-bloggers.com/passing-arguments-to-an-r-script-from-command-lines/
clusters = read.csv(args[1], stringsAsFactors = FALSE)

narrowPeak = data.frame(
  chr = clusters$Chromosome,
  start = clusters$ClusterStart,
  end = clusters$ClusterEnd,
  name = clusters$ClusterID,
  score = clusters$ModeScore,
  strand = clusters$Strand,
  signalValue = clusters$ModeScore,
  pValue = rep(-1, nrow(clusters)),
  qValue= rep(-1, nrow(clusters)),
  peak = clusters$ModeLocation,
  stringsAsFactors = FALSE
)

write.table(narrowPeak, args[2], col.names = FALSE, row.names = FALSE, sep = '\t', quote = FALSE)

