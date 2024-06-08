#' Prints a Checkpoint Message with a Custom Comment in SLURM Output
#'
#' This function outputs a formatted checkpoint message that includes a user-defined comment.
#' @param comment A character string representing the comment to be appended to the checkpoint message.
#' @return Prints a formatted checkpoint message to the console; returns invisible NULL.
#' @export
#' @examples
#' checkpoint("Data loaded successfully")
#' checkpoint("Model training started")
checkpoint <- function(comment) {
    if (interactive()) {
        return(invisible(NULL))
    }
    cat(sprintf("CHECKPOINT_%s\n", comment)) # change to sth less common
}
