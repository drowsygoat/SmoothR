#' RunNow Function
#'
#' This function is designed to submit R scripts to a Slurm job scheduler. It reads configuration from
#' a specified shell script in the user's home directory to set environment variables in R, retrieves 
#' the `OUTPUT_DIR` environment variable, and submits the job using a specified Slurm script.
#'
#' @param config_file A string specifying the path to the configuration file that sets required
#'        environment variables. Defaults to "~/.temp_shell_exports".
#' @param output_file A string specifying the path to the file where stdout and stderr from the Slurm
#'        job will be directed. If NULL, outputs will not be redirected. Defaults to NULL.
#' @return The value of the `OUTPUT_DIR` environment variable, indicating the output directory.
#' @examples
#' RunNow()  # Uses default configuration file and no output redirection
#' RunNow(output_file = "path/to/output.log")
#' @export
RunNow <- function(config_file = "~/.temp_shell_exports", output_file = NULL) {
    # Expand the path to the configuration file to get the absolute path
    config_file <- path.expand(config_file)

    # Source the configuration file to set environment variables
    source_config <- paste("source", config_file, "&& env")
    config_env <- system(source_config, intern = TRUE)
    env_vars <- strsplit(config_env, "=")
    env_list <- setNames(as.list(vapply(env_vars, `[`, 2, FUN.VALUE = character(1))), vapply(env_vars, `[`, 1, FUN.VALUE = character(1)))
    list2env(env_list, envir = .GlobalEnv)
    
    # Extract output_dir from environment variables
    output_dir <- Sys.getenv("OUTPUT_DIR", unset = NA)
    if (is.na(output_dir)) {
        stop("OUTPUT_DIR variable is not set in the configuration file.")
    }
    
    # Retrieve script name from command line arguments
    args <- commandArgs(trailingOnly = FALSE)
    script_index <- grep("--file=", args, fixed = TRUE)
    if (length(script_index) > 0) {cd
        script_name <- sub("--file=", "", args[script_index])
    } else {
        stop("The script name could not be auto-detected. Ensure this is run from an R script.")
    }
    slurm_script_name <- "runSmootheR.sh"
    args <- c(script_name)
    if (!is.null(output_file)) {
        stdout <- output_file
        stderr <- output_file
    } else {
        stdout <- ""
        stderr <- ""
    }
    cat("Submitting '", script_name, "' to Slurm with output directory '", output_dir, "'...\n", sep = "")
    system2(slurm_script_name, args = args, stdout = stdout, stderr = stderr)
    
    # Return the output directory for further use
    return(output_dir)
}

