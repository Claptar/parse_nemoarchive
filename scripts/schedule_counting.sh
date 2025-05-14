#!/bin/bash

# Ensure correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <sample_dir>"
    exit 1
fi

sample_dir=$1
qsub_script=scripts/cellranger_count.qsub

for sample in $sample_dir/*; do
    qsub -v "FQDIR=$sample" $qsub_script
done
