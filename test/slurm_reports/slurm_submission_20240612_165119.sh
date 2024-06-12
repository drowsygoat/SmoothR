#!/bin/bash -eu
#SBATCH -A naiss2023-5-474
#SBATCH -J test
#SBATCH -o test/slurm_reports/%x_%j_20240612_165119.out
#SBATCH -t 0-00:05:00 # job time
#SBATCH -e test/slurm_reports/%x_%j_20240612_165119.err
#SBATCH -p devel
#SBATCH -n 1
#SBATCH --mail-user=user_did_not_provide_email@example.com
#SBATCH --mail-type=ALL

source ./test/.temp_modules_test

$R_SCRIPT $OUTPUT_DIR $R_SCRIPT $SUFFIX $TIMESTAMP $NUM_THREADS $ARGUMENTS 2>&1 | tee $OUTPUT_DIR/R_console_output/R_output_$TIMESTAMP.log >> $OUTPUT_DIR/R_output_cumulative.log
