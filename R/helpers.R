#' Update the Number of Threads
#'
#' @param NUM_THREADS New number of threads to set.
#' @export
updateNumThreads <- function(NUM_THREADS) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    updateConfig("NUM_THREADS", NUM_THREADS)
}

#' Update Job Time
#'
#' @param JOB_TIME_MINUTES New job time to set in minutes.
#' @export
updateJobTime <- function(JOB_TIME_MINUTES) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    hours <- JOB_TIME_MINUTES %/% 60
    days <- hours %/% 24
    hours <- hours %% 24
    minutes <- JOB_TIME_MINUTES %% 60
    JOB_TIME <- sprintf("%d-%02d:%02d:00", days, hours, minutes)
    updateConfig("JOB_TIME", JOB_TIME)
}

#' Update Output Directory
#'
#' @param OUTPUT_DIR New output directory to set.
#' @export
updateOutputDir <- function(OUTPUT_DIR) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    updateConfig("OUTPUT_DIR", OUTPUT_DIR)
}

#' Update Job Partition
#'
#' @param PARTITION New partition to set.
#' @export
updatePartition <- function(PARTITION) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    updateConfig("PARTITION", PARTITION)
}

#' Update File Suffix
#'
#' @param SUFFIX New suffix for the files to set.
#' @export
updateSuffix <- function(SUFFIX) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    updateConfig("SUFFIX", SUFFIX)
}

#' Convert Timestamp to Human-Readable Format
#'
#' This internal function takes a timestamp in the format "YYYYMMDD_HHMMSS" and converts it
#' to a more human-readable form, "YYYY-MM-DD HH:MM:SS". This function is not exported and is intended
#' for internal package use only.
#'
#' @param timestamp A character string of the timestamp in "YYYYMMDD_HHMMSS" format.
#' @return A human-readable datetime string in "YYYY-MM-DD HH:MM:SS" format.
#' @examples
#' convert_timestamp("20240606_202103")
#' @importFrom lubridate ymd_hms
#' @noRd
convertTimestamp <- function(timestamp) {

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

#' Update Configuration Setting
#'
#' This function updates a specific configuration key in the `.temp_shell_exports`
#' file located in the user's home directory. If the key does not exist, it adds the key with the specified value.
#'
#' @param key The configuration key to update.
#' @param value The new value for the key.
#' @return Invisible NULL; updates are made in-place.
#' @export
#' @examples
#' updateConfig("NUM_THREADS", "8")
updateConfig <- function(key, value) {

    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }

    config_file <- list.files(path = ".", pattern = "temp_shell_exports", all.files = TRUE, full.names = TRUE)

    if (!file.exists(config_file) | length(config_file) > 1) {
        stop("Configuration file issue: Either does not exist or multiple files found.")
    }

    # Ensure the configuration file exists
    if (!file.exists(config_file)) {
        stop("Config file does not exist. Please run SetConfig() or InitSmoothR() first or navigate to the project directory.")
    }

    config <- readLines(config_file)
    key_pattern <- sprintf("^export %s=", key)
    has_key <- grepl(key_pattern, config)

    if (any(has_key)) {
        config[has_key] <- sprintf('export %s="%s"', key, value)
    } else {
        config <- c(config, sprintf('export %s="%s"', key, value))
    }

    writeLines(config, config_path)
    cat(sprintf("%s updated in config file:\n", key), readLines(config_path), sep="\n")
    invisible(NULL)
}

#' Add or Update FAT Configuration
#'
#' Adds or updates the FAT setting in the configuration file. It validates and accepts
#' only 'T', 'F', 't', 'f' as values. If no value is provided, the current configuration is printed.
#'
#' @param fat_value Optional character indicating the FAT setting ('T', 'F', 't', 'f'); default NULL.
#' @export
addFat <- function(fat_value = NULL) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
        
    config_file <- list.files(path = ".", pattern = "temp_shell_exports", all.files = TRUE, full.names = TRUE)

    if (!file.exists(config_file) | length(config_file) > 1) {
        stop("Configuration file issue: Either does not exist or multiple files found.")
    }

    config <- readLines(config_file)

    if (!is.null(fat_value)) {
        if (tolower(fat_value) %in% c("t", "f")) {
            fat_value <- toupper(fat_value)
            fat_key_pattern <- "^export FAT="
            has_fat_key <- grepl(fat_key_pattern, config)

            if (any(has_fat_key)) {
                config[has_fat_key] <- sprintf("export FAT='%s'", fat_value)
            } else {
                config <- c(config, sprintf("export FAT='%s'", fat_value))
            }

            writeLines(config, config_file)
            cat("FAT configuration updated:\n")
        } else {
            stop('Incorrect input; valid values are "T" or "F".')
        }
    } else {
        cat("Current configuration:\n")
    }
    
    cat(readLines(config_file), sep="\n")
    invisible(NULL)
}

#' Read Configuration Values from a File
#'
#' Retrieves a specific configuration value by key from a file formatted as `export KEY='VALUE'`.
#' Throws an error if the key is not found or if the file does not exist.
#'
#' @param key_to_check The configuration key to retrieve.
#' @param config_file Path to the configuration file, defaults to '~/.temp_shell_exports'.
#' @return The value associated with the provided key.
#' @export
ReadFromConfig <- function(key_to_check) {
    
    # if (!interactive()) {
    #     return(invisible(NULL))
    # }
    
    config_file <- list.files(path = ".", pattern = "temp_shell_exports", all.files = TRUE, full.names = TRUE)

    if (!file.exists(config_file) | length(config_file) > 1) {
        stop("Configuration file issue: Either does not exist or multiple files found.")
    }

    config_lines <- readLines(config_file)
    config_values <- list()
    
    matches <- which(grepl("^export\\s+\\w+='[^']*'$", config_lines))
    
    for (index in matches) {
        line <- config_lines[index]
        key_value <- sub("^export\\s+(\\w+)='([^']*)'$", "\\1 \\2", line)
        parts <- strsplit(key_value, " ")[[1]]
        config_values[[parts[1]]] <- parts[2]
    }
    
    if (is.null(key_to_check)) {
        stop("Please provide a key.")
    }

    if (!key_to_check %in% names(config_values)) {
        stop("Key not found.")
    }

    return(config_values[[key_to_check]])

}


#' Check and Adjust Working Directory Based on Configuration
#'
#' Verifies the presence of required temp files in the current directory and ensures
#' the output directory matches the expected configuration. Adjusts the working
#' directory if necessary, based on the configuration.
#'
#' @return None; function is used for its side effects (changing directories or stopping execution).

checkDir <- function() {

  # Check for specific temp files
  temp_files <- list.files(path = ".", pattern = "^\\.temp", all.files = TRUE)

  if (length(temp_files) == 0) {
    stop("No temp files found. Please check your directory.")
  }
  
  if (!any(grepl("^\\.temp_modules", temp_files)) ||
      !any(grepl("^\\.temp_shell_exports", temp_files))) {
    stop("Required temp files missing.")
  }
  
  # Read expected output directory from configuration
  output_dir <- ReadFromConfig("OUTPUT_DIR")
  
  # Validate the output directory
  if (!dir.exists(output_dir)) {
    if (basename(getwd()) != output_dir) {
      stop("Directory mismatch. The output directory does not match the current working directory basename. Correct output directory not found.")
    } else {
      message("Current directory is already set to the output directory.")
    }
  } else {
    setwd(output_dir)
    message("Changed working directory to: ", output_dir)
  }
}

#' Set USER_E_MAIL Environment Variable
#'
#' Sets the USER_E_MAIL environment variable to the specified email and displays it.
#' @param email Email address to set as USER_E_MAIL.
#' @examples
#' setEmail("user@example.com")
#' @export
setEmail <- function(email) {
    Sys.setenv(USER_E_MAIL = email)
    message("The USER_E_MAIL has been set to: ", Sys.getenv("USER_E_MAIL"))
}

#' Set COMPUTE_ACCOUNT Environment Variable
#'
#' Sets the COMPUTE_ACCOUNT environment variable to the specified account name and displays it.
#' @param accountName Account name to set as COMPUTE_ACCOUNT.
#' @examples
#' setAccount("snic123456")
#' @export
setAccount <- function(accountName) {
    Sys.setenv(COMPUTE_ACCOUNT = accountName)
    message("The COMPUTE_ACCOUNT has been set to: ", Sys.getenv("COMPUTE_ACCOUNT"))
}