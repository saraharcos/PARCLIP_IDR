//PARpipe published by the Ohler lab: https://github.com/ohlerlab/PARpipe
//IDR published by: Kundaje Lab ENCODE 3 ChIP-seq pipeline: https://docs.google.com/document/d/1lG_Rd7fnYgRpSIqrIfuVlAz2dW1VaSQThzk836Db99c/edit#
//Adding IDR to the PARpipe accomplished by Sarah Arcos: https://github.com/sarah_arcos


about title: "PARCLIP Pipeline"
CUSTOMSCRIPTS="../scripts/"
FILES="../files/"

ANNOTATOR="${CUSTOMSCRIPTS}annotate.pl"
STAR="star"
SAMTOOLS="samtools"
CUTADAPT="cutadapt"
STAR_INDEX="${FILES}hg19"
GTF="${FILES}gencode.v19.chr_patch_hapl_scaff.annotation.gtf.gz"
BITFILE="${FILES}GRCh37.p12.genome.2bit"
MEMORY_LIMIT="32G"
THREADS="4"
STAR_PARAMS="-v 1 -m 10 --best --strata"
THREE_PRIME_ADAPTER_SEQUENCE="TCGTATGCCGTCTTCTGCTTG"
FIVE_PRIME_ADAPTER_SEQUENCE="AATGATACGGCGACCACCGACAGGTTCAGAGTTCTACAGTCCGACGATC"
NINETEEN_NUCLEOTIDE_MARKER_SEQUENCE="CGTACGCGGGTTTAAACGA"
TWENTY_FOUR_NUCLEOTIDE_MARKER_SEQUENCE="CGTACGCGGAATAGTTTAAACTGT"
CUTOFF=".6"

//Transforms the fastq into a fasta format, clips adapter and marker sequences, and collapses the reads
preprocess = {
  transform("*.fastq") to(".fasta") {
  	exec "wc -l $input1.fastq > $output1.fasta"
	  exec "wc -l $input2.fastq > $output2.fasta"
	  exec "wc -l $input3.fastq > $output3.fasta"
  }
	doc desc:"fastqToFASTA.pl v2.0 and collapseFA.pl v2.0"
}

Bpipe.run {
    preprocess
}
