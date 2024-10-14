#!/bin/bash

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="get_known_sites_vcf"
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=1
DRY="no"
MODULES="singularity"

if [ -d "$JOB_NAME" ]; then
    echo "Warning: Directory $JOB_NAME already exists." >&2
    # exit 1
else
    mkdir -p "$JOB_NAME"
fi

REF="/cfs/klemming/projects/snic/sllstore2017078/lech/sarek/refs/112/genome/Gallus_gallus.bGalGal1.mat.broiler.GRCg7b.dna_sm.toplevel.fa"

process_file() {
    local input=$1
    local name=$2

    echo ""
    echo "Input: $input"
    echo "Name: $name"

    export input name REF

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" -o $MODULES \
    \
    'zcat ${input} | bcftools view -e '\''INFO/SOURCE !~ "deepvariant"'\'' | bcftools view -i '\''FILTER="PASS"'\''| bcftools norm -m-any -f ${REF} -Oz -o ${name}.deepvariant.pass.vcf.gz;
    
    echo "1_done";

    zcat ${input} | bcftools view -e '\''INFO/SOURCE !~ "freebayes"'\'' | bcftools view -i '\''QUAL>30 && FORMAT/DP>10 && FORMAT/AO>3'\'' | bcftools norm -m-any -f ${REF} -Oz -o ${name}.freebayes.pass.vcf.gz;

    echo "2_done";

    zcat ${input} | bcftools view -e '\''INFO/SOURCE !~ "strelka"'\'' | bcftools view -i '\''FILTER="PASS"'\'' | bcftools norm -m-any -f ${REF} -Oz -o ${name}.strelka.pass.vcf.gz;

    echo "3_done";

    bcftools index ${name}.deepvariant.pass.vcf.gz;
    bcftools index ${name}.strelka.pass.vcf.gz;
    bcftools index ${name}.freebayes.pass.vcf.gz;
    
    echo "4_done"

    bcftools isec -p ${name}_isec_output -c both -n=3 ${name}.deepvariant.pass.vcf.gz ${name}.freebayes.pass.vcf.gz ${name}.strelka.pass.vcf.gz
    echo "5_done"

    cat ${name}_isec_output/0000.vcf > ${name}.pass.intersected.vcf 
    echo "6_done"
    
    bgzip ${name}.pass.intersected.vcf
    bcftools index ${name}.pass.intersected.vcf.gz
    '
}

cd "$JOB_NAME"

SAMPLES=$(find /cfs/klemming/projects/snic/sllstore2017078/lech/sarek/run1_no_GATK/variant_calling/concat -type f -name "*vcf.gz")

for SAMPLE in $SAMPLES; do

    # if [[ $SAMPLE =~ id_04 ]]; then
    #     continue
    # fi
    base=$(basename "$SAMPLE")
    name="${base%.vcf.gz}"

    # Define input file names
    in="$SAMPLE"
    
    echo $(pwd)
    # Run 
    process_file ${in} ${name}

done