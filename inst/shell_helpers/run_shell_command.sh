#!/bin/bash

# Script to setup and submit a SLURM job with custom job settings and user input.

function print_job_status() {
    current_status=$(sacct --brief --jobs $JOB_ID | awk -v job_id="$JOB_ID" '$1 == job_id {print $1, $2}')
    if [[ "$last_status" != "$current_status" ]]; then
        echo ""
        echo -n "Monitoring job status for Job ID: $current_status"
        last_status="$current_status"
    else
        echo -n "."
    fi
}

function is_job_active() {
    local active_jobs=$(sacct --jobs $JOB_ID | grep -E "RUNNING|PENDING" | wc -l)
    return $(( active_jobs == 0 ))
}


# Capture the current timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Clear any previous settings for these variables
unset NUM_THREADS
unset JOB_TIME
unset PARTITION

# Default values for job settings
NUM_THREADS="1"  # Default to 1 thread unless specified
PARTITION="devel"  # Default partition is 'devel'
DRY_RUN=0

# Add this at the beginning of your getopts loop
if [ $# -eq 0 ]; then
    echo "No arguments provided. Displaying help:"
    # Call a function to display help
    display_help
    exit 1
fi

# Help 

function display_help() {
    echo "Usage: $0 [options] -- [command]"
    echo "Options:"
    echo "  -J [job_name]       Set the job name. Useful for identifying the job within the system."
    echo "  -n [num_threads]    Define the number of CPU cores the job will utilize."
    echo "  -t [job_time]       Set the job duration, formatted as HH:MM:SS."
    echo "  -p [partition]      Specify the cluster partition for job submission."
    echo "  -h                  Show this help message and exit."
    echo "  -d                  Perform a dry run to validate command parsing without submitting."

    echo ""
    echo "Example of fairly complex command:"
    echo "  $0 -J testJob -n 4 -t 01:00:00 -p main "find . -type f -exec sh -c 'ls -lh \"\$1\" | awk "{print \$5, \$9}" ; md5sum \"\$1\"' sh {} \; | sort -k 3 | uniq -w32 -D > destination.txt""
    echo ""
    echo "Note:"
    echo "  Within quoted segments, escape quotes and special characters using a backslash."
}

# Parse command-line options using getopts
while getopts "J:n:t:p:hd" opt; do
  case ${opt} in
    h )
      display_help
      exit 0
      ;;
    J )
      JOB_NAME=${OPTARG}  # Job name specified with -J option
      ;;
    n )
      NUM_THREADS=${OPTARG}  # Number of threads specified with -n option
      ;;
    t )
      JOB_TIME=${OPTARG}  # Job time duration specified with -t option
      ;;
    p )
      PARTITION=${OPTARG}  # Partition specified with -p option
      ;;
    d)
      DRY_RUN=1  # Dry run mode, no arguments needed
      ;;
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

# Remaining arguments are treated as the command to run
ARGUMENTS="$@"

# Set the job name to the first argument if not explicitly set
JOB_NAME=${JOB_NAME:-$(echo $ARGUMENTS | awk '{print $1}')}

# Set default job time based on the partition
if [[ $PARTITION =~ (core|node|shared|long|main) ]]; then
    JOB_TIME=${JOB_TIME:-03:00:00}  # Longer default time for 'core' or 'node'
else 
    JOB_TIME=${JOB_TIME:-00:10:00}  # Shorter default time for devel
fi

# Print the job parameters for confirmation
echo "Job name: $JOB_NAME"
echo "Threads: $NUM_THREADS"
echo "Time: $JOB_TIME"
echo "Partition: $PARTITION"
echo "Command: $ARGUMENTS"

# User email and compute account settings
USER_E_MAIL='lecka48$liu.se'  # Placeholder email
COMPUTE_ACCOUNT=${COMPUTE_ACCOUNT}  # Compute account variable

# Color settings for output using tput
color_key=$(tput setaf 4)   # Blue color for keys
color_value=$(tput setaf 2) # Green color for values
color_reset=$(tput sgr0)    # Reset to default terminal color

# Display settings
echo -e "Here are the current settings:"
echo -e "${color_key}Job name: ${color_value}$JOB_NAME${color_reset}"
echo -e "${color_key}Number of threads: ${color_value}$NUM_THREADS${color_reset}"
echo -e "${color_key}Job time: ${color_value}$JOB_TIME${color_reset}"
echo -e "${color_key}Partition: ${color_value}$PARTITION${color_reset}"
echo -e "${color_key}Account: ${color_value}$COMPUTE_ACCOUNT${color_reset}"

# Prepare the directory and SLURM script for the job
mkdir -p ${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}
SBATCH_SCRIPT="${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}/${JOB_NAME}_${TIMESTAMP}.sh"

# Create the SLURM job script with the specified parameters
cat <<EOF > "$SBATCH_SCRIPT"
#!/bin/bash -eu
#SBATCH -A ${COMPUTE_ACCOUNT}
#SBATCH -J ${JOB_NAME}
#SBATCH -o ${SLURM_HISTORY}/%x_${TIMESTAMP}/%x_%j_${TIMESTAMP}.out
#SBATCH -t ${JOB_TIME}
#SBATCH -p ${PARTITION}
#SBATCH -n ${NUM_THREADS}
#SBATCH --mail-user=${USER_E_MAIL}
#SBATCH --mail-type=ALL

source ~/.temp_modules  # Source the modules from .temp_modules in the home directory

eval "\$ARGUMENTS"  # Execute the user's command
EOF

if [[ $DRY_RUN -eq 1 ]]; then
    echo "Dry run mode enabled. Command to be executed:"
    echo -e "$ARGUMENTS"
    exit 0
fi

echo -e "Running:"
tput setaf 5
echo -e "$ARGUMENTS" | tee ${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}/command.log
tput sgr 0

echo -n "Job will start in "

# Countdown before starting the job
for ((i=3; i>0; i--)); do
    echo -n "$i... "
    read -t 1 -n 1 -s -r response
    if [ $? = 0 ]; then
        # If the user presses a key, exit with a message
        echo -e "Operation canceled by the user."
        exit 1
    fi
done

echo -e "Script to run:\n $SBATCH_SCRIPT"
chmod +x "$SBATCH_SCRIPT"

export ARGUMENTS

JOB_ID=$(sbatch --parsable "$SBATCH_SCRIPT" || exit 1)
start=$(date +%s)

tput setaf 3
echo -e "Job ID $JOB_ID submitted at $TIMESTAMP.\nPress 'c' at any time to cancel.\nPress 'q' at any time to stop monitoring.\nCancelling will discard the log files."
tput sgr 0

read -t 5 -n 1 input
if [[ $input = "c" ]]; then
    # User pressed 'c', cancel the job using scancel
    scancel $JOB_ID
    rm -rf ${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}
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
while is_job_active; do
    print_job_status # Poll every -t seconds
    read -t 5 -n 1 -s input
    if [[ $input = "c" ]]; then
        # User pressed 'c', cancel the job using scancel
        scancel $JOB_ID
        rm -rf ${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}
        tput setaf 1
        echo ""
        echo "Operation canceled by the user."
        tput sgr 0
        exit 1
    elif [[ $input = "q" ]]; then
        # User pressed 'q', exit with status 0
        tput setaf 1
        echo ""
        echo "Monitoring stopped by the user."
        tput sgr 0
        exit 0
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
echo ""
echo -e "Job completed.\n"