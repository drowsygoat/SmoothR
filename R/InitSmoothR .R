#' Activate runSmoothR.sh by Copying and Adding to $PATH
#'
#' This function copies 'runSmoothR.sh' to a specified directory and adds the directory
#' to the $PATH variable by updating the appropriate shell configuration file,
#' only if the path is not already present.
#'
#' @export
InitSmoothR <- function() {

    if ( ! interactive() ) {
        return(invisible(NULL))
    }

    output_dir <- SetConfig()

    CopyRunSmoothRScript(output_dir)
    
}

#' Copy runSmoothR.sh Script to a Specified Directory
#'
#' This function copies the 'runSmoothR.sh' script from the 'shell_helpers' folder
#' of the package to a specified folder.
#'
#' @param dest_folder The destination folder where the script will be copied.
CopyRunSmoothRScript <- function(dest_folder) {

  package_directory <- system.file("shell_helpers", package = "SmoothR")
  script_path <- file.path(package_directory, "runSmoothR.sh")
  
  if (!file.exists(script_path)) {
    stop("Script 'runSmoothR.sh' does not exist in the package.")
  }
  
  file.copy(script_path, file.path(dest_folder, "runSmoothR.sh"))
  cat("Script copied to:", dest_folder, "\n")

}