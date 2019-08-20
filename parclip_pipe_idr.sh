//PARpipe published by the Ohler lab: https://github.com/ohlerlab/PARpipe
//IDR published by:
//Adding IDR to the PARpipe accomplished by Sarah Arcos: https://github.com/sarah_arcos


about title: "PARCLIP Pipeline"
CUSTOMSCRIPTS="../scripts/"
FILES="../files/"

ANNOTATOR="${CUSTOMSCRIPTS}annotate.pl"
BOWTIE="bowtie"
SAMTOOLS="samtools"
CUTADAPT="cutadapt"
BOWTIE_INDEX="${FILES}hg19"
GTF="${FILES}gencode.v19.chr_patch_hapl_scaff.annotation.gtf.gz"
BITFILE="${FILES}GRCh37.p12.genome.2bit"
//BOWTIE_INDEX="${FILES}mm10"
//GTF="${FILES}gencode.vM2.chr_patch_hapl_scaff.annotation.gtf.tar.gz"
//BITFILE="${FILES}GRCm38.p2.genome.2bit"
MEMORY_LIMIT="16G"
THREADS="4"
BOWTIE_PARAMS="-v 1 -m 10 --best --strata"
THREE_PRIME_ADAPTER_SEQUENCE="TCGTATGCCGTCTTCTGCTTG"
FIVE_PRIME_ADAPTER_SEQUENCE="AATGATACGGCGACCACCGACAGGTTCAGAGTTCTACAGTCCGACGATC"
NINETEEN_NUCLEOTIDE_MARKER_SEQUENCE="CGTACGCGGGTTTAAACGA"
TWENTY_FOUR_NUCLEOTIDE_MARKER_SEQUENCE="CGTACGCGGAATAGTTTAAACTGT"
CUTOFF=".6"

//Transforms the fastq into a fasta format, clips adapter and marker sequences, and collapses the reads
@Transform("fasta")
preprocess = {
	exec """
		cat $input1.fastq | ${CUSTOMSCRIPTS}fastqToFASTA.pl 2> ${input1}.processing |
		$CUTADAPT -a $THREE_PRIME_ADAPTER_SEQUENCE -g $FIVE_PRIME_ADAPTER_SEQUENCE
		-b $NINETEEN_NUCLEOTIDE_MARKER_SEQUENCE -b $TWENTY_FOUR_NUCLEOTIDE_MARKER_SEQUENCE
		-n 1 -m 20 - 2>> ${input1}.processing | ${CUSTOMSCRIPTS}collapseFA.pl > $output1
		
		cat $input2.fastq | ${CUSTOMSCRIPTS}fastqToFASTA.pl 2> ${input2}.processing |
		$CUTADAPT -a $THREE_PRIME_ADAPTER_SEQUENCE -g $FIVE_PRIME_ADAPTER_SEQUENCE
		-b $NINETEEN_NUCLEOTIDE_MARKER_SEQUENCE -b $TWENTY_FOUR_NUCLEOTIDE_MARKER_SEQUENCE
		-n 1 -m 20 - 2>> ${input2}.processing | ${CUSTOMSCRIPTS}collapseFA.pl > $output2
		
		cat $input3.fastq | ${CUSTOMSCRIPTS}fastqToFASTA.pl 2> ${input3}.processing |
		$CUTADAPT -a $THREE_PRIME_ADAPTER_SEQUENCE -g $FIVE_PRIME_ADAPTER_SEQUENCE
		-b $NINETEEN_NUCLEOTIDE_MARKER_SEQUENCE -b $TWENTY_FOUR_NUCLEOTIDE_MARKER_SEQUENCE
		-n 1 -m 20 - 2>> ${input3}.processing | ${CUSTOMSCRIPTS}collapseFA.pl > $output3
	"""
	doc desc:"fastqToFASTA.pl v2.0 and collapseFA.pl v2.0"
}

//Aligns reads to the genome and converts to sam format
@Transform("aligned.sam")
align = {
	exec """
	$BOWTIE $BOWTIE_INDEX $BOWTIE_PARAMS -p $THREADS -S --un unaligned_${input1} -f $input1 --quiet
	| samtools view -hS -F 4 - > $output1
	
		$BOWTIE $BOWTIE_INDEX $BOWTIE_PARAMS -p $THREADS -S --un unaligned_${input2} -f $input2 --quiet
	| samtools view -hS -F 4 - > $output2
	
		$BOWTIE $BOWTIE_INDEX $BOWTIE_PARAMS -p $THREADS -S --un unaligned_${input3} -f $input3 --quiet
	| samtools view -hS -F 4 - > $output3
	"""
	doc desc:"filterSAMMultiMapperTC.pl v2.0"
}

//Creates a .ini file containing parameters and file names to be used by PARalyzer
PARparams = {
	transform("aligned.sam") to("ini") {
        exec """
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $input1 $BITFILE > $output1
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $input2 $BITFILE > $output2
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

//Takes PARalyzer reads and converts to bam format
@Transform("bam")
sam2bam = {
        exec "samtools view -bhS $input4  | samtools sort -o - - > $output1"
        exec "samtools view -bhS $input8  | samtools sort -o - - > $output2"
        exec "samtools view -bhS $input12  | samtools sort -o - - > $output3"
}
//Uses the .bam file to create a .bam.bai format file: an index of the reads.
//@Transform("bai")
index = {
	produce ("${input1}.bai") {
	        exec "samtools index $input1"
	}
	forward input1
	
	produce ("${input2}.bai") {
	        exec "samtools index $input2"
	}
	forward input2
	
	produce ("${input3}.bai") {
	        exec "samtools index $input3"
	}
	forward input3
}

//Creates a file containing various attributes for each read
@Transform("attr")
readAttributes = {
	from ("sam") {
		exec "${CUSTOMSCRIPTS}readAttributesTC.pl $input1 > $output1"
	}
	
	from ("sam") {
		exec "${CUSTOMSCRIPTS}readAttributesTC.pl $input2 > $output2"
	}
	
	from ("sam") {
		exec "${CUSTOMSCRIPTS}readAttributesTC.pl $input3 > $output3"
	}
	doc desc:"readAttributesTC.pl v2.0"
}

//Creates an annotated csv file out of the attributes
@Transform("readcsv")
annotateReads = {
	exec """
	$ANNOTATOR -g $GTF -p ${CUSTOMSCRIPTS}annotationRank.txt
	-r ${FILES}hg19_rmsk.bed.gz -s ${FILES}hg19_rmsk_info -strict -oi $input1 > $output1
	
		$ANNOTATOR -g $GTF -p ${CUSTOMSCRIPTS}annotationRank.txt
	-r ${FILES}hg19_rmsk.bed.gz -s ${FILES}hg19_rmsk_info -strict -oi $input2 > $output2
	
		$ANNOTATOR -g $GTF -p ${CUSTOMSCRIPTS}annotationRank.txt
	-r ${FILES}hg19_rmsk.bed.gz -s ${FILES}hg19_rmsk_info -strict -oi $input3 > $output3
	"""
}

//Converts annotated csv to bed format
@Transform("readbed")
read_bed = {
	exec "${CUSTOMSCRIPTS}reads2bed.py $input1 > $output1"
	
	exec "${CUSTOMSCRIPTS}reads2bed.py $input2 > $output2"
		
	exec "${CUSTOMSCRIPTS}reads2bed.py $input3 > $output3"
	doc desc:"reads2bed.pl v2.0"
}

//Annotates clusters file and converts it to bed format
@Transform("clusterbed")
annotateClusters = {
	from ("clusters")
	exec """
		$ANNOTATOR -g $GTF -p ${CUSTOMSCRIPTS}annotationRank.txt
		-r ${FILES}hg19_rmsk.bed.gz -s ${FILES}hg19_rmsk_info -strict -oi $input |
		${CUSTOMSCRIPTS}PARclusters2bed.py > $output
	"""
	doc desc:"PARclusters2bed.py v2.0"
}

//Uses the .clusterbed file to create a .clusters.csv file, containing most useful cluster-level information
@Transform("clusters.csv")
addInfo = {
	from ("readbed","clusterbed") 
	exec """ 
		intersectBed -a $input1 -b $input2 -wao -s |
		awk -F "\t" 'BEGIN{OFS=",";} { print 
		\$5,\$7,\$8,\$9,\$11,\$12}' | sed '/,\\-1/d' |
		${CUSTOMSCRIPTS}editClustersTC.pl $CUTOFF > $output
	"""	
	doc desc:"editClustersTC.pl v2.0"
}

//Creates a .clusters.bed file out of the .clusters.csv file
@Transform("bed")
visbed = {
	exec "cat $input | ${CUSTOMSCRIPTS}visclusterbed.py > $output"
	forward input
	doc desc:"visclusterbed.py v2.0"
}

//Creates a file with format .gene_cl.csv, which contains gene-level information on cluster counts
geneLvl = {
        transform("clusters.csv") to("gene_cl.csv") {
        	exec "perl ${CUSTOMSCRIPTS}geneLevel.pl $input ${GTF} > $output"
	}
        doc desc:"geneLevel.pl v1.0"
}

//Annotates .groups file and converts to bed format
annotateGroups = {
	from("groups")
	transform("groupbed") {
	        exec """
			$ANNOTATOR -g $GTF -p ${CUSTOMSCRIPTS}annotationRank.txt
			-r ${FILES}hg19_rmsk.bed.gz -s ${FILES}hg19_rmsk_info -strict -oi $input |
	                ${CUSTOMSCRIPTS}PARclusters2bed.py > $output
		"""
	}
}

//Uses the .groupbed file to create a .groups.csv file, containing most useful group-level information
@Transform("groups.csv")
addInfoGroups = {
	from ("readbed","groupbed") 
	exec """ 
		intersectBed -a $input1 -b $input2 -wao -s |
		awk -F "\t" 'BEGIN{OFS=",";} { print 
		\$5,\$7,\$8,\$9,\$11,\$12}' | sed '/,\\-1/d' |
		${CUSTOMSCRIPTS}editClustersTC.pl > $output
	"""
	doc desc:"editClustersTC.pl v2.0"
}

//Creates a file with format .gene_gr.csv, which contains gene-level information on group counts
geneLvlGroups = {
	transform("groups.csv") to("gene_gr.csv") {
		exec "perl ${CUSTOMSCRIPTS}geneLevel.pl $input ${GTF} > $output"
	}
	doc desc:"geneLevel.pl v1.0"
}

//.clusters.txt file, which contains read, group, and cluster-level information across annotation categories, as well as processing information
statsTable = {
	from("readbed")
	transform("readbed") to("clusters.txt") {
		exec "${CUSTOMSCRIPTS}extractDataTC.pl ${input.prefix} > $output"
	}
}

//Runs the spatial perl script
spatialPerl = {
	from("readbed")
	produce("tmp_${input.prefix}_spatial.csv"){
	exec "perl ${CUSTOMSCRIPTS}Spatial.pl -g $GTF -a ${input.prefix} -strict -t ${FILES}isoforms.fpkm_tracking"
//	exec "perl ${CUSTOMSCRIPTS}Spatial.pl -g $GTF -a ${input.prefix} -strict"
	}
}

//Runs the spatial R script using output from the previous step to create graphs that visualize cluster distributions
spatialR = {
	from("readbed")
	R {"""
		yn<-'n'
		fn<-'${input.prefix}'
		resolution<-3
		install.packages('${CUSTOMSCRIPTS}colorRamps_2.3.tar.gz', lib='${CUSTOMSCRIPTS}')
		install.packages('${CUSTOMSCRIPTS}schoolmath_0.4.tar.gz', lib='${CUSTOMSCRIPTS}')
		install.packages('${CUSTOMSCRIPTS}gtools_3.4.1.tar.gz', lib='${CUSTOMSCRIPTS}')
		install.packages('${CUSTOMSCRIPTS}ellipse_0.3-8.tar.gz', lib='${CUSTOMSCRIPTS}')
		install.packages('${CUSTOMSCRIPTS}RColorBrewer_1.1-2.tar.gz', lib='${CUSTOMSCRIPTS}')
		install.packages('${CUSTOMSCRIPTS}LSD_2.5.tar.gz', lib='${CUSTOMSCRIPTS}')
		library(colorRamps, lib.loc='${CUSTOMSCRIPTS}')
		library(schoolmath, lib.loc='${CUSTOMSCRIPTS}')
		library(gtools, lib.loc='${CUSTOMSCRIPTS}')
		library(ellipse, lib.loc='${CUSTOMSCRIPTS}')
		library(RColorBrewer, lib.loc='${CUSTOMSCRIPTS}')
		library(LSD, lib.loc='${CUSTOMSCRIPTS}')
		library(parallel)
		source('${CUSTOMSCRIPTS}Spatial.R')
	"""}
}

Bpipe.run {
    preprocess + align + PARparams + PARalyze + sam2bam + index + readAttributes + annotateReads + read_bed + annotateClusters + addInfo + visbed + geneLvl + annotateGroups + addInfoGroups + geneLvlGroups + statsTable + spatialPerl + spatialR
}
