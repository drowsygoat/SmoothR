#' Activate runSmoothR.sh by Copying and Adding to $PATH
#'
#' This function copies 'runSmoothR.sh' to a specified directory and adds the directory
#' to the $PATH variable by updating the appropriate shell configuration file,
#' only if the path is not already present.
#'
#' @param dest_folder The directory to which the script will be copied and added to $PATH.
#' @export
ActivateSmoothR <- function(dest_folder) {
    # Copy the script to the desired folder
    CopyRunSmoothRScript(dest_folder)
    # Get the absolute path of the destination folder
    full_path <- normalizePath(dest_folder, mustWork = TRUE)

    # Prepare the path addition command with the correct path
    path_addition <- sprintf("export PATH=\"$PATH:%s\"", full_path)

    # Determine which shell configuration file to update
    bashrc <- file.path(Sys.getenv("HOME"), ".bashrc")
    bash_profile <- file.path(Sys.getenv("HOME"), ".bash_profile")
    zshrc <- file.path(Sys.getenv("HOME"), ".zshrc")

    # Find an appropriate file to update, preferring .bashrc, then .bash_profile, then .zshrc
    target_file <- ifelse(file.exists(bashrc), bashrc,
                          ifelse(file.exists(bash_profile), bash_profile,
                                 ifelse(file.exists(zshrc), zshrc, "")))

    if (nzchar(target_file)) {
        # Check if the path is already in the PATH variable
        existing_paths <- strsplit(Sys.getenv("PATH"), ":")[[1]]
        if (!(full_path %in% existing_paths)) {
            # Append the path to the configuration file, ensuring to add it on a new line
            writeLines(c("\n", path_addition), target_file, useBytes = TRUE)
            cat("Updated", target_file, "with new PATH\n")
        } else {
            cat("The path is already included in the PATH variable.\n")
        }
    } else {
        stop("No shell configuration file (.bashrc, .bash_profile, or .zshrc) found.")
    }
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