//PARpipe published by the Ohler lab: https://github.com/ohlerlab/PARpipe
//IDR published by: Kundaje Lab ENCODE 3 ChIP-seq pipeline: https://docs.google.com/document/d/1lG_Rd7fnYgRpSIqrIfuVlAz2dW1VaSQThzk836Db99c/edit#
//Adding IDR to the PARpipe accomplished by Sarah Arcos: https://github.com/sarah_arcos


about title: "PARCLIP Pipeline"
CUSTOMSCRIPTS="../scripts/"
FILES="../files/"

ANNOTATOR="${CUSTOMSCRIPTS}annotate.pl"
STAR="STAR"
SAMTOOLS="samtools"
CUTADAPT="cutadapt"
STAR_INDEX="${FILES}star_genome"
GTF="${FILES}gencode.v19.chr_patch_hapl_scaff.annotation.gtf.gz"
BITFILE="${FILES}GRCh37.p12.genome.2bit"
MEMORY_LIMIT="32G"
THREADS="7"
STAR_PARAMS="--outFilterMismatchNoverReadLmax 0.1"
THREE_PRIME_ADAPTER_SEQUENCE="TGGAATTCTCGGGTGCCAAGG"
FIVE_PRIME_ADAPTER_SEQUENCE="CCTTGGCACCCGAGAATTCCA"
NINETEEN_NUCLEOTIDE_MARKER_SEQUENCE="CGTACGCGGGTTTAAACGA"
TWENTY_FOUR_NUCLEOTIDE_MARKER_SEQUENCE="CGTACGCGGAATAGTTTAAACTGT"
CUTOFF=".6"

//Transforms the fastq into a fasta format, clips adapter and marker sequences, and collapses the reads
preprocess = {
  transform("*.fastq") to(".fasta") {
  	exec """cat $input1.fastq | ${CUSTOMSCRIPTS}fastqToFASTA.pl 2> ${input1}.processing |
		$CUTADAPT -a $THREE_PRIME_ADAPTER_SEQUENCE -g $FIVE_PRIME_ADAPTER_SEQUENCE
		-b $NINETEEN_NUCLEOTIDE_MARKER_SEQUENCE -b $TWENTY_FOUR_NUCLEOTIDE_MARKER_SEQUENCE
		-n 1 -m 16 - 2>> ${input1}.processing | ${CUSTOMSCRIPTS}collapseFA.pl > $output1
		"""
	  exec """cat $input2.fastq | ${CUSTOMSCRIPTS}fastqToFASTA.pl 2> ${input1}.processing |
		$CUTADAPT -a $THREE_PRIME_ADAPTER_SEQUENCE -g $FIVE_PRIME_ADAPTER_SEQUENCE
		-b $NINETEEN_NUCLEOTIDE_MARKER_SEQUENCE -b $TWENTY_FOUR_NUCLEOTIDE_MARKER_SEQUENCE
		-n 1 -m 16 - 2>> ${input1}.processing | ${CUSTOMSCRIPTS}collapseFA.pl > $output2
		"""
	  exec """cat $input3.fastq | ${CUSTOMSCRIPTS}fastqToFASTA.pl 2> ${input1}.processing |
		$CUTADAPT -a $THREE_PRIME_ADAPTER_SEQUENCE -g $FIVE_PRIME_ADAPTER_SEQUENCE
		-b $NINETEEN_NUCLEOTIDE_MARKER_SEQUENCE -b $TWENTY_FOUR_NUCLEOTIDE_MARKER_SEQUENCE
		-n 1 -m 16 - 2>> ${input1}.processing | ${CUSTOMSCRIPTS}collapseFA.pl > $output3
		"""
  }
	doc desc:"fastqToFASTA.pl v2.0 and collapseFA.pl v2.0"
}

//Aligns reads to the genome and converts to sam format
align = {
  transform("*.fasta") to(".aligned.sam") {
    	exec """
	    $STAR --runThreadN $THREADS --genomeDir $STAR_INDEX $STAR_PARAMS --outStd SAM --readFilesIn ${input1} |
	    samtools view -hS -F 4 - > $output1
	    """
	    exec """
	    $STAR --runThreadN $THREADS --genomeDir $STAR_INDEX $STAR_PARAMS --outStd SAM --readFilesIn ${input2} |
	    samtools view -hS -F 4 - > $output2
	    """
    	exec """
    	$STAR --runThreadN $THREADS --genomeDir $STAR_INDEX $STAR_PARAMS --outStd SAM --readFilesIn ${input3} |
    	samtools view -hS -F 4 - > $output3
    	"""
  }
	
	doc desc:"filterSAMMultiMapperTC.pl v2.0"
}

Bpipe.run {
    preprocess + align
}
