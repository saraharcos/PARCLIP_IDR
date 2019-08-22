#!/bin/bash

#Code adapted from Kundaje Lab ENCODE 3 ChIP-seq pipeline: https://docs.google.com/document/d/1lG_Rd7fnYgRpSIqrIfuVlAz2dW1VaSQThzk836Db99c/edit#

infile="$1"

# Get total number of read pairs
nlines=$( cat "$infile" | wc -l )
nlines=$(( (nlines + 1) / 2 ))

#Function to get random seed based on file. 
#Taken from: https://www.gnu.org/software/coreutils/manual/html_node/Random-sources.html
get_seeded_random()
{
  seed=<(cat "$infile"| wc -c)
  openssl enc -aes-256-ctr -pass pass:"$seed" -nosalt \
    </dev/zero 2>/dev/null
}

#split into fileaa and fileab
cat "$infile" | shuf --random-source=<(get_seeded_random) | split -l ${nlines} - ${infile}

mv ${infile}aa pr1${infile}
mv ${infile}ab pr2${infile}