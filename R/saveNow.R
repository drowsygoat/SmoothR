
#' Save the Current R Session
#'
#' This function saves the current R session into a .RData file, enabling the session
#' to be resumed in future Slurm job executions. It also logs session details
#' into a timestamped text file, aiding in reproducibility and debugging.
#' The session file name and timestamp can be specified; if not, defaults are used.
#'
#' @param session_file_name string (optional); the filename for saving the session.
#'        If not provided, the first command line argument will be used with "Data" appended.
#' @param timestamp string (optional); the timestamp to append to the session info file.
#'        Defaults to the current datetime if not provided.
#' @importFrom sessioninfo session_info
#' @examples
#' saveNow()  # Save using default settings
#' @export
saveNow <- function(session_file_name = NULL) {

    requireNamespace("sessioninfo", quietly = TRUE)

    checkDir()

    if (!interactive()) {
        safeExecute({
        print("Hello World")
        [[4]]
        session_info_path <- file.path("R_console_output", paste0("session_info_", args[[4]], ".txt")) # adding timestamp
        print("Hello World")
        sink(session_info_path)
        print(sessioninfo::session_info())
        sink()
        message("Session info logged in '", session_info_path, "'.")
        })
    }

    if (is.null(session_file_name)) {
        output_dir <- ReadFromConfig("OUTPUT_DIR")
        session_file_name <- paste0(output_dir, ".RData")
    }

    safeExecute({
        save.image(file = session_file_name)
        # Correct usage of checkpoint with a single string argument
        checkpoint(sprintf("Session file '%s' saved successfully.", session_file_name))
        message(sprintf("Session file '%s' saved successfully.", session_file_name))
    })
}