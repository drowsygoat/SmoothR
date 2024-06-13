#' @title Run a R script and submit it to Slurm for execution.
#' @description This function runs a R script and submits it to Slurm for execution.
#' @param script_name The name of the R script to run.
#' @param output_file The name of the output file.
#' @param lint Whether to lint the script instead of running it.
#' @import lintr
#' @return NA
#' @export
RunNow <- function(script_name, output_file = NULL, lint = FALSE) {

  # Validate input arguments
  if (!file.exists(script_name)) {
    stop("Script file not found")
  }
  
  # Lint the script
  if (lint) {
    lint_results <- lintr::lint(script_name)
    if (length(lint_results) > 0) {
      cat("Linting issues found:\n")
      print(lint_results)
      return(invisible(NULL))
    }
  }
  
  # Parse the script
  parse_result <- tryCatch({
    exprs <- parse(file = script_name)
    message("Parsing successful")
    TRUE
  }, error = function(e) {
    message("Error during parsing: ", e$message)
    FALSE
  })
  
  # Check if parsing was successful
  if (!parse_result) {
    stop("Parsing failed")
  }
  
  # Submit the script to Slurm
  slurm_script_name <- file.path(output_dir, "runSmoothR.sh")
  shell_args <- c(script_name)
  cat("Submitting '", slurm_script_name, "' to Slurm...\n")

 if (is.null(output_file)) {
  
  # Running the command without redirecting errors
  tryCatch({
    system2(slurm_script_name, args = shell_args)
    message("Script submitted successfully.")
  }, error = function(e) {
    message("Error submitting script: ", e$message)
  })

} else {

  # Running the command with redirected errors
  tryCatch({
    system2(slurm_script_name, args = shell_args, stderr = output_file, stdin = output_file, input = NULL, wait = FALSE)
    message("Script submitted successfully.")
  }, error = function(e) {
    message("Error submitting script: ", e$message)

    })
  }
}