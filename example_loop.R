#!/usr/bin/env Rscript

# Preamble
##########################################################################
args <- commandArgs(trailingOnly = TRUE)
args
require(SmoothR, quietly = TRUE)

# Initialize session and set working directory
################################################################################
args <- InitNow(session_file_name = "empty.RData")

# Load command line arguments
################################################################################

cat(sprintf("Configuration:\n- Output directory: %s\n- Script name: %s\n- Suffix: %s\n- Timestamp: %s\n- Threads: %d\n",
            args[1], args[2], args[3], args[4], as.integer(args[5])))

# Some analysis
################################################################################
require(ggplot2, quietly = TRUE)

Sys.sleep(30)  # Simulated delay for process separation

checkpoint("Start of Analysis")

# Example plotting
pdf(file.path("plot1.pdf"))
plot(mpg)
dev.off()

checkpoint("Analysis Complete")
Sys.sleep(30)

# Prime number calculation function
is_prime <- function(num) {
  if (num < 2) return(FALSE)
  for (i in 2:sqrt(num)) {
    if (num %% i == 0) return(FALSE)
  }
  return(TRUE)
}

find_primes <- function(limit) {
  primes <- c()
  for (num in 2:limit) {
    if (length(primes) >= limit) break
    if (is_prime(num)) primes <- c(primes, num)
  }
  return(primes)
}

prime_numbers <- find_primes(200)
checkpoint("First 20 prime numbers calculated.")

# Error handling with SafeExecute
safeExecute({ I_have_no_mouth_and_I_must_scream })

Sys.sleep(30)
# Save session and cleanup
################################################################################
saveNow()
Sys.sleep(30)
# Properly exit script
################################################################################
quit(status = 0)