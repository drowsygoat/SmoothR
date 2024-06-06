#' Initialize Environment After Slurm Execution#'
#'
#' This function loads an R session file if it exists and is specifically tailored for use in a Slurm environment.
#' It aborts if run in an interactive session.
#' @param session_file_name String; the name of the session file to load. Defaults to the first command line argument.
#' @examples
#' load_after_slurm()
#' @export
init_after_slurm <- function(session_file_name = NULL) {
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

#' Save Current R Session for Slurm Execution
#'
#' Saves the current R session into a file, allowing for future continuation in Slurm job executions.
#' It aborts if run in an interactive session.
#' @param session_file_name String; the filename where the session should be saved. Defaults to the first command line argument.
#' @examples
#' save_for_slurm()
#' @export
save_for_slurm <- function(session_file_name = NULL) {
    if (interactive()) {
        stop("This function is not available in interactive mode.")
    }

    if (is.null(session_file_name)) {
        args <- commandArgs(trailingOnly = TRUE)
        if (length(args) > 0) {
            session_file_name <- paste0(args[1], "Data")
        } else {
            stop("No session file name provided.")
        }
    }

    tryCatch({
        save.image(file = session_file_name)
        message("Session file '", session_file_name, "' saved successfully.")
    }, error = function(e) {
        stop("Failed to save the session: ", e$message)
    })
}

#' Print checkpoint messages for Slurm job monitoring
#'
#' This function prints a specified message with a 'CHECKPOINT_' prefix, which is used to signal specific stages
#' or statuses in a Slurm job script. This is particularly useful for logging and monitoring job progress.
#'
#' @param phrase A character string representing the message to be printed.
#' @examples
#' print_checkpoint("data_loaded")
#' @export
print_checkpoint <- function(phrase) {
    if (missing(phrase)) {
        stop("No phrase provided. Please provide a phrase as an argument.")
    }

    # Construct the checkpoint message
    checkpoint_message <- paste("CHECKPOINT_", phrase, sep="")

    # Print the message
    cat(checkpoint_message, "\n")
}

#' Quit R session
#'
#' This function terminates the current R session and exits with status 0, indicating successful completion.
#' It is particularly useful for scripting and batch processing in environments like Slurm.
#'
#' @examples
#' quit_success()
#' @export
quit_success <- function() {
    if (interactive()) {
        stop("This function is not available in interactive mode.")
    }
    # Print a message before quitting (optional)
    message("Exiting R session")

    # Quit R session with status 0
    quit(save = "no", status = 0)
}

