#!/bin/bash

CUSTOMSCRIPTS="../scripts/"
FILES="../files/"
SAMTOOLS="samtools"
MEMORY_LIMIT="32G"
GTF="../../PARpipe/files/gencode.v19.chr_patch_hapl_scaff.annotation.gtf.gz"
BITFILE="../../PARpipe/files/GRCh37.p12.genome.2bit"
THREADS="7"
BOWTIE_PARAMS="-v 1 -m 10 --best --strata"
BOWTIE_INDEX="../../PARpipe/files/hg19"
BOWTIE="bowtie"

#get filenames without extensions or paths
#code from: https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
filename1=$(basename -- "$1")
extension1="${filename1##*.}"
filename1="${filename1%.*}"

filename2=$(basename -- "$2")
extension2="${filename2##*.}"
filename2="${filename2%.*}"

filename3=$(basename -- "$3")
extension3="${filename3##*.}"
filename3="${filename3%.*}"

# #call trim_galore and save to trim_galore directory
# echo "Performing trimming and fastQC with trim_galore"
# trim_galore --length 12 --output_dir trim_galore_${filename1}/ --fastqc --fastqc_args "--outdir trim_galore_${filename1}" "$1"
# 
# trim_galore --length 12 -a "GTGGAATTCTCGG" --output_dir trim_galore_${filename2}/ --fastqc --fastqc_args "--outdir trim_galore_${filename2}" "$2"
# 
# trim_galore --length 12 -a "GTGGAATTCTCGG" --output_dir trim_galore_${filename3}/ --fastqc --fastqc_args "--outdir trim_galore_${filename3}" "$3"
# 
# 
# #transform fastq into fasta and collapse reads
# echo "converting to fasta and collapsing reads"
# cat trim_galore_${filename1}/${filename1}_trimmed.fq | ${CUSTOMSCRIPTS}fastqToFASTA.pl |${CUSTOMSCRIPTS}collapseFA.pl > trim_galore_${filename1}/${filename1}_trimmed.fasta
# 
# cat trim_galore_${filename2}/${filename2}_trimmed.fq | ${CUSTOMSCRIPTS}fastqToFASTA.pl |${CUSTOMSCRIPTS}collapseFA.pl > trim_galore_${filename2}/${filename2}_trimmed.fasta
# 
# cat trim_galore_${filename3}/${filename3}_trimmed.fq | ${CUSTOMSCRIPTS}fastqToFASTA.pl |${CUSTOMSCRIPTS}collapseFA.pl > trim_galore_${filename3}/${filename3}_trimmed.fasta
# 
# #align with STAR and convert to sam format
# echo "align with STAR and convert to sam format"
# 
# $BOWTIE $BOWTIE_INDEX $BOWTIE_PARAMS -p $THREADS -S --un trim_galore_${filename1}/unaligned_${filename1}_trimmed.sam -f trim_galore_${filename1}/${filename1}_trimmed.fasta --quiet | samtools view -hS -F 4 - > trim_galore_${filename1}/${filename1}_trimmed.sam
# 
# $BOWTIE $BOWTIE_INDEX $BOWTIE_PARAMS -p $THREADS -S --un trim_galore_${filename2}/unaligned_${filename2}_trimmed.sam -f trim_galore_${filename2}/${filename2}_trimmed.fasta --quiet | samtools view -hS -F 4 - > trim_galore_${filename2}/${filename2}_trimmed.sam
# 
# $BOWTIE $BOWTIE_INDEX $BOWTIE_PARAMS -p $THREADS -S --un trim_galore_${filename3}/unaligned_${filename3}_trimmed.sam -f trim_galore_${filename3}/${filename3}_trimmed.fasta --quiet | samtools view -hS -F 4 - > trim_galore_${filename3}/${filename3}_trimmed.sam


# #Split replicates into pseudos and pools, and make directory structure
# echo "Making pseudo and pooled replicates"
# 
# mkdir PARalyzer_results
# 
# mkdir PARalyzer_results/${filename1}
# mkdir PARalyzer_results/${filename2}
# mkdir PARalyzer_results/${filename3}
# 
# # mkdir PARalyzer_results/pool${filename1}_${filename2}
# # mkdir PARalyzer_results/pool${filename1}_${filename3}
# # mkdir PARalyzer_results/pool${filename2}_${filename3}
# # 
# # #make pools
# # cat trim_galore_${filename1}/${filename1}_trimmed.sam trim_galore_${filename2}/${filename2}_trimmed.sam > PARalyzer_results/pool${filename1}_${filename2}/pool${filename1}_${filename2}.sam
# # cat trim_galore_${filename1}/${filename1}_trimmed.sam trim_galore_${filename3}/${filename3}_trimmed.sam > PARalyzer_results/pool${filename1}_${filename3}/pool${filename1}_${filename3}.sam
# # cat trim_galore_${filename2}/${filename2}_trimmed.sam trim_galore_${filename3}/${filename3}_trimmed.sam > PARalyzer_results/pool${filename2}_${filename3}/pool${filename2}_${filename3}.sam
# 
# #move true reps into directories
# cp trim_galore_${filename1}/${filename1}_trimmed.sam PARalyzer_results/${filename1}/${filename1}.sam
# cp trim_galore_${filename2}/${filename2}_trimmed.sam PARalyzer_results/${filename2}/${filename2}.sam
# cp trim_galore_${filename3}/${filename3}_trimmed.sam PARalyzer_results/${filename3}/${filename3}.sam

# #make pseudo of pools
# 
# ${CUSTOMSCRIPTS}pseudoreplicates.sh PARalyzer_results/pool${filename1}_${filename2}/pool${filename1}_${filename2}.sam
# ${CUSTOMSCRIPTS}pseudoreplicates.sh PARalyzer_results/pool${filename1}_${filename3}/pool${filename1}_${filename3}.sam
# ${CUSTOMSCRIPTS}pseudoreplicates.sh PARalyzer_results/pool${filename2}_${filename3}/pool${filename2}_${filename3}.sam
# 
# #make pseudo of true reps
# 
# ${CUSTOMSCRIPTS}pseudoreplicates.sh PARalyzer_results/${filename1}/${filename1}.sam
# ${CUSTOMSCRIPTS}pseudoreplicates.sh PARalyzer_results/${filename2}/${filename2}.sam
# ${CUSTOMSCRIPTS}pseudoreplicates.sh PARalyzer_results/${filename3}/${filename3}.sam

# #Make PARalyzer ini for all things that need it
# #code from: https://unix.stackexchange.com/questions/86722/how-do-i-loop-through-only-directories-in-bash
# echo "Making ini files for PARalyzer"
# for d in PARalyzer_results/*/ ; do
#     for file in $d*.sam; do
#         perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $file $BITFILE > ${file}.ini
#     done
# done
# 
# #Call PARalyzer on all things that need it
# 
# for d in PARalyzer_results/*/ ; do
#     for file in $d*.ini; do
#         ${CUSTOMSCRIPTS}PARalyzer ${MEMORY_LIMIT} $file
#     done
# done

# #Transform PARalyzer clusters file to narrowPeak
# echo "Transforming .clusters file to .narrowPeak file"
# for d in PARalyzer_results/*/ ; do
#     for file in $d*.clusters; do
#         ${CUSTOMSCRIPTS}clusters_to_narrowPeak.r $file
#     done
# done

#Setting up subdirectories to run remaining bpipe
echo "Setting up directory structure to run remaining PARpipe on PARalyzer outputs"
for d in PARalyzer_results/*/ ; do
    #mkdir ${d}pr1
    #mkdir ${d}pr2
    mkdir ${d}full
    #mv ${d}pr1*.* ${d}pr1
    #mv ${d}pr2*.* ${d}pr2
    mv ${d}*.* ${d}full
done

#Running second half of PARpipe on each directory of PARalyzer results
echo "Running the second half of PARpipe on each directory of PARalyzer results"
for d in PARalyzer_results/*/ ; do
    for sub_d in $d* ; do
        cd $sub_d
        cp *[0-9].sam original.sam
        rename '\_PARalyzer\_Utilized' '' *PARalyzer_Utilized.sam
        bpipe run -r ../../../parclip_pipe_secondhalf.sh *[0-9].sam
        cd ../../../
    done
done
        

















