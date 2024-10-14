#' @title Run an R expression and submit it to Slurm for execution.
#' @description This function runs an R expression and submits it to Slurm for execution.
#' @param r_expression The R expression to run.
#' @return NA
#' @export
runExpression <- function(r_expression, save = FALSE) {
  
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

  # Set the system environment variable to indicate the operation mode
  
  if (isTRUE(save)) {
      full_command <- sprintf("args <- InitNow(); %s; SaveNow()", r_expression)
  } else {
      full_command <- sprintf("args <- InitNow(); %s", r_expression)
  }

  # Prepare the command to run the expression using R
  slurm_script_name <- "runSmoothR.sh"  # Unchanged Slurm script name
  command <- sprintf("R -e '%s'", full_command)

  # Submit the command to Slurm without redirecting outputs
  tryCatch({
    system2(slurm_script_name, args = command, wait = FALSE)
    message("Expression submitted successfully.")
  }, error = function(e) {
    message("Error submitting expression: ", e$message)
  })
}