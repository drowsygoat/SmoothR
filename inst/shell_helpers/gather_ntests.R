#!/usr/bin/env Rscript

wd <- getwd()

setwd("/cfs/klemming/projects/snic/sllstore2017078/lech")
source("/cfs/klemming/projects/snic/sllstore2017078/lech/renv/activate.R")

setwd(wd)

#!/usr/bin/env Rscript

# Load necessary libraries
library(argparse)
library(dplyr)

# Function to parse command-line arguments using argparse
parse_args <- function() {
  parser <- ArgumentParser(description = "Process eQTL files")
  parser$add_argument("directory", help = "Directory containing the files")
  parser$add_argument("pattern", help = "Pattern to match files")
  parser$add_argument("prefix", help = "Prefix to filter files")
  
  args <- parser$parse_args()
  
  return(args)
}

# Function to gather and process ntests files
gather_ntests <- function(directory, pattern, prefix) {
  # Get list of files matching the pattern "ntests" in the specified directory
  files <- list.files(path = directory, pattern = pattern, full.names = TRUE)
  files <- grep(prefix, files, value = TRUE)

  if (length(files) < 1) {
    stop("No files found to gather.")
  }
  
  # Initialize an empty list to store data frames
  data_list <- list()
  file_counter <- 0
  
  # Loop over the files and read each one
  for (file in files) {
    file_counter <- file_counter + 1
    cat("Processing file", file_counter, ":", file, "\n")
    
    # Read the file
    data <- read.table(file, header = FALSE, sep = " ")
    
    # Append the data frame to the list
    data_list <- append(data_list, list(data))
  }
  
  # Combine all data frames into one
  combined_data <- bind_rows(data_list)

  if (anyNA(combined_data)) {
    warning("NA values were present in the data and were removed") 
  }
  
  # Sum each column
  summed_data <- colSums(combined_data, na.rm = TRUE)
  
  # Create a data frame with the summed data
  result <- data.frame(all = summed_data[1], trans = summed_data[2], cis = summed_data[3])
  
  write.table(result, file = file.path(directory, paste(prefix, "ntests_combined.txt", sep = "_")), quote = FALSE, sep = "\t", row.names = FALSE, col.names = FALSE)
  
  return(result)
}

# Main function to handle arguments and call the gather_ntests function
main <- function() {
  args <- parse_args()
  
  directory <- args$directory
  pattern <- args$pattern
  prefix <- args$prefix

  result <- gather_ntests(directory, pattern, prefix)
  
  print(result)
}

# Call the main function
main()
