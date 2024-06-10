#' RunNow Function
#'
#' This function is designed to submit R scripts to a Slurm job scheduler. It initializes the environment
#' by reading configurations from a shell script located in the user's home directory. The function retrieves
#' the `OUTPUT_DIR` environment variable, and submits the job using a designated Slurm script. The `script_name`
#' variable is defined here and logged for subsequent analysis. If `script_name` is not redefined during execution,
#' its initial value is used.
#'
#' Instead of using this function, one might find it convenient to use a multiplexed terminal for live
#' reporting. This can be achieved by running:
#' ./runSmoothR.sh script_name.R [optional args, which will start from position 6 in args]
#'
#' Note: The optional arguments are available starting from the sixth position in `args`.
#'
#' @param config_file A string specifying the path to the configuration file for setting required
#'        environment variables. Defaults to "~/.temp_shell_exports".
#' @param output_file A string specifying the path to the file where stdout and stderr from the Slurm
#'        job will be directed. If NULL, outputs will not be redirected. Defaults to NULL.
#' @return The value of the `OUTPUT_DIR` environment variable, which indicates the output directory.
#' @examples
#' RunNow()  # Uses default configuration file and no output redirection
#' RunNow(output_file = "path/to/output.log")
#' @export
RunNow <- function(script_name = NULL, verbose = TRUE) {
    
    if (!interactive()) {
        return(invisible(NULL))
    }
    
    if (!is.null(script_name)) {
        script_name <- normalizePath(script_name)
    }
    current_dir <- getwd()
    
    output_dir <- ReadFromConfig("OUTPUT_DIR")
    checkDir(output_dir)
    
    config_file <- list.files(path = output_dir, pattern = "temp_shell_exports", all.files = TRUE, full.names = TRUE)[1]

    if (!file.exists(config_file)) {
        stop("Config file does not exist. Please run InitSmoothR() first.")
    }

    slurm_script_name <- file.path(".", output_dir, "runSmoothR.sh")
    shell_args <- c(script_name)

    if (!isTRUE(verbose)) {
        output_file <- "SmoothR.log"
        stdout <- output_file
        stderr <- output_file
    } else {
        stdout <- ""
        stderr <- ""
    }

    cat("Submitting '", slurm_script_name, "' to Slurm with output directory '", output_dir, "'...\n", sep = "")
    system2(slurm_script_name, args = paste0(shell_args), stdout = stdout, stderr = stderr)
    
    # Return the output directory for further use
    # assign("output_dir", normalizePath(output_dir), envir = .GlobalEnv)
    setwd(current_dir)
}
