#!/bin/bash

# Ensure correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <filelist>"
    exit 1
fi

fastq_list=$1
qsub_script=scripts/curl_fastq.qsub

while read -r SAMPLE FILENAME LINK; do
    if [[ -f "${PWD}/${SAMPLE}/${FILENAME}" ]]; then
        echo "File ${SAMPLE}/${FILENAME} already exists. Skipping."
        continue
    fi

    mkdir -p "${PWD}/${SAMPLE}"
    #echo "Downloading $LINK to ${PWD}/${SAMPLE}/${FILENAME}"
    qsub -v "DIR=$SAMPLE, FILENAME=$FILENAME, LINK=$LINK" $qsub_script
done <"$fastq_list"
