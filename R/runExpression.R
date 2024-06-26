#' @title Run an R expression and submit it to Slurm for execution.
#' @description This function runs an R expression and submits it to Slurm for execution.
#' @param r_expression The R expression to run.
#' @return NA
#' @export
runExpression <- function(r_expression, save = FALSE) {
  
  # Attempt to parse the R expression to ensure it's syntactically correct
  parse_result <- tryCatch({
    parse(text = r_expression)
    TRUE  # Parsing successful
  }, error = function(e) {
    message("Error during parsing: ", e$message)
    FALSE  # Parsing failed
  })

  # Check if parsing was successful
  if (!parse_result) {
    stop("Parsing failed, expression will not be submitted.")
  }

  # Create the command based on the 'save' condition
  if (isTRUE(save)) {
      full_command <- sprintf("args <- InitNow(); %s; SaveNow()", r_expression)
  } else {
      full_command <- sprintf("args <- InitNow(); %s", r_expression)
  }

  # Prepare the full script content
  script_content <- sprintf("#!/usr/bin/env Rscript\n%s", full_command)

  # Save the script to a temporary file
  script_file <- tempfile(pattern = "R_script_", fileext = ".R")
  writeLines(script_content, script_file)
  
  # Make the script executable
  Sys.chmod(script_file, mode = "0755")

  # Prepare the command to run the expression using R
  slurm_script_name <- "./runSmoothR.sh"

  # Submit the command to Slurm with the path to the script file
  tryCatch({
    # Script file is passed as the first argument to the script
    system2(slurm_script_name, args = script_file, wait = FALSE)
    message("Expression submitted successfully.")
  }, error = function(e) {
    message("Error submitting expression: ", e$message)
  })
}
