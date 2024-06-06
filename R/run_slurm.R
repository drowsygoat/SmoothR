#' Submit the Current R Script to Slurm for Execution
#'
#' This function automatically submits the currently running R script to a Slurm-managed cluster
#' using a predefined Slurm script named 'run_loop.sh'. The function assumes that the Slurm script
#' is available in the system's PATH and is properly configured to accept an R script as a parameter.
#' The function can optionally redirect the output of the Slurm job to a specified file.
#'
#' @param output_file An optional string specifying the file path where the Slurm job output should be redirected.
#'        If not specified, the output will be handled according to the Slurm script's configuration.
#' @return The function does not return a value but prints the submission status to the console.
#'         It is designed for interactive use to allow dynamic job control.
#' @export
#' @examples
#' # Submit the current script to Slurm, outputting to the console
#' run_slurm()
#'
#' # Submit the current script to Slurm, redirecting output to 'job_output.txt'
#' run_slurm("job_output.txt")
run_slurm <- function(output_file = NULL) {
    script_name <- get_script_name()
    if (is.null(script_name)) {
        cat("This function must be run from an R script file, not interactively.\n")
        return(invisible(NULL))
    }

    slurm_script_name <- "run_loop.sh"  # Assuming the slurm script name is fixed and in PATH

    # Prepare the command arguments
    args <- c(script_name)

    # Prepare output handling
    if (!is.null(output_file)) {
        stdout <- output_file
    } else {
        stdout <- ""  # Capturing the output to return or print later
    }

    cat("Submitting '", script_name, "' to Slurm...\n", sep = "")
    output <- system2(slurm_script_name, args = args, stdout = stdout, stderr = TRUE)

    # Optionally print the output if not redirected to a file
    if (is.null(output_file)) {
        cat(output, sep = "\n")
    }
}

# Usage
# run_slurm()
