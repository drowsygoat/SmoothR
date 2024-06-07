# Update the Number of Threads
#
# @param NUM_THREADS New number of threads to set.
# @export
UpdateNumThreads <- function(NUM_THREADS) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    UpdateConfig("NUM_THREADS", NUM_THREADS)
}

# Update Job Time
#
# @param JOB_TIME New job time to set.
# @export
UpdateJobTime <- function(JOB_TIME_MINUTES) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    hours <- JOB_TIME_MINUTES %/% 60
    days <- hours %/% 24
    hours <- hours %% 24
    minutes <- JOB_TIME_MINUTES %% 60
    JOB_TIME <- sprintf("%d-%02d:%02d:00", days, hours, minutes)
    UpdateConfig("JOB_TIME", JOB_TIME)
}

# Update Output Directory
#
# @param OUTPUT_DIR New output directory to set.
# @export
UpdateOutputDir <- function(OUTPUT_DIR) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    UpdateConfig("OUTPUT_DIR", OUTPUT_DIR)
}

# Update Job Partition
#
# @param PARTITION New partition to set.
# @export
UpdatePartition <- function(PARTITION) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    UpdateConfig("PARTITION", PARTITION)
}

# Update File Suffix
#
# @param SUFFIX New suffix for the files to set.
# @export
UpdateSuffix <- function(SUFFIX) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    UpdateConfig("SUFFIX", SUFFIX)
}

# Convert Timestamp to Human-Readable Format
#
# This internal function takes a timestamp in the format "YYYYMMDD_HHMMSS" and converts it
# to a more human-readable form, "YYYY-MM-DD HH:MM:SS". This function is not exported and is intended
# for internal package use only.
#
# @param timestamp A character string of the timestamp in "YYYYMMDD_HHMMSS" format.
# @return A human-readable datetime string in "YYYY-MM-DD HH:MM:SS" format.
# @examples
# convert_timestamp("20240606_202103")
# @importFrom lubridate ymd_hms
# @noRd
ConvertTimestamp <- function(timestamp) {
    if (!grepl("^\\d{8}_\\d{6}$", timestamp)) {
        stop("Invalid timestamp format. Expected 'YYYYMMDD_HHMMSS'.")
    }

    date_part <- substr(timestamp, 1, 8)
    time_part <- substr(timestamp, 10, 15)
    datetime <- sprintf("%s-%s-%s %s:%s:%s",
                        substr(date_part, 1, 4), substr(date_part, 5, 6), substr(date_part, 7, 8),
                        substr(time_part, 1, 2), substr(time_part, 3, 4), substr(time_part, 5, 6))
    return(lubridate::ymd_hms(datetime))
}

# Set Environment Configuration Interactively
#
# This function prompts the user for various configuration settings,
# converts job time from minutes to a formatted string (D-H:M:S),
# and writes these settings to a shell script configuration file in the user's home directory.
# The file is intended to be sourced by a shell to export environment variables.
#
# @param None Parameters are gathered interactively.
#
# @return No return value; the function writes to a file and prints the file path and contents.
# @export
# @examples
# set_config_interactively() # Run this in an interactive R session


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

SetConfig <- function() {
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

    FAT <- "F"

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
#' UpdateConfig("NUM_THREADS", "8") # This example updates the number of threads.

UpdateConfig <- function(key, value) {
    home_dir <- Sys.getenv("HOME")
    config_path <- file.path(home_dir, ".temp_shell_exports")

    if (!file.exists(config_path)) {
        stop("Config file does not exist. Please run SetConfig() first.")
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

#' Add or Update FAT Configuration
#'
#' This function adds or updates the FAT setting in the configuration file. If no value is provided,
#' it prints the current configuration. If a specific value is provided, it updates or adds the FAT setting
#' with validation to ensure only acceptable values ('T', 'F', 't', 'f') are allowed.
#'
#' @param fat_value Optional value for the FAT setting; default NULL means no update.
#' @export

AddFat <- function(fat_value = NULL) {
    home_dir <- Sys.getenv("HOME")
    config_path <- file.path(home_dir, ".temp_shell_exports")

    # Check if the configuration file exists
    if (!file.exists(config_path)) {
        stop("Config file does not exist. Please run SetConfigInteractively or a similar function first.")
    }

    # Read the existing configuration
    config <- readLines(config_path)

    if (!is.null(fat_value)) {
        # Validate the fat_value input
        stopifnot('Incorrect input; valid values are "T" or "F".' = tolower(fat_value) %in% c("t", "f"))  # Check for valid input

        # Normalize to upper case if valid
        fat_value <- toupper(fat_value)

        # Check if the 'FAT' key exists
        fat_key_pattern <- "^export FAT="
        has_fat_key <- grepl(fat_key_pattern, config)

        # Update or append the 'FAT' configuration
        if (any(has_fat_key)) {
            config[has_fat_key] <- sprintf("export FAT='%s'", fat_value)
        } else {
            config <- c(config, sprintf("export FAT='%s'", fat_value))
        }

        # Write the updated configuration back to the file
        writeLines(config, config_path)
        cat("FAT node selected:\n")
    } else {
        # If no value provided, just print the current configuration
        cat("Please select T or F. Current configuration:\n")
    }

    cat(readLines(config_path), sep="\n")  # Display the updated or current configuration content
    invisible(NULL)
}
