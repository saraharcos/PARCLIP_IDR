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

//Generate pooled replicate
pooled = {
  produce("pooled.aligned.sam"){
    from("*aligned.sam"){
      exec """
        cat $inputs > $output1
      """
    }
  }
  forward(input1, input2, input3, output1)
}

//Generate pseudoreplicates and pooled replicates from aligned sam files
pseudoreplicates = {
  produce("*.aligned.sam"){
    from("*.aligned.sam"){
      exec """
        ${CUSTOMSCRIPTS}pseudoreplicates.sh $input1
        """
        
      exec """
        ${CUSTOMSCRIPTS}pseudoreplicates.sh $input2
        """
        
     exec """
        ${CUSTOMSCRIPTS}pseudoreplicates.sh $input3
        """
        
      exec """
        ${CUSTOMSCRIPTS}pseudoreplicates.sh $input4
        """    
    }
  }
  forward(input1, input2, input3, output1, output2, output3, output4, output5, output6, output7, output8)
  doc desc:"editPARalyzerINIfile.pl v2.0"
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
        
        exec """
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $input4 $BITFILE > $output4
        """
        
        exec """
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $input5 $BITFILE > $output5
        """
        
        exec """
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $input6 $BITFILE > $output6
        """
        
        exec """
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $input7 $BITFILE > $output7
        """
        
        exec """
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $input8 $BITFILE > $output8
        """
        
        exec """
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $input9 $BITFILE > $output9
        """
        
        exec """
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $input10 $BITFILE > $output10
        """
        
        exec """
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $input11 $BITFILE > $output11
        """
	}
	doc desc:"editPARalyzerINIfile.pl v2.0"
}

//Runs PARalyzer, creating clusters, groups, a distribution file, and a sam file of PARalyzer utilized reads
@Transform("*.sam")
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
  produce ("${input4.prefix}.clusters","${input4.prefix}.groups","${input4.prefix}.distribution","${input4.prefix}.sam") {
                exec "${CUSTOMSCRIPTS}PARalyzer ${MEMORY_LIMIT} $input4"
		exec "mv ${input4.prefix}_PARalyzer_Utilized.sam ${input4.prefix}.sam"
        }
  produce ("${input5.prefix}.clusters","${input5.prefix}.groups","${input5.prefix}.distribution","${input5.prefix}.sam") {
                exec "${CUSTOMSCRIPTS}PARalyzer ${MEMORY_LIMIT} $input5"
		exec "mv ${input5.prefix}_PARalyzer_Utilized.sam ${input5.prefix}.sam"
        }
  produce ("${input6.prefix}.clusters","${input6.prefix}.groups","${input6.prefix}.distribution","${input6.prefix}.sam") {
                exec "${CUSTOMSCRIPTS}PARalyzer ${MEMORY_LIMIT} $input6"
		exec "mv ${input6.prefix}_PARalyzer_Utilized.sam ${input6.prefix}.sam"
        }
        
  produce ("${input7.prefix}.clusters","${input7.prefix}.groups","${input7.prefix}.distribution","${input7.prefix}.sam") {
                exec "${CUSTOMSCRIPTS}PARalyzer ${MEMORY_LIMIT} $input7"
		exec "mv ${input7.prefix}_PARalyzer_Utilized.sam ${input7.prefix}.sam"
        }
  produce ("${input8.prefix}.clusters","${input8.prefix}.groups","${input8.prefix}.distribution","${input8.prefix}.sam") {
                exec "${CUSTOMSCRIPTS}PARalyzer ${MEMORY_LIMIT} $input8"
		exec "mv ${input8.prefix}_PARalyzer_Utilized.sam ${input8.prefix}.sam"
        }
  produce ("${input9.prefix}.clusters","${input9.prefix}.groups","${input9.prefix}.distribution","${input9.prefix}.sam") {
                exec "${CUSTOMSCRIPTS}PARalyzer ${MEMORY_LIMIT} $input9"
		exec "mv ${input9.prefix}_PARalyzer_Utilized.sam ${input9.prefix}.sam"
        }
  produce ("${input10.prefix}.clusters","${input10.prefix}.groups","${input10.prefix}.distribution","${input10.prefix}.sam") {
                exec "${CUSTOMSCRIPTS}PARalyzer ${MEMORY_LIMIT} $input10"
		exec "mv ${input10.prefix}_PARalyzer_Utilized.sam ${input10.prefix}.sam"
        }
  produce ("${input11.prefix}.clusters","${input11.prefix}.groups","${input11.prefix}.distribution","${input11.prefix}.sam") {
                exec "${CUSTOMSCRIPTS}PARalyzer ${MEMORY_LIMIT} $input11"
		exec "mv ${input11.prefix}_PARalyzer_Utilized.sam ${input11.prefix}.sam"
        }
}


Bpipe.run {
    preprocess + align + pooled + pseudoreplicates + PARparams + PARalyze
}
