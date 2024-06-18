#' Set Environment Configuration Interactively
#'
#' Interactively prompts for various configuration settings and writes them to a shell script in the user's home directory.
#' The script, formatted for environment variable export, is intended for shell sourcing.
#' Includes conversion of job time from minutes to D-H:M:S format.
#'
#' @param None Parameters are input interactively.
#'
#' @return No return value; outputs file path and contents to console.
#' @export
#' @examples
#' setConfig() # Run this in an interactive R session
setConfig <- function(force = F) {

    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }

    NUM_THREADS <- readline(prompt = "Enter the number of threads (default 1): ")
    NUM_THREADS <- ifelse(NUM_THREADS == "", "1", NUM_THREADS)

    JOB_TIME_MINUTES <- readline(prompt = "Enter the job time in minutes (default 5): ")
    JOB_TIME_MINUTES <- ifelse(JOB_TIME_MINUTES == "", 5, as.numeric(JOB_TIME_MINUTES))

    hours <- JOB_TIME_MINUTES %/% 60
    days <- hours %/% 24
    hours <- hours %% 24
    minutes <- JOB_TIME_MINUTES %% 60
    JOB_TIME <- sprintf("%d-%02d:%02d:00", days, hours, minutes)

    repeat {
        OUTPUT_DIR <- readline(prompt = "Enter the output directory: ")
        if (OUTPUT_DIR != "" && OUTPUT_DIR != getwd() && !dir.exists(OUTPUT_DIR)) {
            dir.create(OUTPUT_DIR, recursive = TRUE)
            message("Directory created successfully.")
            break
        } else if (OUTPUT_DIR == getwd()) {
            message("\033[31mUsing the current directory is not allowed. Please choose a different directory.\033[0m")
        } else if (dir.exists(OUTPUT_DIR)) {
            message("\033[31mDirectory already exists. Please choose a different directory or enable 'force' option if you want to overwrite.\033[0m")
        } else {
            message("\033[31mInvalid input or directory path. Please try again.\033[0m")
        }
    }

    PARTITION <- readline(prompt = "Enter the partition (default 'devel'): ")
    PARTITION <- ifelse(PARTITION == "", "devel", PARTITION)

    SUFFIX <- readline(prompt = "Enter the suffix for the files (default 'suffix'): ")
    SUFFIX <- ifelse(SUFFIX == "", "suffix", SUFFIX)

    FAT <- "F"

   config_content <- sprintf("export NUM_THREADS='%s'\nexport JOB_TIME='%s'\nexport OUTPUT_DIR='%s'\nexport PARTITION='%s'\nexport SUFFIX='%s'\nexport FAT='%s'",
                              NUM_THREADS, JOB_TIME, OUTPUT_DIR, PARTITION, SUFFIX, FAT)

    config_path <- file.path(OUTPUT_DIR, paste0(".temp_shell_exports_", basename(OUTPUT_DIR)))

    writeLines(config_content, config_path)
    cat("Config file created/updated at:", config_path, "\n")
    cat("Config file content:\n")
    cat(readLines(config_path), sep = "\n")
    
    return(OUTPUT_DIR)

}
