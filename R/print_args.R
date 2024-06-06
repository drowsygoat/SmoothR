#' Print Command Line Arguments
#'
#' This function prints all command line arguments provided to the R script
#' when run from the command line. It will not execute in interactive sessions
#' to ensure it is used specifically for command-line operations.
#'
#' @return Prints each command-line argument passed to the script; returns invisible NULL in interactive mode.
#' @export
print_args <- function() {
    if (interactive()) {
        cat("This function is intended for command-line use only.\n")
        return(invisible(NULL))
    }

    args <- commandArgs(trailingOnly = TRUE)

    if (length(args) == 0) {
        cat("No command line arguments were provided.\n")
    } else {
        cat("List of command line arguments:\n")
        for (i in seq_along(args)) {
            cat(sprintf("Arg %d: %s\n", i, args[i]))
        }
    }
}

if (!interactive()) {
    print_args()
}
