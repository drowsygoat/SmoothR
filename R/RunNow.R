#' Submit the Running R Script to Slurm for Execution
#'
#' This function submits the currently running R script to a Slurm-managed cluster.
#' It uses a predefined Slurm script (`runSmoothR.sh`) assumed to be available in the system's PATH.
#' The function automatically retrieves the name of the running script and submits it to Slurm,
#' which makes the script handling secure and error-free. Also, a function (`ActivateSmoothR())` will copy `runSmoothR.sh` to your folder of choice (profided ar argument), and add the route to it to your $PATH variable by updatin "~/.bashrc", or ~/.zshrc

#'
#' @param output_file Optional; specifies the file path where the Slurm job output should be redirected.
#'        If not specified, the output will be displayed in the console.
#' @return The function does not return a value but prints the submission status to the console.
#'         It is designed for interactive use to allow dynamic job control.
#' @export
#' @examples
#' # Submit the currently running script to Slurm, outputting to the console
#' RunNow()
#'
#' # Submit the current script to Slurm, redirecting output to 'job_output.txt'
#' RunNow("job_output.txt")
RunNow <- function(output_file = NULL) {

    args <- commandArgs(trailingOnly = FALSE)
    script_index <- grep("--file=", args, fixed = TRUE)
    if (length(script_index) > 0) {
        script_name <- sub("--file=", "", args[script_index])
    } else {
        stop("The script name could not be auto-detected. Ensure this is run from an R script.")
    }

    slurm_script_name <- "run_loop.sh"  # Assuming the slurm script name is fixed and in PATH

    # Prepare the command
    args <- c(script_name)

    # Prepare output handling
    if (!is.null(output_file)) {
        # Redirect both stdout and stderr to the output file
        stdout <- output_file
        stderr <- output_file
    } else {
        # Default to console output for both stdout and stderr
        stdout <- ""
        stderr <- ""
    }

    cat("Submitting '", script_name, "' to Slurm...\n", sep = "")
    system2(slurm_script_name, args = args, stdout = stdout, stderr = stderr)

}

# Example Usage:
# Correct use: run_slurm()
# Redirect output to a file: run_slurm("output.txt")
