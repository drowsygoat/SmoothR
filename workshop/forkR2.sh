#!/bin/bash

# Script to setup and submit SLURM jobs for each directory with R script execution.

# Default values for job settings
TASKS="1"  # Default to 1 thread unless specified
JOB_TIME="01:00:00"  # Default job time (1 hour)
PARTITION="devel"  # Default partition is 'devel'
JOB_NAME="MEQTL_job_$TIMESTAMP"  # Default job name includes a timestamp

# Capture the current timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Parse command-line options using getopts
while getopts "J:n:t:p:N:" opt; do
  case ${opt} in
    J )
      JOB_NAME=${OPTARG}  # Job name specified with -J option
      ;;
    n )
      TASKS=${OPTARG}  # Number of threads specified with -n option
      ;;
    t )
      JOB_TIME=${OPTARG}  # Job time duration specified with -t option
      ;;
    p )
      PARTITION=${OPTARG}  # Partition specified with -p option
      ;;
    N )
      NODES=${OPTARG}  # Partition specified with -p option
      ;;
    # p )
    #   PARTITION=${OPTARG}  # Partition specified with -p option
    #   ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      exit 1
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      exit 1
      ;;
  esac
done

# Shift off the options and optional --
shift $((OPTIND -1))

# Command to execute (R script)
R_SCRIPT="$1"
echo -e "Running ${R_SCRIPT}\n"
shift 1
# Remaining arguments are treated as the command to run
# shellcheck disable=SC2124
ARGUMENTS="$@"

# if [[ $1 -eq 0 ]]; then
#     echo "Usage: $0 <directory_path>"
#     exit 1
# fi

snp_path="$1"
features_path="$2"
snp_loc_path="$3"
features_loc_path="$4"

if [ ! -d "$snp_path" ]; then
    echo "Error: Directory '$snp_path' does not exist."
    exit 1
fi

# Function to find a unique file based on a pattern in the specified directory
find_unique_file() {
    local search_dir=$1
    local file_pattern=$2

    # Search for files matching the pattern in the specified directory, non-recursively
    local found_files=$(find "$search_dir" -maxdepth 1 -type f -regex "$file_pattern")

    # Convert search results to an array
    IFS=$'\n' read -r -a files_array <<< "$found_files"

    # Check if exactly one unique file is found
    if [ "${#files_array[@]}" -eq 1 ]; then
        echo "${files_array[0]}"
        return 0
    else
        echo "No unique $file_pattern file found in $search_dir."
        return 1
    fi
}

# Function to search for file in current directory and then in $HOME if not found
find_file() {
    local file_pattern=$1
    local file

    # Try current directory first
    file=$(find_unique_file "." "$file_pattern")
    local status=$?

    # If not found, try $HOME
    if [ $status -ne 0 ]; then
        file=$(find_unique_file "$HOME" "$file_pattern")
        status=$?
    fi

    # If file is not found in both locations, handle the error
    if [ $status -ne 0 ]; then
        echo "Error: No unique $file_pattern file found or multiple files present."
        return 1
    fi

    echo "$file"
}

# Search for configuration and module files
module_file=$(find_file ".*temp_modules.*")

# Output the results
if [[ -f "$module_file" ]]; then
    echo "Module file used: $module_file with the following modules:"
    cat "$module_file"
else
    echo "No module file found or error occurred. Modules will not be loaded"
fi

# Get the current directory
current_dir=$(pwd)
# List directories in the current directory
directories=()
for dir in */ ; do
    if [[ -d "$dir" ]]; then
        directories+=("${dir%/}")  # Remove trailing slash and add to list
    fi
done

# Create an output directory for Slurm and R output reports
output_dir="${current_dir}/slurm_reports"
output_dir_r="${current_dir}/R_console_output"

mkdir -p "$output_dir"
mkdir -p "$output_dir_r"

# improve it by making a function to find files in in directory matching pattern and adding them to array

# mapfile -t snp_files < <(find "$snp_path" -maxdepth 1 -type f -regex ".*chunk_[0-9]+_SNPs.*")

# echo "${snp_files[@]}"
counter=0
# Loop through each subdirectory in the current directory
# Loop through each stored directory
for dir in "${directories[@]}"; do
    echo "Processing directory: $dir"
    if [[ ! $dir =~ group_[0-4]_results ]]; then
        #((counter++))
        continue
    fi
    sleep 1

    # Find all files recursively in the directory
    # files=$(find "$dir" -type f)
    # files_array=($files) # Convert to an array
    # mapfile -t feature_files < <(find ./${dir} -maxdepth 1 -type f -regex ".*chunk.*[0-9].*MEQTL.rds")

    # for snp_file in "${snp_files[@]}"; do
    #     # Construct the location file path by inserting '_loc' in the appropriate position
    #     loc_file="${snp_file/SNPs_VK_fixed_colnames.txt/loc_SNPs_VK_fixed_colnames.txt}"
    #     chunk_snp=$(echo "$snp_file" | grep -oE "chunk_[0-9]+")

    # Check if both files exist
        # if [ -f "$snp_file" ] && [ -f "$loc_file" ]; then
        #     echo ""
        #     echo "SNP file: $snp_file"
        #     echo "SNP location file: $loc_file"
        #     echo "SNP chunk: $chunk_snp"
        #     for feature_file in "${feature_files[@]}"; do
        #         loc_feature=$(echo "$feature_file" | sed -E 's/group_[0-9]+_//g; s/input/loc_input/' | xargs basename)
        #         chunk_feature=$(echo "$feature_file" | grep -oE "chunk.*[0-9]+")

        #         if [ -f "$loc_feature" ] && [ -f "$feature_file" ]; then
        #             echo ""
        #             echo "Feature file: $feature_file"
        #             echo "Feature location file: $loc_feature"
        #             echo "Feature chunk: $chunk_feature"
                    

        #             if [[ $counter == 2 ]]; then
        #                 #((counter++))
        #                 exit 0
        #             fi

        #             if [[ $chunk_snp != "chunk_2" ]]; then
        #                 #((counter++))
        #                 continue
        #             fi

                    # if [[ $counter == 10 ]]; then
                    #     #((counter++))
                    #     exit 0
                    # fi

                    # if [[ $counter -lt 3 ]]; then
                    #     #((counter++))
                    #     continue
                    # fi
                     
                    
                    export R_SCRIPT ARGUMENTS dir module_file output_dir_r TIMESTAMP snp_file loc_file loc_feature feature_file chunk_feature chunk_snp snp_path features_path snp_loc_path features_loc_path TASKS # some arguments can be removed

                    # Submit a Slurm job for each directory
                    JOB_ID=$(sbatch <<-EOT
#!/bin/bash
#SBATCH -A ${COMPUTE_ACCOUNT}
#SBATCH -J ${JOB_NAME}_${dir}_${chunk_snp}_${chunk_feature}
#SBATCH -o slurm_reports/%x_%j_${TIMESTAMP}.out
#SBATCH -t ${JOB_TIME}
#SBATCH -N ${NODES}
#SBATCH -p ${PARTITION}
#SBATCH -n ${TASKS}
#SBATCH --mail-user=YOUR_EMAIL # Replac e YOUR_EMAIL with your email
#SBATCH --mail-type=ALL
#SBATCH --parsable

# source \$module_file
module load PDC/23.12 R/4.4.0 harfbuzz fribidi libpng libtiff libjpeg-turbo

echo "Job \$SLURM_JOB_ID for directory \$dir is running..."
start=\$(date +%s)

# ./\$R_SCRIPT \$dir \$TASKS \$snp_file \$loc_file \$feature_file \$loc_feature 2>&1 > \$output_dir_r/R_out_\${dir}_\${chunk_snp}_\${chunk_feature}_\${TIMESTAMP}.log 

./\$R_SCRIPT \$dir \$TASKS \$snp_path \$snp_loc_path \$features_path \$features_loc_path 2>&1 > \$output_dir_r/R_out_\${dir}_\${chunk_snp}_\${chunk_feature}_\${TIMESTAMP}.log 

echo "Job \$SLURM_JOB_ID for directory \$dir completed."
end=\$(date +%s)
runtime=\$((end-start))
echo "Runtime: \$((runtime/3600)) hours and \$(((runtime%3600)/60)) minutes."

EOT
                    )
    #             else
    #                 echo "Missing files."
    #             fi
    #             echo -e "Job ID $JOB_ID for $dir and $(basename $snp_file) submitted.\n" | tee >> fork_output.log

    #             read -t 1 -n 1 input

    #             if [[ $input = "c" ]]; then
    #                 tput setaf 1
    #                 echo ""
    #                 echo "Operation stopped by the user."
    #                 tput sgr 0
    #                 exit 1
    #             else
    #                 unset input
    #             fi
    #         done
    #     fi
    # done
done

echo "All jobs submitted."

echo 



