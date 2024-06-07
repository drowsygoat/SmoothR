#!/bin/bash

# Description:
# This script is a versatile batch launcher for SLURM jobs, specifically designed for running R scripts.
# It automates the execution of iterative analyses with varying experimental parameters.
# Key Features:
# - Continuous monitoring of SLURM job outputs.
# - Ability to cancel a job within 5 seconds of submission.
# - Automatic detection and notification of "CHECKPOINT" occurrences in the output for streamlined status updates.
# - For longer jobs tmux is good to keep the session alive.

# SLURM Job Parameters:
# NUM_THREADS: Number of threads
# JOB_TIME: Job time (e.g., "2:00:00" for 2 hours)
# OUTPUT_DIR: Output directory to store results
# PARTITION: SLURM partition (e.g., devel, core, shared, memory, long, main)
# SUFFIX: Suffix to append to output files ()
# R_SCRIPT: The R script to run (e.g., my_analysis.R)
# Additional features include timestamp creation, workspace and session data saving.

# Create timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

config_file="$HOME/.temp_shell_exports"

source $config_file

# Set default parameters if unset
NUM_THREADS="${NUM_THREADS:-1}"
JOB_TIME="${JOB_TIME:-"0:05:00"}"
OUTPUT_DIR="${OUTPUT_DIR:-"./output_dir"}"
PARTITION="${PARTITION:-"devel"}"
SUFFIX="${SUFFIX:-"$(date +%Y%m%d_%H%M%S)"}"

# Function to display help if no arguments are provided
function display_help() {
    echo "Usage: $0 R_SCRIPT [ARG1 ARG2 ...]"
    echo
    echo "This script launches SLURM jobs for R scripts with given parameters."
    echo
    echo "Arguments:"
    echo "  R_SCRIPT    The R script to execute."
    echo "  ARG1, ARG2, ... Additional arguments specific to the R analysis."
    echo
    echo "Environment variables used:"
    echo "  NUM_THREADS    Number of threads (default: 1)"
    echo "  JOB_TIME       Job duration (default: 00:05:00)"
    echo "  OUTPUT_DIR     Directory to store results (default: ./output_dir)"
    echo "  PARTITION      SLURM partition (default: devel)"
    echo "  SUFFIX         Timestamp is the default"
    echo
    echo "Example:"
    echo "  ./runSmoothR.sh my_exe.R genome_file.gtf"
    exit 1
}

# Display help
if [ "$#" -lt 1 ]; then
    display_help
fi

# Shift script argument and assign remaining arguments
R_SCRIPT="$1"
shift 1
ARGUMENTS="$@"

# Display current settings
echo -e "Parameters set. Here are the current settings:"
echo -e "Number of threads: $NUM_THREADS"
echo -e "Job time: $JOB_TIME"
echo -e "Output directory: $OUTPUT_DIR"
echo -e "Partition: $PARTITION"
echo -e "Suffix: $SUFFIX"
echo -e "Timestamp: $TIMESTAMP"

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
            echo "$last_keyword_found"
            tput setaf 3 # yellow ;)
            echo "dfghdgfhh"
            tput sgr 0
            echo -n "Monitoring job status for Job ID: $current_status" # single instance below dots    
            current_count=$((current_count + 1))

            fi
        fi
    fi
}
                            # echo "$(echo $last_keyword_found | sed 's/CHECKPOINT_//g')"

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
#SBATCH -A $COMPUTE_ACCOUNT_LECH # update if needed!
#SBATCH -J ${OUTPUT_DIR} # job name
#SBATCH -o ${OUTPUT_DIR}/slurm_reports/%x_%j_${TIMESTAMP}.out # output file
#SBATCH -t $JOB_TIME # job time
#SBATCH -e ${OUTPUT_DIR}/slurm_reports/%x_%j_${TIMESTAMP}.err # error file
#SBATCH -p $PARTITION # partition
#SBATCH -n $NUM_THREADS # number of threads
#SBATCH --mail-user=example@email.com
#SBATCH --mail-type=ALL

# Load R module(s), if not loaded by default

module load R/4.1.1
module load R_packages/4.1.1

# Run the R script and redirect output to a file

./\$R_SCRIPT \$OUTPUT_DIR \$R_SCRIPT \$SUFFIX \$TIMESTAMP \$NUM_THREADS \$ARGUMENTS 2>&1 | tee \$OUTPUT_DIR/R_console_output/R_output_\$TIMESTAMP.log >> \$OUTPUT_DIR/R_output_cumulative.log
EOF

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