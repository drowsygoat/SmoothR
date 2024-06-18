#' Safely Evaluate Expressions with Optional Logging
#'
#' Evaluates an expression while handling errors and warnings to prevent unexpected script termination. 
#' If enabled, captures and logs messages, warnings, and errors to a file, facilitating smooth operation 
#' in production or critical scripts requiring uninterrupted execution.
#'
#' @param expr Expression to evaluate, which can range from a single command to a block of code.
#' @param logging Boolean; enables logging of all runtime messages, warnings, and errors when set to TRUE.
#' @param log_file String; specifies the file path for logging, effective only if `logging` is TRUE.
#' @param envir Evaluation environment, defaulting to the parent frame.
#' @return Returns the result of the evaluated expression, or NULL in the event of an error or warning.
#' @export
#' @examples
#' safeExecute({
#'   x <- rnorm(100)
#'   if (mean(x) > 0) "Positive" else "Negative"
#' }, logging = TRUE, log_file = "run_log.txt")
safeExecute <- function(expr, logging = FALSE, log_file = "R_console_log_file.log", envir = parent.frame()) {

    if (interactive()) {
        result <- eval(expr, envir)
        return(result)
    }

    handle_error <- function(e) {
        checkpoint(paste("Error occurred:", conditionMessage(e)))
        invisible(NULL)  # Allow continuation without returning an error
    }

    handle_warning <- function(w) {
        checkpoint(paste("Warning occurred:", conditionMessage(w)))
        invisible(NULL)  # Ensure continuation
    }

    if (isTRUE(logging)) {
        sink(log_file, type = "message")
        on.exit(sink(NULL, type = "message"), add = TRUE)
    }

    result <- tryCatch(eval(expr, envir = envir), error = handle_error, warning = handle_warning)

    return(result)

}