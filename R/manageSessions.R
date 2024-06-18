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
    
    output_dir <- ReadFromConfig("OUTPUT_DIR")

    if (is.null(session_file_name)) {
        session_file_name <- paste0(output_dir, ".RData")
    }

    # Ensure output directory exists
    if (basename(getwd()) != output_dir) {
        stop("Wrong dir. Please first navigate the:", output_dir)
    }

    # Load the session file if it exists
    if (file.exists(session_file_name)) {
        load(session_file_name, envir = .GlobalEnv)
        message("Session file '", session_file_name, "' loaded successfully.")
        checkpoint(paste("Session file '", session_file_name, "' loaded successfully."))
    } else {
        message("Session file '", session_file_name, "' does not exist. Continuing without it.")
        checkpoint(paste("Session file '", session_file_name, "' does not exist. Continuing without it."))
    }

    args <- commandArgs(trailingOnly = TRUE)
    
    if (length(args) < 5) {
        stop("Args missing!")
    }
    
    cat("List of command line arguments:\n")
    for (i in seq_along(args)) {
        cat(sprintf("Arg %d: %s\n", i, args[i]))
    }

    list(
        output_dir = args[1],
        script_name = args[2],
        suffix = args[3],
        timestamp = args[4],
        threads = as.integer(args[5])
    )
}


#' Quit R Session when not Interactive
#'
#' Terminates the current R session non-interactively with a success status. Useful in scripts and batch processing.
#' Does not save the session before exiting. Precede with SaveNow() to save data first.
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
