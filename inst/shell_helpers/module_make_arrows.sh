#!/bin/bash

# Make arrows

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="cpus20_test_no_M"
PARTITION="shared"
NODES=1
TIME="23:00:00"
TASKS=1
CPUS=5
DRY="no"
MODULES="singularity"

if [ -d "$JOB_NAME" ]; then
    echo "Warning: Directory $JOB_NAME already exists." >&2
    # exit 1
else
    mkdir -p "$JOB_NAME"
fi

process_file() {
    local sample_id=$1
    local sample_path=$2
    local anno=$3
    local my_script=$4
    local cpus=$5

    echo ""
    echo "Processing: $sample_id"
    echo "Directory: $sample_path"
    echo "Anno: $anno"
    echo "R script to run: $my_script"  

    export sample_id sample_path anno my_script cpus JOB_NAME

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" -o "$MODULES" \
    'sing.sh -B /cfs/klemming/ r_archr Rscript "$my_script" --dir "$JOB_NAME" --name "$sample_id" --sample "$sample_path" --threads "$cpus" --gtf "$anno"'
}

ANNO="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/archr_gal7/geneAnnotation_gal7.rds"

SAMPLES="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/count_arc/gal7_fragment_samples.txt"

MY_SCRIPT="make_chicken_arrows.R"

while IFS=$'\t' read -r sample_path
do
    sample_id=$(echo $sample_path | awk -F'/' '{print $12}')
    echo "Processing: $sample_id"
    echo "Directory: $sample_path"

    if [[ ! $sample_id == "ID4" ]]; then
        continue
    fi

    echo "Processing: $sample_id"
    echo "Directory: $sample_path"
    echo "Anno: $ANNO"
    echo "R script to run: $MY_SCRIPT"

    process_file ${sample_id} ${sample_path} ${ANNO} ${MY_SCRIPT} ${CPUS}

done < "$SAMPLES"