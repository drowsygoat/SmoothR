
#' Save the current R session for Slurm execution and log session info
#'
#' Saves the current R session into a file, allowing for future continuation in Slurm job executions.
#' Additionally, it saves session information into a text file appended with a timestamp.
#' @param session_file_name String; the filename where the session should be saved.
#' @param timestamp String; a timestamp to append to the session info file, default is current datetime if not provided.
#' @importFrom sessioninfo session_info
#' @examples
#' SaveNow()
#' @export

SaveNow <- function(session_file_name = NULL) {

    requireNamespace("sessioninfo", quietly = TRUE)

    if (interactive()) {
        stop("This function is not available in interactive mode.")
    }

    if (is.null(session_file_name)) {
        args <- commandArgs(trailingOnly = TRUE)
        if (length(args) > 0) {
            session_file_name <- paste0(args[1], "Data")
        } else {
            stop("No session file name detected. Something's rotten in the state od Denmark.")
        }
    }

    tryCatch({
        sink("R_console_output")
        timespam
        print(sessioninfo::session_info())
        sink()
    }, error = function(e) {
        cat("Failed to save session info: ", e$message, "\n")
    })

    tryCatch({
        save.image(file = session_file_name)
        message("Session file '", session_file_name, "' saved successfully.")
    }, error = function(e) {
        stop("Something's rotten in the state od Denmark.: ", e$message)
    })

}
