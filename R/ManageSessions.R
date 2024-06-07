#' Initialize Environment After Slurm Execution
#'
#' This function loads an R session file if it exists.
#' It aborts if run in an interactive session. If the specified session file does not exist, the function will continue
#' without loading it, ensuring that the show goes on.
#' @param session_file_name String; the name of the session file to load.
#' Defaults to the first command line argument.
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
            session_file_name <- paste(args[1], ".RData")
            output_dir <- args[1]  # Assuming the first argument is also the output directory
        } else {
            stop("Something is messed up, there were not args detected.")
        }
    }

    # Check if the output directory exists
    if (!dir.exists(output_dir)) {
        stop("Output directory does not exist. Something's rotten in the State of Denmark")
    }

    # Change working directory to the output directory
    setwd(output_dir)
    message("Switched to directory: ", output_dir)

    # Load the session file if it exists
    if (file.exists(session_file_name)) {
        load(session_file_name)
        message("Session file '", session_file_name, "' loaded successfully.")
        checkpoint(paste("Session file '", session_file_name, "' loaded successfully."))
    } else {
        message("Session file '", session_file_name, "' does not exist. Continuing without it.")
        checkpoint(paste("Session file '", session_file_name, "' does not exist. Continuing without it."))
    }
}

#' Quit R when not interactive
#'
#' This function terminates the current R session and exits with status 0, indicating successful completion.
#' It is particularly useful for scripting and batch processing when you want to run the script up to a point (practically equivalent to commenting the remained of the script). Remember to combine with a function SaveNow, as QuitNow does not save anything, just exits!
#'
#' @examples
#' QuitNow()
#' @export

QuitNow <- function() {
    if (interactive()) {
        stop("This function is not available in interactive mode.")
    }
    # Print a message before quitting (optional)
    message("Exiting R session")

    # Quit R session with status 0
    quit(save = "no", status = 0)
}
