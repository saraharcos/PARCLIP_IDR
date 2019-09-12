#!/bin/bash

CUSTOMSCRIPTS="../scripts/"
FILES="../files/"
BITFILE="${FILES}GRCh37.p12.genome.2bit"
MEMORY_LIMIT="32G"

#Call bpipe first modules on all 3 input replicates

bpipe run test_parpipe_firsthalf.sh "$1" "$2" "$3"

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

#Split replicates into pseudos and pools, and make directory structure

mkdir ${filename1}
mkdir ${filename2}
mkdir ${filename3}

mkdir pool${filename1}_${filename2}
mkdir pool${filename1}_${filename3}
mkdir pool${filename2}_${filename3}

#make pools
cat ${filename1}.aligned.sam ${filename2}.aligned.sam > pool${filename1}_${filename2}/pool${filename1}_${filename2}.aligned.sam
cat ${filename1}.aligned.sam ${filename3}.aligned.sam > pool${filename1}_${filename3}/pool${filename1}_${filename3}.aligned.sam
cat ${filename2}.aligned.sam ${filename3}.aligned.sam > pool${filename2}_${filename3}/pool${filename2}_${filename3}.aligned.sam

#move true reps into directories
mv ${filename1}.aligned.sam ${filename1}/${filename1}.aligned.sam
mv ${filename2}.aligned.sam ${filename2}/${filename2}.aligned.sam
mv ${filename3}.aligned.sam ${filename3}/${filename3}.aligned.sam

#make pseudo of pools

${CUSTOMSCRIPTS}pseudoreplicates.sh pool${filename1}_${filename2}/pool${filename1}_${filename2}.aligned.sam
${CUSTOMSCRIPTS}pseudoreplicates.sh pool${filename1}_${filename3}/pool${filename1}_${filename3}.aligned.sam
${CUSTOMSCRIPTS}pseudoreplicates.sh pool${filename2}_${filename3}/pool${filename2}_${filename3}.aligned.sam

#make pseudo of true reps

${CUSTOMSCRIPTS}pseudoreplicates.sh ${filename1}/${filename1}.aligned.sam
${CUSTOMSCRIPTS}pseudoreplicates.sh ${filename2}/${filename2}.aligned.sam
${CUSTOMSCRIPTS}pseudoreplicates.sh ${filename3}/${filename3}.aligned.sam

#Make PARalyzer ini for all things that need it
#code from: https://unix.stackexchange.com/questions/86722/how-do-i-loop-through-only-directories-in-bash
echo "Making ini files for PARalyzer"
for d in */ ; do
    for file in $d*; do
        perl ${CUSTOMSCRIPTS}editPARalyzerINIfile.pl ${CUSTOMSCRIPTS}Default_PARalyzer_Parameters.ini $file $BITFILE > ${file}.ini
    done
done

#Call PARalyzer on all things that need it
for d in */ ; do
    for file in $d*.ini; do
        ${CUSTOMSCRIPTS}PARalyzer ${MEMORY_LIMIT} $file
    done
    for file in $d*PARalyzer_Utilized.sam; do
        mv $file ${file}.sam
    done
done










#Call IDR on replicates pairwise

#Call last bpipe modules on final peak list