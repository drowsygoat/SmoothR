#!/bin/bash

# Script to setup and submit a SLURM job with custom job settings and user input.

source /cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/SmoothR/inst/shell_helpers/helpers_shell.sh

# User email and compute account settings
COMPUTE_ACCOUNT=${COMPUTE_ACCOUNT}  # Compute account variable

# Capture the current timestamp
# TIMESTAMP=$(TIMESTAMP:-$(date +%Y%m%d_%H%M%S))
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Clear any previous settings for these variables
unset TASKS
unset JOB_TIME
unset PARTITION
unset TASKS
unset CPUS
unset NODES
unset DRY_RUN

# Default values for job settings

NODES="1"
CPUS="1"
TASKS="1" 
PARTITION="shared"
INTERACTIVE=0

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
while getopts "J:n:t:p:N:ic:d:" opt; do
  case ${opt} in
    J )
      JOB_NAME=${OPTARG} 
      ;;
    n )
      TASKS=${OPTARG}  
      ;;
    t )
      JOB_TIME=${OPTARG}  
      ;;
    p )
      PARTITION=${OPTARG}  
      ;;
    N )
      NODES=${OPTARG}  
      ;;
    i )
      INTERACTIVE=1  
      ;;
    c )
      CPUS=${OPTARG}  
      ;;
    d )
      DRY_RUN=${OPTARG}  
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
if [[ $PARTITION =~ (core|node|shared|long|main|memory|devel) ]]; then
    JOB_TIME=${JOB_TIME:-23:59:00}
else 
    JOB_TIME=${JOB_TIME:-00:10:00} 
fi

# Color settings for output using tput
color_key=$(tput setaf 4)   # Blue color for keys
color_value=$(tput setaf 6) # Green color for values
color_reset=$(tput sgr0)    # Reset to default terminal color

# Display settings
echo -e "Here are the current settings:"
echo -e "${color_key}Job name: ${color_value}$JOB_NAME${color_reset}"
echo -e "${color_key}Number of tasks: ${color_value}$TASKS${color_reset}"
echo -e "${color_key}Number of cpus: ${color_value}$CPUS${color_reset}"
echo -e "${color_key}Number of nodes: ${color_value}$NODES${color_reset}"
echo -e "${color_key}Job time: ${color_value}$JOB_TIME${color_reset}"
echo -e "${color_key}Partition: ${color_value}$PARTITION${color_reset}"
echo -e "${color_key}E-mail: ${color_value}$USER_E_MAIL${color_reset}"
echo -e "${color_key}Account: ${color_value}$COMPUTE_ACCOUNT${color_reset}"
echo -e "${color_key}Dry run: ${color_value}$DRY_RUN${color_reset}"

SBATCH_SCRIPT="${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}/${JOB_NAME}_${TIMESTAMP}.sh"

# Create the SLURM job script with the specified parameters
if [[ $DRY_RUN == "dry" ]]; then
  echo -e "This would be run:" 
  echo -e "$ARGUMENTS" 
  exit 0
elif [[ $DRY_RUN == "with_eval" ]]; then
  echo -e "Evaluating:" 
  echo -e "$ARGUMENTS"
  eval "$ARGUMENTS"
  echo -e "Finished."
  exit 0
fi

# Prepare the directory and SLURM script for the job
mkdir -p ${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}

# creating script file
cat <<EOF > "$SBATCH_SCRIPT"
#!/bin/bash -eu
#SBATCH -A ${COMPUTE_ACCOUNT}
#SBATCH -J ${JOB_NAME}
#SBATCH -o ${SLURM_HISTORY}/%x_${TIMESTAMP}/%x_%j_${TIMESTAMP}.out
#SBATCH -t ${JOB_TIME}
#SBATCH -p ${PARTITION}
#SBATCH -n ${TASKS}
#SBATCH -N ${NODES}
#SBATCH -c ${CPUS}
#SBATCH --mail-user=${USER_E_MAIL:-lecka@liu.se}
#SBATCH --mail-type=BEGIN

load_modules() {
    if [ -n "\${MODULES+x}" ]; then
        echo "Loading modules from MODULES variable: \${MODULES}"
        for module in \${MODULES}; do
            echo "Loading module: \$module"
            module load "\$module"
        done
    elif [ -n "\${temp_modules+x}" ]; then
        echo "Used modules from \${temp_modules}"
        cat "\${temp_modules}"
        source "\${temp_modules}"
    fi
}

load_modules

echo "Job \$SLURM_JOB_ID for \$input is running..."

start=\$(date +%s)

eval "\$ARGUMENTS"

echo "Job \$SLURM_JOB_ID for directory \$input is completed."
end=\$(date +%s)
runtime=\$((end-start))
echo "Runtime: \$((runtime/3600)) hours and \$(((runtime%3600)/60)) minutes."

EOF

echo -e "Running:"
tput setaf 5
echo -e "$ARGUMENTS" | tee ${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}/command.log
tput sgr 0


if [[ $INTERACTIVE == 1 ]]; then
  countdown 3
fi

temp_modules=$(get_module_file_path)

export temp_modules
echo "Used modules"

echo -e "Script to run:\n $SBATCH_SCRIPT"
chmod +x "$SBATCH_SCRIPT"

export ARGUMENTS

JOB_ID=$(sbatch --parsable "$SBATCH_SCRIPT" || exit 1)
start=$(date +%s)

if [[ $INTERACTIVE == 1 ]]; then
  interactive_mode
fi

remove_if_empty "${SLURM_HISTORY}/${JOB_NAME}_${TIMESTAMP}"


# echo -e "\033[?1000l"