#' Print Custom Checkpoint Message in SLURM Output
#'
#' Outputs a checkpoint message with a user-defined comment. Useful for tracking progress in non-interactive SLURM tasks.
#' @param comment A character string for the checkpoint comment.
#' @return Prints to the console; returns invisible NULL.
#' @export
#' @examples
#' checkpoint("Data loaded successfully")
#' checkpoint("Model training started")
checkpoint <- function(comment) {
    # if (interactive()) {
    #     return(invisible(NULL))
    # }
    cat(sprintf("CHECKPOINT_%s\n", comment)) # Ensures visibility in logs
}
