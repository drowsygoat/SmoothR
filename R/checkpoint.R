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
    cat(sprintf("CHECKPOINT_%s\n", comment)) # change to sth less common
}
