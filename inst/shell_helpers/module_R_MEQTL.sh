#!/bin/bash

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="R_MEQTL_mod_test"
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=1
DRY="no"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# feature locations is the same as feaares data, the directory changes is resolved in the R script

snp_path="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/QTL_analysis/initial_atac/atac_QTL/data/chunks"

features_path="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/QTL_analysis/initial_atac/atac_QTL/seurat_cl_v3_group_SE_scale_1000_MEQTL_chunky_sl2000"

snp_loc_path="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/QTL_analysis/initial_atac/atac_QTL/data/chunks"

features_loc_path="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/QTL_analysis/initial_atac/atac_QTL/seurat_cl_v3_group_SE_scale_1000_MEQTL_chunky_sl2000"

covFilePath="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/QTL_analysis/initial_atac/atac_QTL/data/COV_VK_fixed_colnames.txt"


# Check if directories exist
if [ ! -d "$snp_path" ]; then
    echo "Error: Directory '$snp_path' does not exist."
    exit 1
fi

if [ ! -d "$features_path" ]; then
    echo "Error: Directory '$features_path' does not exist."
    exit 1
fi

if [ ! -d "$snp_loc_path" ]; then
    echo "Error: Directory '$snp_loc_path' does not exist."
    exit 1
fi

if [ ! -d "$features_loc_path" ]; then
    echo "Error: Directory '$features_loc_path' does not exist."
    exit 1
fi

# Check if file exists
if [ ! -f "$covFilePath" ]; then
    echo "Error: File '$covFilePath' does not exist."
    exit 1
fi

echo "All paths and file exist. Proceeding with the script."

R_SCRIPT="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/SmoothR/inst/shell_helpers/matrixEQTLrun.R"

process_file() {

    local input=$1
    local output=$2

    # Example modification: copy the file content (you can replace this with actual processing)

    echo "$input"
    echo "$output"

    export input output R_SCRIPT snp_path features_path snp_loc_path features_loc_path covFilePath TIMESTAMP stderr_stdout_R

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" '$R_SCRIPT $input $snp_path $snp_loc_path $features_path $features_loc_path $covFilePath 2>&1 > ${stderr_stdout_R}/R_out_${input}_${TIMESTAMP}.log'

}

# directories=()
# for dir in */ ; do
#     if [[ -d "$dir" ]]; then
#         directories+=("${dir%/}")  # Remove trailing slash and add to list
#     fi
# done
# mapfile -t snp_files < <(find "$snp_path" -maxdepth 1 -type f -regex ".*chunk_[0-9]+_SNPs.*")

input_directory=${1:-.}  # Default to current directory if no argument is given

output_directory=${2:-$input_directory}

# Create an output directory for Slurm and R output reports
output_dir="${input_directory}/slurm_reports"
output_dir_R="${input_directory}/R_console_output"

mkdir -p "$stderr_stdout"
mkdir -p "$stderr_stdout_R"

process_file $input_directory $output_directory



