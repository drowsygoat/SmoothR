#!/bin/bash

# run count
# cellranger-arc must me in PATH

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="count_arc"
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=8
CPUS=1
DRY="dry"

ALL_LIBS="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/libraries/cumulative_libraries.csv"

SAMPLES=$(tail -n +2 "$ALL_LIBS" | awk -F, '{print $2}' | sort | uniq)

REF="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/single_cell_gal7b/mkref/bGalGal1_mat_broiler_GRCg7b"

process_file() {

    local sample=$1
    local libraries=$2
    local reference=$3

    export reference libraries REF

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" \
    'cellranger-arc count --id=$sample \
                          --reference=$REF \
                          --libraries=$libraries \
                          --localcores=8 \
                          --localmem=16'
}

for SAMPLE in $SAMPLES; do
    # Create a temporary CSV file for each SAMPLE
    LIBS="LIBS_${SAMPLE}.csv"

    # Add the header row to the LIBS file
    head -n 1 "$ALL_LIBS" > "$LIBS"

    # Append the rows matching the current SAMPLE to the LIBS file
    awk -F, -v SAMPLE="$SAMPLE" '$2 == SAMPLE' "$ALL_LIBS" >> "$LIBS"

    # Inform the user about the created file
    echo "Created library file: $LIBS"

    process_file $SAMPLE $LIBS $REF

done


