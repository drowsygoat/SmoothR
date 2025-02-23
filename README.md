**SmoothR: Simplify Your Slurm Environment Configuration for UPPMAX and PDC**

SmoothR is an R package specifically designed to streamline the setup and management of Slurm job environments. It creates a project-specific directory, housing its own SLURM configuration in a separate directory, thus facilitating the easy configuration of environment variables, session management, and integration with the Slurm job submission system. Essentially, SmoothR acts as an organizer for R projects within a remote compute cluster.

Upon using `initSmoothR()`, SmoothR automatically establishes a project-specific directory. This directory is equipped with two essential files: `runSmoothR.sh`, a universal script responsible for the submission of jobs to the Slurm queue, and `.temp_shell_exports_{project_name}`, which holds all environment configurations relevant to the project. This organization ensures that all project settings are centralized and readily accessible.

The `setModules()` function allows users to interactively specify and load required computational modules. These modules may include software packages, libraries, or other tools necessary for the tasks at hand, and are tailored specifically to meet the project’s needs.

Key functions such as `InitNow` and `SaveNow` automate the management of session states. `InitNow` is triggered at the start of each job to load necessary settings from `.temp_shell_exports_{project_name}`, ensuring the environment is correctly configured prior to beginning computations. In contrast, `SaveNow` captures and stores the current state of the project in a `{project_name}.RData` file at any moment, enhancing recovery and continuity between sessions.

`UpdateConfig()` permits modifications or additions to settings without needing to reinitialize the project. The configuration file can also be manually edited if needed.

Moreover, SmoothR includes functionality to track job progression. The `checkpoint()` function marks significant steps in a script’s execution, aiding in identifying potential issues. If necessary, `QuitNow()` can be used to cleanly end a session prematurely.

Jobs can be initiated interactively from within R, or by using the `./runSmoothR.sh my_script.R` command from the shell, providing flexibility in Slurm egagement..

**Installation**

To get started, install SmoothR from GitHub using `devtools`:

```r
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}
devtools::install_github("drowsygoat/SmoothR")
```

```
library(SmoothR)
```

## Functions

# Script Activation

- `initSmoothR()`: Initializes project.

# Environment Configuration

- `setConfig()`: Initializes settings interactively.
- `setModules()`: Initializes Slurm modules interactively.
- `updateConfig(key, value)`: Dynamically updates or adds environment settings.
- `InitNow()`: Executes at job start to load necessary settings.

# Job Management

- `runScript(script_name=my_script.R)`: Submits the current script to Slurm.
- `runScript(script_name=my_script.R, lint = TRUE)`: Lints the current script instead.
- `runExpression(expr)`: Similar to `runScript()`, but for expressions.

# Debugging and Management

- `checkpoint()`: Logs progress points within scripts, aiding in debugging.
- `QuitNow()`: Ends a script segment at a specific point.
- `saveNow()`: Saves current settings for reuse in later Slurm job scripts.

# Configuration Update Functions

- `updateNumThreads(NUM_THREADS)`: Configures thread count for parallel processing.
- `updateJobTime(JOB_TIME)`: Sets job duration in "D-H:M" format.
- `updateOutputDir(OUTPUT_DIR)`: Specifies directory for storing outputs.
- `updatePartition(PARTITION)`: Alters the Slurm partition for job queuing.
- `updateSuffix(SUFFIX)`: Changes suffix for output file naming.
- `setEmail(email)`: Configures E-mail for SLURM notifications (sets variable).
- `setAccount("snic123")`: Configures user account (sets variable).

# Other useful functions

- `los()`: Like `ls()` but but showing objects' sizes and sorting accordingly.

# Optional Error Handling

- Expressions can be wrapped to prevent script termination due to errors.

```R
safeExecute({
  result <- potentiallyFailingFunction()
})


```
![Example](images/screen.png)
```
