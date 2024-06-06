# RSessionHelper

## Slurm Environment Configurator

This package provides a suite of tools designed to facilitate the configuration and management of computational environments, useful in systems using Slurm for job scheduling. The package allows users to interactively set up and modify environment variables, save configurations for later use, and integrate seamlessly with Slurm job submission processes.

## Installation

To install the latest version of RSessionHelper from GitHub, use the following commands in R:

```r
# Install the devtools package if not already installed
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}

# Install RSessionHelper from GitHub
devtools::install_github("username/YourPackageName")
```

## Main Functions

### `set_config()`
Initializes the environment configuration interactively. This function prompts the user to input settings such as number of threads, job time, output directory, partition, and file suffix. This information is saved to a `.temp_shell_exports` file in the user's home directory.

### `update_config(key, value)`
Updates or adds a specific key-value pair in the environment configuration file. This function is designed to be flexible and can be used to change any specified setting.

### `init_after_slurm()`
A function intended to be called after a job starts in a Slurm environment to perform any necessary initialization tasks.

### `print_checkpoint()`
Outputs a checkpoint message, useful for debugging and tracking the progress of a script that is part of a Slurm job chain.

### `quit_success()`
Ends a script with a success message, signaling that a job part has completed successfully in a multi-part Slurm job setup.

### `save_for_slurm()`
Prepares and saves environment settings specifically configured for subsequent retrieval and use in Slurm job scripts.

## Automated Slurm Submission

### `run_slurm(output_file = NULL)`
Automatically submits the currently running R script to a Slurm-managed cluster. This function is designed to streamline the process of job submission by using a predefined Slurm script (`run_loop.sh`) assumed to be available in the system's PATH. It facilitates the self-submission of scripts, making it particularly useful for workflows that require automated, repeated job submissions.

#### Features:
- **Self-Recognition**: The function detects the name of the R script from which it is called, enabling seamless submission without manual input of the script name.
- **Output Handling**: Optionally redirects the output of the Slurm job to a specified file. If no file is specified, the output will be displayed in the console, allowing for easy monitoring of job progress.
- **Ease of Use**: Designed for interactive use but also robust enough for automated workflows within scripts.

#### Usage:
- To submit the script and view the output in the console:
  ```r
  run_slurm()
  
  ```
## Interactive Update Functions

Each of the following functions updates a specific parameter in the environment configuration file and is designed for interactive use:

### `update_num_threads(NUM_THREADS)`
Sets the number of threads. It ensures that changes reflect immediately in the environment configuration, aiding in computational tasks that rely on parallel processing.

### `update_job_time(JOB_TIME)`
Adjusts the job time. Input should be provided in a "D-H:M" format where D, H, and M stand for days, hours, and minutes, respectively.

### `update_output_dir(OUTPUT_DIR)`
Updates the output directory where results or logs should be stored. This function helps manage the file organization for complex projects.

### `update_partition(PARTITION)`
Changes the partition used for the job. This is crucial for jobs requiring specific computational resources.

### `update_suffix(SUFFIX)`
Modifies the suffix used for naming output files, which can be helpful for versioning and tracking different runs of the same processes.

## Notes for Users

- Some functions are specifically designed for interactive use. Running them in a non-interactive session will result in a notification and no changes being made.
- Ensure that `set_config()` is run at least once before using any `update_` functions to establish initial settings.

## Getting Started

To get started with this package, load it into your R session and begin by setting up your environment with `set_config()`. After initial setup, individual settings can be modified as needed using the update functions.

For more detailed information on each function, refer to the help files included in the package, accessible via `?function_name` in R.
