#' Initialize Session After Slurm Execution
#'
#' Loads a specified R session file. Aborts if run interactively or if the session file does not exist.
#' Continues without loading if the file is missing.
#'
#' @param session_file_name The name of the session file to load, defaults to the first command line argument with ".RData" appended.
#' @examples
#' InitNow()
#' @export
InitNow <- function(session_file_name = NULL) {
    
    if (interactive()) {
        stop("This function is not available in interactive mode.")
    }

    # Fetch command line arguments if no session file name is provided
    if (is.null(session_file_name)) {
        args <- commandArgs(trailingOnly = TRUE)
        if (length(args) > 0) {
            session_file_name <- file.path(output_dir, paste0(args[1], ".RData"))
            output_dir <- args[1]  # Assuming the first argument is also the output directory
        } else {
            stop("No command line arguments detected.")
        }
    }

    # Check if the output directory exists
    if (!dir.exists(output_dir)) {
        stop("Output directory does not exist.")
    }

    # checkDir()

    # Load the session file if it exists
    if (file.exists(session_file_name)) {

        load(session_file_name, envir = .GlobalEnv)
        message("Session file '", session_file_name, "' loaded successfully.")
        checkpoint(paste("Session file '", session_file_name, "' loaded successfully."))

    } else {

        message("Session file '", session_file_name, "' does not exist. Continuing without it.")
        checkpoint(paste("Session file '", session_file_name, "' does not exist. Continuing without it."))
        
    }
}


#' Quit R Session when not Interactive
#'
#' Terminates the current R session non-interactively with a success status. Useful in scripts and batch processing.
#' Does not save the session before exiting. Pair with SaveNow() to save data first.
#'
#' @examples
#' QuitNow()
#' @export
QuitNow <- function() {
    if (interactive()) {
        stop("This function is not available in interactive mode.")
    }
    message("Exiting R session")
    quit(save = "no", status = 0)
}
