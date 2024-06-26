#' Update or Create Module Configuration
#'
#' Updates or creates a module configuration file in a specified directory, overwriting the existing file if allowed. The function is designed for interactive R sessions only and prints the file path and content to the console.
#'
#' @param modules A character vector of module names to be loaded (default is c("R/4.1.1", "R_packages/4.1.1")).
#' @param force Logical; if TRUE, forcefully overwrite the existing module file if it exists (default is TRUE).
#' 
#' @return No return value; outputs file path and contents to console.
#' @export
#' @examples
#' setModules() # Default usage
#' setModules(modules = c("Python/3.8.5", "Java/1.8"), force = FALSE)
setModules <- function(modules = c("R/4.1.1", "R_packages/4.1.1"), force = TRUE) {

    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }

    output_dir <- ReadFromConfig("OUTPUT_DIR")
    module_file <- paste0(".temp_modules_", basename(output_dir))

    if (basename(getwd()) != output_dir) {
        stop("Run initSmoother() first to create a project or navigate to the existing project's directory")
    }

    if (file.exists(module_file)) {
        if (isTRUE(force)) {
            message("Module file exists but overwriting since 'force = TRUE'.")
        } else {
            stop("Module file exists. Stopping as 'force = FALSE'.")
        }
    }

    if (is.null(modules)) {
        writeLines("\n", module_file)
        cat("Module file created with no modules.")
    } else {
        writeLines(sprintf(rep("module load %s", length(modules)), modules), module_file)
        cat("Module file created/updated at:", module_file, "\n")
        cat("Module file content:\n")
        cat(readLines(module_file), sep = "\n")
    }
}