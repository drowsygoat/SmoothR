#' Prints a Checkpoint Message with a Custom Comment in SLURM Output
#'
#' This function outputs a formatted checkpoint message that includes a user-defined comment.
#' It is designed to assist in logging and monitoring script progress, especially when run
#' as part of automated processes where specific checkpoints need to be recorded and tracked.
#'
#' @param comment A character string representing the comment to be appended to the checkpoint message.
#' @return Prints a formatted checkpoint message to the console; returns invisible NULL.
#' @export
#' @examples
#' checkpoint("Data loaded successfully")
#' checkpoint("Model training started")
checkpoint <- function(comment) {
    cat(sprintf("CHECKPOINT_%s\n", comment))
}

get_script_name <- function() {
    args <- commandArgs(trailingOnly = FALSE)
    script_index <- grep("--file=", args, fixed = TRUE)
    if (length(script_index) > 0) {
        script_name <- sub("--file=", "", args[script_index])
        return(script_name)
    }
    return(NULL)
}
