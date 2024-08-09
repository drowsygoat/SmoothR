#!/usr/bin/env Rscript

.libPaths()

wd <- getwd()
setwd("/cfs/klemming/projects/snic/sllstore2017078/lech")
source("renv/activate.R")
setwd(wd)

.libPaths()

# Load necessary libraries
library(argparse)
library(MatrixEQTL)
library(SmoothR)
library(parallel)
library(R.utils)

# Define command-line arguments
parser <- ArgumentParser(description = 'Process QTL analysis arguments')
parser$add_argument("group_name", help = "Name of the group")
parser$add_argument("snpFilePath", help = "Path to the SNP file")
parser$add_argument("snpLocPath", help = "Path to the SNP location file")
parser$add_argument("feature_data_path", help = "Path to the feature data file")
parser$add_argument("feature_locations_path", help = "Path to the feature locations file")
parser$add_argument("covFilePath", help = "Path to the covariates file")
parser$add_argument("--threads", type = "integer", default = 10, help = "Number of threads to use (default: 10)")

# Parse command-line arguments
args <- parser$parse_args()

print("-----")
print(args)
print("-----")

options("warn")

# Extract arguments
group_name <- args$group_name
snpFilePath <- args$snpFilePath
snpLocPath <- args$snpLocPath
feature_data_path <- args$feature_data_path
feature_locations_path <- args$feature_locations_path
covFilePath <- args$covFilePath
threads <- args$threads

# Print arguments for debugging
cat("Group name:", group_name, "\n")
cat("SNP file path:", snpFilePath, "\n")
cat("SNP location path:", snpLocPath, "\n")
cat("Feature data path:", feature_data_path, "\n")
cat("Feature locations path:", feature_locations_path, "\n")
cat("Covariates file path:", covFilePath, "\n")
cat("Number of threads:", threads, "\n")

# Run the SmoothR::matrixEQTLwrapperMC function
SmoothR::matrixEQTLwrapperMC(
  feature_locations_path = feature_locations_path,
  feature_data_path = feature_data_path,
  snpFilePath = snpFilePath,
  covFilePath = covFilePath,
  snpLocPath = snpLocPath,
  group_name = group_name,
  resultsDir = getwd(),
  cisDist = 1e6,
  pvOutputThreshold = 1e-7,
  pvOutputThresholdCis = 1e-5,
  useModel = "linear",
  minPvByGeneSnp = FALSE,
  noFDRsaveMemory = FALSE,
  SNPsInChunks = FALSE,
  prefix = "linear1",
  threads = threads,
  pvalueHist = "qqplot"
)