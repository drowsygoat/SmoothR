#' Update the Number of Threads
#'
#' @param NUM_THREADS New number of threads to set.
#' @export
update_num_threads <- function(NUM_THREADS) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    update_config("NUM_THREADS", NUM_THREADS)
}

#' Update Job Time
#'
#' @param JOB_TIME New job time to set.
#' @export
update_job_time <- function(JOB_TIME_MINUTES) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    hours <- JOB_TIME_MINUTES %/% 60
    days <- hours %/% 24
    hours <- hours %% 24
    minutes <- JOB_TIME_MINUTES %% 60
    JOB_TIME <- sprintf("%d-%02d:%02d:00", days, hours, minutes)
    update_config("JOB_TIME", JOB_TIME)
}

#' Update Output Directory
#'
#' @param OUTPUT_DIR New output directory to set.
#' @export
update_output_dir <- function(OUTPUT_DIR) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    update_config("OUTPUT_DIR", OUTPUT_DIR)
}

#' Update Job Partition
#'
#' @param PARTITION New partition to set.
#' @export
update_partition <- function(PARTITION) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    update_config("PARTITION", PARTITION)
}

#' Update File Suffix
#'
#' @param SUFFIX New suffix for the files to set.
#' @export
update_suffix <- function(SUFFIX) {
    if (!interactive()) {
        cat("This function can only be run in an interactive R session.\n")
        return(invisible(NULL))
    }
    update_config("SUFFIX", SUFFIX)
}
