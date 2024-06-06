#' Initialize Environment After Slurm Execution#'
#'
#' This function loads an R session file if it exists and is specifically tailored for use in a Slurm environment.
#' It aborts if run in an interactive session.
#' @param session_file_name String; the name of the session file to load. Defaults to the first command line argument.
#' @examples
#' load_after_slurm()
#' @export
init_after_slurm <- function(session_file_name = NULL) {
    if (interactive()) {
        stop("This function is not available in interactive mode.")
    }

    if (is.null(session_file_name)) {
        args <- commandArgs(trailingOnly = TRUE)
        if (length(args) > 0) {
            session_file_name <- args[1]
        } else {
            stop("No session file name provided.")
        }
    }

    if (!dir.exists(output_dir)) {
        stop("Output directory does not exist.")
    }

    setwd(output_dir)
    message("Switched to directory: ", output_dir)


    if (file.exists(session_file_name)) {
        load(session_file_name)
        message("Session file '", session_file_name, "' loaded successfully.")
    } else {
        stop("Session file does not exist.")
    }

    setwd(file.path(getwd(), output_dir))

}

#' Save the current R session for Slurm execution and log session info
#'
#' Saves the current R session into a file, allowing for future continuation in Slurm job executions.
#' Additionally, it saves session information into a text file appended with a timestamp.
#' @param session_file_name String; the filename where the session should be saved.
#' @param timestamp String; a timestamp to append to the session info file, default is current datetime if not provided.
#' @importFrom sessioninfo session_info
#' @examples
#' save_for_slurm()
#' @export
save_for_slurm <- function(session_file_name = NULL) {

    requireNamespace("sessioninfo", quietly = TRUE)

    if (interactive()) {
        stop("This function is not available in interactive mode.")
    }

    if (is.null(session_file_name)) {
        args <- commandArgs(trailingOnly = TRUE)
        if (length(args) > 0) {
            session_file_name <- paste0(args[1], "Data")
        } else {
            stop("No session file name provided.")
        }
    }

    tryCatch({
        sink("R_console_output")
        print(sessioninfo::session_info())
        sink()
    }, error = function(e) {
        cat("Failed to save session info: ", e$message, "\n")
    })

    tryCatch({
        save.image(file = session_file_name)
        message("Session file '", session_file_name, "' saved successfully.")
    }, error = function(e) {
        stop("Failed to save the session: ", e$message)
    })

}


#' Print checkpoint messages for Slurm job monitoring
#'
#' This function prints a specified message with a 'CHECKPOINT_' prefix, which is used to signal specific stages
#' or statuses in a Slurm job script. This is particularly useful for logging and monitoring job progress.
#'
#' @param phrase A character string representing the message to be printed.
#' @examples
#' print_checkpoint("data_loaded")
#' @export
print_checkpoint <- function(phrase) {
    if (missing(phrase)) {
        stop("No phrase provided. Please provide a phrase as an argument.")
    }

    # Construct the checkpoint message
    checkpoint_message <- paste("CHECKPOINT_", phrase, sep="")

    # Print the message
    cat(checkpoint_message, "\n")
}

#' Quit R session
#'
#' This function terminates the current R session and exits with status 0, indicating successful completion.
#' It is particularly useful for scripting and batch processing in environments like Slurm.
#'
#' @examples
#' quit_success()
#' @export
quit_success <- function() {
    if (interactive()) {
        stop("This function is not available in interactive mode.")
    }
    # Print a message before quitting (optional)
    message("Exiting R session")

    # Quit R session with status 0
    quit(save = "no", status = 0)
}

#' Set Environment Configuration Interactively
#'
#' This function prompts the user for various configuration settings,
#' converts job time from minutes to a formatted string (D-H:M:S),
#' and writes these settings to a shell script configuration file in the user's home directory.
#' The file is intended to be sourced by a shell to export environment variables.
#'
#' @param None Parameters are gathered interactively.
#'
#' @return No return value; the function writes to a file and prints the file path and contents.
#' @export
#' @examples
#' set_config_interactively() # Run this in an interactive R session
set_config <- function() {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    home_dir <- Sys.getenv("HOME")
    config_path <- file.path(home_dir, ".temp_shell_exports")

    # Prompt user for input and provide default values
    NUM_THREADS <- readline(prompt = "Enter the number of threads (default 1): ")
    NUM_THREADS <- ifelse(NUM_THREADS == "", "1", NUM_THREADS)

    JOB_TIME_MINUTES <- readline(prompt = "Enter the job time in minutes (default 5): ")
    JOB_TIME_MINUTES <- ifelse(JOB_TIME_MINUTES == "", 5, as.numeric(JOB_TIME_MINUTES))

    # Convert minutes to D-H:M:S format
    hours <- JOB_TIME_MINUTES %/% 60
    days <- hours %/% 24
    hours <- hours %% 24
    minutes <- JOB_TIME_MINUTES %% 60
    JOB_TIME <- sprintf("%d-%02d:%02d:00", days, hours, minutes)

    OUTPUT_DIR <- readline(prompt = "Enter the output directory (default current directory): ")
    OUTPUT_DIR <- ifelse(OUTPUT_DIR == "", getwd(), OUTPUT_DIR)

    PARTITION <- readline(prompt = "Enter the partition (default 'devel'): ")
    PARTITION <- ifelse(PARTITION == "", "devel", PARTITION)

    SUFFIX <- readline(prompt = "Enter the suffix for the files (default 'suffix'): ")
    SUFFIX <- ifelse(SUFFIX == "", "suffix", SUFFIX)

    # Construct the content to write to the config file
    config_content <- sprintf("export NUM_THREADS='%s'\nexport JOB_TIME='%s'\nexport OUTPUT_DIR='%s'\nexport PARTITION='%s'\nexport SUFFIX='%s'",
                              NUM_THREADS, JOB_TIME, OUTPUT_DIR, PARTITION, SUFFIX)

    # Write to the config file
    writeLines(config_content, config_path)
    cat("Config file created/updated at:", config_path, "\n")
    cat("Config file content:\n")
    cat(readLines(config_path), sep = "\n")
}

#' Update Configuration Setting
#'
#' This function updates a specific configuration key in the `.temp_shell_exports`
#' file located in the user's home directory. If the key does not exist, it adds the key with the specified value.
#'
#' @param key The configuration key to update (character).
#' @param value The new value for the key (character).
#' @return Invisible NULL; updates the file in-place.
#' @export
#' @examples
#' update_config("NUM_THREADS", "8") # This example updates the number of threads.
update_config <- function(key, value) {
    home_dir <- Sys.getenv("HOME")
    config_path <- file.path(home_dir, ".temp_shell_exports")

    if (!file.exists(config_path)) {
        stop("Config file does not exist. Please run set_config() first.")
    }

    config <- readLines(config_path)
    key_pattern <- sprintf("^%s=", key)
    has_key <- grepl(key_pattern, config)

    if (any(has_key)) {
        config[has_key] <- sprintf('%s="%s"', key, value)
    } else {
        config <- c(config, sprintf('%s="%s"', key, value))
    }

    writeLines(config, config_path)
    cat(sprintf("%s updated in config file:\n", key), readLines(config_path), sep="\n")
    invisible(NULL)
}

