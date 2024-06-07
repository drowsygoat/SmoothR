#' Activate RunSmoothR.sh by Copying and Adding to $PATH
#'
#' This function copies 'RunSmoothR.sh' to a specified directory and adds the directory
#' to the $PATH variable by updating the appropriate shell configuration file,
#' only if the path is not already present.
#'
#' @param dest_folder The directory to which the script will be copied and added to $PATH.
#' @export
ActivateRunSmoothR <- function(dest_folder) {
    # Copy the script to the desired folder
    CopyRunSmoothRScript(dest_folder)

    # Get the absolute path of the destination folder
    full_path <- normalizePath(dest_folder, mustWork = FALSE)

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
