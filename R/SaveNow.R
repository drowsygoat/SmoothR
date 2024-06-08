
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

        output_dir <- ReadFromConfig("OUTPUT_DIR")

        relative_path <- file.path(".", output_dir)
    
        if (!dir.exists(relative_path)) {
            dir.create(relative_path)
            message(paste("Directory '", normalizePath(relative_path), "' created."))
        } else {
            message(paste("Directory '", normalizePath(relative_path), "' already exists."))
        }
        
        full_path <- file.path(relative_path, paste0(output_dir, ".RData"))
        
        save.image(file = full_path)
        
        return(paste("Session file '", normalizePath(full_path), "' saved successfully."))

    }

    if (is.null(session_file_name)) {
        args <- commandArgs(trailingOnly = TRUE)
        if (length(args) > 0) {
            session_file_name <- paste0(args[1], "Data")
        } else {
            stop("No session file name detected. Something's rotten in the state od Denmark.")
        }
    }

    SafeExecute({
        sink(file.path("R_console_output, paste0(session_info_", timestamp, ".txt"))
        print(sessioninfo::session_info())
        sink()
    })

    SafeExecute({
        save.image(file = session_file_name)
        message("Session file '", session_file_name, "' saved successfully.")
    })

}
