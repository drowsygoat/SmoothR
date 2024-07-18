#!/bin/bash

# Usage: This script reads samples from a TSV file and submits Slurm jobs for processing each sample using an R script.
# Each sample is processed in its own folder within the specified output directory.
#
# Syntax:
#   ./submit_jobs.sh <time> <partition> <cores> <sample_table.tsv> <R_exec> <args...>
#
# Arguments:
#   time           - Job duration in format <days>-<HH>:<MM>:<SS>.
#   partition      - Slurm partition name (e.g., main, shared, long, memory, core, devel, node).
#   cores          - Number of cores (integer).
#   sample_table   - Path to the TSV file containing sample IDs and paths.
#   R_exec         - R script executable or command.
#   args           - Additional arguments to pass to the R script.
#
# Options:
#   -h, --help     - Display this help message and exit.
#
# example run:
#
# rr_archR_makeArrows.sh 02:00:00 core 8 <(awk 'NR > 1' /proj/sllstore2017078/single_cell/BackUp_CellRanger_VKumarMay10/rr_atac_samples.txt) make_chicken_arrows.R --gtf geneAnnotation_v1.rds
#
# make sample table:
# paste <(find $(pwd) -type f -name "*fragments*gz" | grep -E "l\/id_.{2}" | awk -F'/' '{print $5}') remaining_fragment_files.txt > rr_atac_remaining_samples.txt



print_usage() {
    echo "Usage: $0 <time> <partition> <cores> <sample_table.tsv> <R_exec> <args...>"
    echo "Arguments:"
    echo "  time            - Job duration in format <days>-<HH>:<MM>:<SS>"
    echo "  partition       - Slurm partition name"
    echo "  cores           - Number of cores (integer)"
    echo "  sample_table    - Path to TSV file with sample IDs and paths"
    echo "  R_exec          - R script executable or command"
    echo "  args            - Additional arguments for R script"
    exit 0
}

# Display usage if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    print_usage
fi

# Check for minimum number of required arguments
if [ "$#" -lt 5 ]; then
    echo "Error: Insufficient arguments provided."
    print_usage
fi

# Input validation using regular expressions
time_regex="^[0-9]+-[0-9]{2}:[0-9]{2}:[0-9]{2}$"
partition_regex="^(main|shared|long|memory|core|devel|node)$"
integer_regex="^[0-9]+$"

if ! [[ $1 =~ $time_regex ]]; then
    echo "Error: Invalid time format. Expected format <days>-<HH>:<MM>:<SS>"
    print_usage
elif ! [[ $2 =~ $partition_regex ]]; then
    echo "Error: Invalid partition name."
    print_usage
elif ! [[ $3 =~ $integer_regex ]]; then
    echo "Error: Number of cores must be an integer."
    print_usage
fi

# Assign input parameters
job_time=$1
partition=$2
cores=$3
sample_table=$4
r_script_exec=$5
shift 5
additional_args="$@"

# Get version of ArchRcode 
version=$(Rscript -e 'cat(Biobase::package.version("ArchR"), "\n")' 2> /dev/null)
echo "ArchR package version: $version"

# Request output directory name, default to "output_dir"
read -p "Enter the output directory name [default: output_dir]: " output_dir
output_dir="${output_dir:-output_dir}"

# Create necessary directories
mkdir -p "$output_dir" "${output_dir}/slurm_reports"

# Export variables for use within the sbatch script
export r_script_exec additional_args output_dir cores

# Read and process each sample from the TSV file
while IFS=$'\t' read -r sample_id sample_path; do
    echo "Processing: $sample_id"
    mkdir -p "${output_dir}/${sample_id}"

    # Submit job to Slurm
    sbatch <<-EOT
#!/bin/bash -eu
#SBATCH -A YOUR_ACCOUNT # Replace YOUR_ACCOUNT with your account
#SBATCH -J $sample_id
#SBATCH -o ${output_dir}/slurm_reports/${sample_id}_%j.out
#SBATCH -e ${output_dir}/slurm_reports/${sample_id}_%j.err
#SBATCH -t $job_time
#SBATCH -p $partition
#SBATCH -n $cores
#SBATCH --mail-user=YOUR_EMAIL # Replace YOUR_EMAIL with your email
#SBATCH --mail-type=ALL

ml R/4.1.1
ml R_packages/4.1.1

echo "Job \$SLURM_JOB_ID for sample $sample_id is running..."
start=\$(date +%s)

# Execute the R script
\$r_script_exec --dir \$output_dir --name \$sample_id --sample \$sample_path --threads \$cores \$additional_args || {
    echo "Error: R script execution failed."
    exit 1
}

echo "Job \$SLURM_JOB_ID for sample $sample_id completed."
end=\$(date +%s)
runtime=\$((end-start))
echo "Runtime: \$((runtime/3600)) hours and \$(((runtime%3600)/60)) minutes."
EOT

    echo "$sample_id job submitted."
done < "$sample_table"

echo "All jobs submitted."
    
