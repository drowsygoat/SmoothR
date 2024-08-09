# Function to find a unique file based on a pattern in specified directories
function find_module_file() {
    local file_pattern=$1
    local search_dirs=("$@")
    local file
    local found_files
    local files_array

    for dir in "${search_dirs[@]:1}"; do
        # Search for files matching the pattern in the specified directory, non-recursively
        found_files=$(find "$dir" -maxdepth 1 -type f -regex "$file_pattern")

        # Convert search results to an array
        IFS=$'\n' read -r -d '' -a files_array <<< "$found_files"

        # Check if exactly one unique file is found
        if [ "${#files_array[@]}" -eq 1 ]; then
            file="${files_array[0]}"
            echo "$file"
            return 0
        fi
    done

    # If no unique file is found
    echo "Error: No unique $file_pattern file found or multiple files present in the specified directories."
    return 1
}

# Function to find and output the module file
function get_module_file_path() {
    local file_pattern=".*temp_modules.*"
    local search_dirs=("$PWD" "$HOME")
    local file
    local found_files
    local files_array

    for dir in "${search_dirs[@]}"; do
        # Search for files matching the pattern in the specified directory, non-recursively
        found_files=$(find "$dir" -maxdepth 1 -type f -regex "$file_pattern")

        # Convert search results to an array
        IFS=$'\n' read -r -d '' -a files_array <<< "$found_files"

        # Check if exactly one unique file is found
        if [ "${#files_array[@]}" -eq 1 ]; then
            file="${files_array[0]}"
            echo "$file"
            return 0
        fi
    done

    # If no unique file is found
    echo "Error: No unique $file_pattern file found or multiple files present in the specified directories."
    return 1
}

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

function is_completed() {
    local completed_jobs=$(sacct --jobs $JOB_ID | grep -E "COMPLETED" | wc -l)
    return $(( completed_jobs == 0 ))
}


function interactive_mode() {
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
}


# Function to remove directory if it is empty
function remove_if_empty() {
    local dir=$1

    # Check if directory exists
    if [[ -d "$dir" ]]; then
        # Check if directory is empty
        if [[ -z "$(ls -A "$dir")" ]]; then
            # Remove the directory forcefully
            rmdir "$dir" && echo "Directory '$dir' was empty and has been removed."
        fi
    fi
}

# Function to perform countdown before starting a job
function countdown() {
    local duration=$1

    echo -n "Job will start in "

    # Countdown loop
    for ((i=duration; i>0; i--)); do
        echo -n "$i... "
        read -t 1 -n 1 -s -r response
        if [ $? = 0 ]; then
            # If the user presses a key, exit with a message
            echo -e "\nOperation canceled by the user."
            exit 1
        fi
    done
    echo -e "\nJob is starting now..."
}


# Function to load modules
function load_modules() {
    if [ -n "${MODULES+x}" ]; then
        echo "Loading modules from MODULES variable: ${MODULES}"
        for module in ${MODULES}; do
            echo "Loading module: $module"
            module load "$module"
        done
    elif [ -n "${temp_modules+x}" ]; then
        echo "Used modules from ${temp_modules}"
        cat "${temp_modules}"
        source "${temp_modules}"
    fi
}