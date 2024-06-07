#' Handle Errors by Printing to Console and Invoking Checkpoint
#'
#' Prints error messages using a checkpoint function and allows continuation of the script despite errors.
#' @param e The error object captured by tryCatch.
#' @keywords internal
handle_error <- function(e) {
    # Use the checkpoint function to print error messages and add any additional context or handling.
    checkpoint(paste("Error occurred:", conditionMessage(e)))
    invisible(NULL)  # Allow continuation without returning an error
}

#' Handle Warnings by Printing and Converting to Errors
#'
#' Handles warnings by logging them through the checkpoint function, then converts them to errors to ensure they are caught.
#' @param w The warning object captured by tryCatch.
#' @keywords internal
handle_warning <- function(w) {
    # Use the checkpoint function to print warning messages.
    checkpoint(paste("Warning occurred:", conditionMessage(w)))
    # Convert warning to error to ensure it is handled by the error handler
    stop(w)
}

#' General Purpose Try-Catch Wrapper
#'
#' Executes code with robust error and warning handling to prevent script termination.
#' The function utilizes a custom checkpoint system to manage and log all issues.
#' @param expr An expression to evaluate.
#' @keywords internal
SafeExecute <- function(expr) {
    tryCatch(eval(expr), error = handle_error, warning = handle_warning)
}
