
#' Retrieve the Name of the Currently Running R Script
#'
#' This function extracts the name of the R script that is currently being executed.
#' It is intended for use in scripts where the script needs to be aware of its own filename,
#' particularly useful for logging, dynamic referencing, or script self-submission in batch processing environments.
#'
#' @return A character string containing the filename of the R script being executed,
#'         or NULL if the function cannot determine the script name (e.g., when run interactively).
#' @examples
#' # To see the name of the script in which this function is called:
#' script_name <- get_script_name()
#' print(script_name)
get_script_name <- function() {
    args <- commandArgs(trailingOnly = FALSE)
    script_index <- grep("--file=", args, fixed = TRUE)
    if (length(script_index) > 0) {
        script_name <- sub("--file=", "", args[script_index])
        return(script_name)
    }
    return(NULL)
}
