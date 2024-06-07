#' Initialize Environment After Slurm Execution#'
#'
#' This function loads an R session file if it exists and is specifically tailored for use in a Slurm environment.
#' It aborts if run in an interactive session.
#' @param session_file_name String; the name of the session file to load. Defaults to the first command line argument.
#' @examples
#' InitNow()
#' @export
InitNow <- function(session_file_name = NULL) {
    if (interactive()) {
        stop("This function is not available in interactive mode.")
    }

    if (is.null(session_file_name)) {
        args <- commandArgs(trailingOnly = TRUE)
        if (length(args) > 0) {
            session_file_name <- args[1]
        } else {
            stop("No session file name provided.")
        }
    }

    if (!dir.exists(output_dir)) {
        stop("Output directory does not exist.")
    }

    setwd(output_dir)
    message("Switched to directory: ", output_dir)


    if (file.exists(session_file_name)) {
        load(session_file_name)
        message("Session file '", session_file_name, "' loaded successfully.")
    } else {
        stop("Session file does not exist.")
    }

    setwd(file.path(getwd(), output_dir))

}

#' Quit R when not interactive
#'
#' This function terminates the current R session and exits with status 0, indicating successful completion.
#' It is particularly useful for scripting and batch processing in environments like Slurm.
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
