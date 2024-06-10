# SmoothR: Slurm Environment Configurator

`SmoothR` provides a comprehensive suite of tools for managing and configuring SLURM job environments directly from R. It offers functionalities to set up environment variables, manage session states, and seamlessly interact with the Slurm job submission system.

## Installation

Install `SmoothR` directly from GitHub using `devtools`:

```r
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}
devtools::install_github("drowsygoat/SmoothR")
```

## Quick Start

Load `SmoothR` and set up your environment interactively:

```r
library(SmoothR)
set_config()  # Interactive environment setup
```

## Key Features

### Script Activation

`ActivateRunSmoothR()` prepares your system to use `runSmoothR.sh`:

```r
ActivateRunSmoothR("/path/to/file")
```

- **Copies** `RunSmoothR.sh` to your specified directory.
- **Updates** `$PATH` to include the script's directory.
- **Configures** the shell by updating `.bashrc`, `.bash_profile`, or `.zshrc`.

### Environment Configuration

- **`SetConfig()`**: Initializes settings interactively and saves them for Slurm jobs.
- **`UpdateConfig(key, value)`**: Dynamically updates or adds environment settings.
- **`InitNow()`**: Executes at job start to load necessary settings.

### Job Management

- **`run_slurm()`**: Submits R scripts to a Slurm-managed cluster for execution.

```r
run_slurm()  # Submits the current script to Slurm
```

### Debugging and Management

- **`checkpoint()`**: Logs progress points within scripts, aiding in debugging.
- **`QuitNow()`**: Ends a script segment positively, signaling completion.
- **`SaveMe()`**: Saves current settings for reuse in later Slurm job scripts.

### Interactive Update Functions

Modify specific settings interactively:

- **`UpdateNumThreads(NUM_THREADS)`**: Configures thread count for parallel processing.
- **`UpdateJobTime(JOB_TIME)`**: Sets job duration in "D-H:M" format.
- **`UpdateOutputDir(OUTPUT_DIR)`**: Specifies directory for storing outputs.
- **`UpdatePartition(PARTITION)`**: Alters the Slurm partition for job queuing.
- **`UpdateSuffix(SUFFIX)`**: Changes suffix for output file naming.
- **`setEmail(email)`**: Configures `USER_E_MAIL` for SLURM notifications.
- **`setAccount("snic123")`**: Configures `USER_E_MAIL` for SLURM notifications.
  
### Robust Error Handling

Prevent interruptions with `SafeExecute`, ensuring smooth execution even when errors occur. You can wrap big chunks of code as well (but it's safer to use it multiple times instead.)

```r
SafeExecute({
  result <- potentiallyFailingFunction()
})
```

## Support

For more detailed documentation on each function and additional configuration tips, refer to the function help pages and manual.
