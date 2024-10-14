#!/bin/bash

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="workshop"
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=20
DRY="no"
MODULES="bcftools,samtools"

process_file() {

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" -o $MODULES \
    \
    'bedtools intersect -a reheadered_CB_only_ID34.bam -b variants_ID34.bed -wa -wb > tagged_variant_reads_ID34_wa_wb.bam'
}

process_file

