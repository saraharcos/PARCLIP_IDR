#!/usr/bin/env Rscript
#Script to convert PARalyzer clusters output into ENCODE narrowPeak format

#Error handling copied from this blog post: https://www.r-bloggers.com/passing-arguments-to-an-r-script-from-command-lines/
install.packages("readr", quiet = TRUE, repos = "http://cran.us.r-project.org")
install.packages("dplyr", quiet = TRUE, repos = "http://cran.us.r-project.org")
library(readr)
library(dplyr)

# test if there is at least one argument: if not, return an error (from https://www.r-bloggers.com/passing-arguments-to-an-r-script-from-command-lines/)
args = commandArgs(trailingOnly=TRUE)
if (length(args)==0) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} else if (length(args)==1) {
  # default output file
  args[2] = paste(args[1], ".narrowPeak", sep = "")
}

#testing

## Adapted from https://www.r-bloggers.com/passing-arguments-to-an-r-script-from-command-lines/
clusters = read_csv(args[1])

narrowPeak = tibble(
  chr = clusters$Chromosome,
  start = clusters$ClusterStart,
  end = clusters$ClusterEnd,
  name = clusters$ClusterID,
  score = clusters$ConversionEventCount,
  strand = clusters$Strand,
  signalValue = clusters$ModeScore,
  pValue = -1,
  qValue= -1,
  peak = -1
)

write_tsv(narrowPeak, args[2], colnames = FALSE)

