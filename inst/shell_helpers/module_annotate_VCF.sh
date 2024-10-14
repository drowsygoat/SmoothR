#!/bin/bash

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="workshop"
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=1
DRY="no"
MODULES="bcftools"

# if [ -d "$JOB_NAME" ]; then
#     echo "Warning: Directory $JOB_NAME already exists." >&2
#     # exit 1
# else
#     mkdir -p "$JOB_NAME"
# fi

REF="/cfs/klemming/projects/snic/sllstore2017078/lech/sarek/refs/112/genome/Gallus_gallus.bGalGal1.mat.broiler.GRCg7b.dna_sm.toplevel.fa"

process_file() {
    # local input=$1
    # local name=$2

    echo ""
    # echo "Input: $input"
    # echo "Name: $name"

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" -o $MODULES \
    \
    '
    samtools view -F 1024 /cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/count_arc/ID34/outs/atac_possorted_bam.bam | grep CB:Z | \
    awk '\''BEGIN {OFS="\t"} { 
    cb = ""; 
    for (i=12; i<=NF; i++) { 
        if ($i ~ /^CB:Z:.*1/) cb = $i; 
    } 
    print $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, cb 

}'\'' > CB_only_ID34.sam
'
}

SAMPLES=$(find /cfs/klemming/projects/snic/sllstore2017078/lech/sarek/run1_no_GATK/variant_calling/concat -type f -name "*vcf.gz")

process_file

