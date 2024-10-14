#!/bin/bash

# Haplotypecaller valilla = no reclalibration - this is to get known variants

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="merge_known_sites_vcf"
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=10
DRY="no"
MODULES="bcftools"

if [ -d "$JOB_NAME" ]; then
    echo "Warning: Directory $JOB_NAME already exists." >&2
    # exit 1
else
    mkdir -p "$JOB_NAME"
fi

process_file() {
    local name=$1

    echo ""
    echo "name: $name"

    export name

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" -o $MODULES \
    \
    'vcf_files=$(find /cfs/klemming/projects/snic/sllstore2017078/lech/sarek/run1_no_GATK/get_known_sites_vcf -type f -name "*.${name}.vcf.gz")

    bcftools isec -n+2 -c both -p isec_output ${vcf_files};

    for vcf_file in isec_output/00*.vcf; do
        bgzip "$vcf_file"
    done;

    for vcf_file in isec_output/00*.vcf.gz; do
        bcftools index "$vcf_file"
    done;
    
    echo "1_done";

    bcftools merge -Oz -o merged_intersected.vcf.gz isec_output/00*.vcf.gz;
    bcftools merge -Ov -o merged_intersected.vcf isec_output/00*.vcf.gz

    echo "2_done";
    '
}

cd "$JOB_NAME"

name="germline.pass.intersected"

process_file ${name}
