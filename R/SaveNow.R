
#' Save the Current R Session for Slurm Execution and Log Session Information
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
#' SaveNow()  # Save using default settings
#' @export
SaveNow <- function(session_file_name = NULL, timestamp = format(Sys.time(), "%Y%m%d-%H%M%S")) {
    requireNamespace("sessioninfo", quietly = TRUE)

    if (interactive()) {
        output_dir <- ReadFromConfig("OUTPUT_DIR")
        checkDir(output_dir)

        full_path <- file.path(output_dir, paste0("session_", timestamp, ".RData"))

        suppressWarnings(try(rm(list = c("args"), envir = .GlobalEnv), silent = TRUE))

        SafeExecute({
            save.image(file = full_path)
            return(paste("Session file '", normalizePath(full_path), "' saved successfully."))
        })
    }
    
    args <- commandArgs(trailingOnly = TRUE)
    if (is.null(session_file_name)) {
        if (length(args) > 0) {
            session_file_name <- paste0(args[1], "Data")
        } else {
            stop("No session file name detected. Please provide a filename.")
        }
    }
    
    if (length(args) > 1) {
        assign("script_name", args[2], envir = .GlobalEnv)
    }

    suppressWarnings(try(rm(list = c("args"), envir = .GlobalEnv), silent = TRUE))
    
    SafeExecute({
        session_info_path <- file.path("R_console_output", paste0("session_info_", timestamp, ".txt"))
        sink(session_info_path)
        print(sessioninfo::session_info())
        sink()
        message("Session info logged in '", session_info_path, "'.")
    })

    SafeExecute({
        save.image(file = session_file_name)
        message("Session file '", session_file_name, "' saved successfully.")
    })
}