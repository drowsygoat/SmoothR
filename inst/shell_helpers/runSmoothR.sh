#!/bin/bash

# Description:
# A versatile SLURM job launcher for R scripts, designed for automated iterative analyses with monitoring capabilities.
# Features include:
# - Continuous monitoring of output for "CHECKPOINT" tags.
# - Ability to cancel jobs quickly after submission.
# - Utilization of tmux for maintaining session activity during long jobs.

# SLURM Job Parameters:
# NUM_THREADS: Number of threads (default: 1)
# JOB_TIME: Job duration in format D-HH:MM (default: "00:05:00")
# OUTPUT_DIR: Directory to store results (default: "./output_dir")
# PARTITION: SLURM partition (default: "devel")
# SUFFIX: Suffix for output files, using a timestamp by default.
# R_SCRIPT: The R script filename to execute.

# Creating a timestamp for session and file naming
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Searching for configuration file
found_files=$(find . -type f | grep "temp_shell_exports")

# Converting search results to an array
IFS=$'\n' read -r -a files_array <<< "$found_files"

# Ensuring a unique configuration file is found
if [ "${#files_array[@]}" -eq 1 ]; then
    echo "Unique configuration file found."
    config_file="${files_array[0]}"
    echo "Using configuration from: $config_file"
else
    echo "Error: No configuration file found or multiple configurations present."
    exit 1
fi

source $config_file

# Setting default parameters if they are not already set
NUM_THREADS="${NUM_THREADS:-1}"
JOB_TIME="${JOB_TIME:-"00:05:00"}"
OUTPUT_DIR="${OUTPUT_DIR:-"./output_dir"}"
PARTITION="${PARTITION:-"devel"}"
SUFFIX="${SUFFIX:-"$(date +%Y%m%d_%H%M%S)"}"
USER_E_MAIL="${USER_E_MAIL:-user_did_not_provide_email@example.com}"

# Function to display script usage
function display_help() {
    echo "Usage: $0 R_SCRIPT [ARG1 ARG2 ...]"
    echo
    echo "Launches a SLURM job to execute an R script with the specified parameters."
    echo
    echo "Example:"
    echo "  ./runSmoothR.sh my_analysis.R additional_arguments"
    exit 1
}

# Display help if no script argument provided
if [ "$#" -lt 1 ]; then
    display_help
fi

# Shift script argument and assign remaining arguments
R_SCRIPT="$1"
shift 1
ARGUMENTS="$@"

# Define color settings using tput
color_key=$(tput setaf 4)   # Blue color for keys
color_value=$(tput setaf 2) # Green color for values
color_reset=$(tput sgr0)    # Reset to default terminal color

# Display settings
echo "Parameters set. Here are the current settings:"
echo -e "${color_key}Number of threads: ${color_value}$NUM_THREADS${color_reset}"
echo -e "${color_key}Job time: ${color_value}$JOB_TIME${color_reset}"
echo -e "${color_key}Output directory: ${color_value}$OUTPUT_DIR${color_reset}"
echo -e "${color_key}Partition: ${color_value}$PARTITION${color_reset}"
echo -e "${color_key}Suffix: ${color_value}$SUFFIX${color_reset}"
echo -e "${color_key}Timestamp: ${color_value}$TIMESTAMP${color_reset}"
echo -e "${color_key}Account: ${color_value}$USER_ACCOUNT${color_reset}"

# Define functions to check output file modifications and monitor job status
function was_file_modified_last_minute() {
    local file="$1"
    if [ -f "$file" ]; then
        local current_time=$(date +%s)
        local modification_time=$(stat -c %Y "$file")
        local elapsed_time=$(( current_time - modification_time ))
        [[ $elapsed_time -le 60 ]]
    fi
}

check_file() {
    # Define output file path
    local OUTPUT_FILE="${OUTPUT_DIR}/R_console_output/R_output_${TIMESTAMP}.log"
    
    # Define the regex pattern
    local KEYWORD='^CHECKPOINT.*$'
    
    # Check if the output file exists and has been modified in the last minute
    if [ -f "$OUTPUT_FILE" ]; then
        if was_file_modified_last_minute "$OUTPUT_FILE"; then
            local current_count=$(grep -c "$KEYWORD" "$OUTPUT_FILE")
            if [[ $current_count -gt $phrase_found_count ]]; then
            phrase_found_count=$current_count
            last_keyword_found=$(grep -o "$KEYWORD" "$OUTPUT_FILE" | tail -1)
            tput setaf 3 # yellow ;)
            echo ""
            echo "$(echo $last_keyword_found | sed 's/CHECKPOINT_//g')"
            tput sgr 0
            echo -n "Monitoring job status for Job ID: $current_status" # single instance below dots    
            current_count=$((current_count + 1))
            fi
        fi
    fi
}

function print_job_status() {
    current_status=$(sacct --brief --jobs $JOB_ID | awk -v job_id="$JOB_ID" '$1 == job_id {print $1, $2}')
    if [[ "$last_status" != "$current_status" ]]; then
        echo ""
        echo -n "Monitoring job status for Job ID: $current_status"
        last_status="$current_status"
    else
        echo -n "."
        check_file
    fi
}

function is_job_active() {
    local active_jobs=$(sacct --jobs $JOB_ID | grep -E "RUNNING|PENDING" | wc -l)
    return $(( active_jobs == 0 ))
}

# Check and create output directory
if [ -d "$OUTPUT_DIR" ]; then
    tput setaf 1
    echo -e "WARNING: The directory $OUTPUT_DIR already exists files may be overwritten."
    tput sgr 0
fi

mkdir -p "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/slurm_reports"
mkdir -p "${OUTPUT_DIR}/R_console_output"

# Prepare and execute SLURM job

SBATCH_SCRIPT="${OUTPUT_DIR}/slurm_reports/slurm_submission_${TIMESTAMP}.sh"

cat <<EOF > "$SBATCH_SCRIPT"
#!/bin/bash -eu
#SBATCH -A $COMPUTE_ACCOUNT_LECH
#SBATCH -J ${OUTPUT_DIR}
#SBATCH -o ${OUTPUT_DIR}/slurm_reports/%x_%j_${TIMESTAMP}.out
#SBATCH -t $JOB_TIME # job time
#SBATCH -e ${OUTPUT_DIR}/slurm_reports/%x_%j_${TIMESTAMP}.err
#SBATCH -p $PARTITION
#SBATCH -n $NUM_THREADS
#SBATCH --mail-user=$USER_E_MAIL
#SBATCH --mail-type=ALL

module load R/4.1.1
module load R_packages/4.1.1

./\$R_SCRIPT \$OUTPUT_DIR \$R_SCRIPT \$SUFFIX \$TIMESTAMP \$NUM_THREADS \$ARGUMENTS 2>&1 | tee \$OUTPUT_DIR/R_console_output/R_output_\$TIMESTAMP.log >> \$OUTPUT_DIR/R_output_cumulative.log
EOF

# cat <<EOF > "$FAT_SCRIPT"
# #!/bin/bash -eu
# #SBATCH -A $COMPUTE_ACCOUNT_LECH
# #SBATCH -J ${OUTPUT_DIR}
# #SBATCH -o ${OUTPUT_DIR}/slurm_reports/%x_%j_${TIMESTAMP}.out
# #SBATCH -t $JOB_TIME # job time
# #SBATCH -e ${OUTPUT_DIR}/slurm_reports/%x_%j_${TIMESTAMP}.err
# #SBATCH -p $PARTITION
# #SBATCH -n $NUM_THREADS
# #SBATCH -C fat
# #SBATCH --mail-user=lecka@liu.se
# #SBATCH --mail-type=ALL

# module load R/4.1.1
# module load R_packages/4.1.1

# ./\$R_SCRIPT \$OUTPUT_DIR \$R_SCRIPT \$SUFFIX \$TIMESTAMP \$NUM_THREADS \$ARGUMENTS 2>&1 | tee \$OUTPUT_DIR/R_console_output/R_output_\$TIMESTAMP.log >> \$OUTPUT_DIR/R_output_cumulative.log
# EOF

echo -n "Job will start in "

for ((i=3; i>0; i--)); do
    echo -n "$i... "
    read -t 1 -n 1 -s -r response
    if [ $? = 0 ]; then
        # If the user presses a key, exit with a message
        echo -e "Operation canceled by the user."
        exit 1
    fi
done

chmod +x "$SBATCH_SCRIPT"
echo -e "\nRunning: $SBATCH_SCRIPT"

# Submit the job to Slurm
export R_SCRIPT
export NUM_THREADS
export OUTPUT_DIR
export TIMESTAMP
export ARGUMENTS

JOB_ID=$(sbatch --parsable "$SBATCH_SCRIPT" || exit 1)
start=$(date +%s)

tput setaf 5
echo -n "Job ID $JOB_ID submitted at $TIMESTAMP. Press 'c' at any time to cancel"
tput sgr 0

read -t 5 -n 1 input
if [[ $input = "c" ]]; then
    # User pressed 'c', cancel the job using scancel
    scancel $JOB_ID
    tput setaf 1
    echo ""
    echo "Operation canceled by the user."
    tput sgr 0
    exit 1
else
    unset input
fi

start=$(date +%s)

# Monitor job status until completion

last_status="init"
phrase_found_count=0

while is_job_active; do
    
    print_job_status # Poll every -t seconds

    read -t 5 -n 1 -s input
    if [[ $input = "c" ]]; then
    # User pressed 'c', cancel the job using scancel
        scancel $JOB_ID
        tput setaf 1
        echo ""
        echo "Operation canceled by the user."
        tput sgr 0
        exit 1
    else
        unset input
    fi
done

# Final job status and statistics
echo ""
echo "Job $JOB_ID has finished. Fetching final statistics..."
echo ""
sacct --format=elapsed,jobname,reqcpus,reqmem,state -j $JOB_ID
end=$(date +%s)
runtime=$((end-start))
runtimeh=$((runtime/3600))
runtimem=$((runtime/60))
echo ""
echo "Runtime was $runtimeh hours ($runtimem minutes)."

# Output result handling

if [[ $? -eq 0 ]]; then
    echo -e "Job ended. Here's the R console output:\n"
    cat "${OUTPUT_DIR}/R_console_output/R_output_${TIMESTAMP}.log" | more
else
    echo "SLURM job failed. Check the error file for details."
    cat $(find ${OUTPUT_DIR}/slurm_reports -maxdepth 1 -type f -printf '%T@ %p\n' | sort -k1,1nr | head -n1 | cut -d' ' -f2-) | more
fi