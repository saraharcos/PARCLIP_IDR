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
THREADS="4"
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

//Creates a .ini file containing parameters and file names to be used by PARalyzer
PARparams = {
	transform("*.aligned.sam") to(".ini") {
        exec """
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $input1 $BITFILE > $output1
        """
        
        exec """
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $input2 $BITFILE > $output2
        """
        
        exec """
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $input3 $BITFILE > $output3
        """
	}
	doc desc:"editPARalyzerINIfile.pl v2.0"
}

//Runs PARalyzer, creating clusters, groups, a distribution file, and a sam file of PARalyzer utilized reads
@Transform("sam")
PARalyze = {
	produce ("${input1.prefix}.clusters","${input1.prefix}.groups","${input1.prefix}.distribution","${input1.prefix}.sam") {
                exec "${CUSTOMSCRIPTS}PARalyzer ${MEMORY_LIMIT} $input1"
		exec "mv ${input1.prefix}_PARalyzer_Utilized.sam ${input1.prefix}.sam"
        }
  produce ("${input2.prefix}.clusters","${input2.prefix}.groups","${input2.prefix}.distribution","${input2.prefix}.sam") {
                exec "${CUSTOMSCRIPTS}PARalyzer ${MEMORY_LIMIT} $input2"
		exec "mv ${input2.prefix}_PARalyzer_Utilized.sam ${input2.prefix}.sam"
        }
  produce ("${input3.prefix}.clusters","${input3.prefix}.groups","${input3.prefix}.distribution","${input3.prefix}.sam") {
                exec "${CUSTOMSCRIPTS}PARalyzer ${MEMORY_LIMIT} $input3"
		exec "mv ${input3.prefix}_PARalyzer_Utilized.sam ${input3.prefix}.sam"
        }
}



Bpipe.run {
    preprocess + align + PARparams
}
