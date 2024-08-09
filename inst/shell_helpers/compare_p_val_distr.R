#!/usr/bin/env Rscript
wd <- getwd()

setwd("/cfs/klemming/projects/snic/sllstore2017078/lech")
source("/cfs/klemming/projects/snic/sllstore2017078/lech/renv/activate.R")

setwd(wd)
#!/usr/bin/env Rscript

# Load necessary libraries
library(argparse)
library(data.table)
library(ggplot2)
library(cowplot)

# Define command-line arguments
parser <- ArgumentParser(description = 'Compare p-values from two files')
parser$add_argument("file1", help = "Path to the first file")
parser$add_argument("file2", help = "Path to the second file")
parser$add_argument("--name1", help = "Custom name for the first file", default = NULL)
parser$add_argument("--name2", help = "Custom name for the second file", default = NULL)
args <- parser$parse_args()

# Read data from the first file
data1 <- fread(
  args$file1,
  header = FALSE,
  skip = 1,
  showProgress = TRUE,
  select = c(1, 2, 4)
)

# Read data from the second file
data2 <- fread(
  args$file2,
  header = FALSE,
  skip = 1,
  showProgress = TRUE,
  select = c(1, 2, 4)
)

# Sample 10,000 p-values from each dataset
set.seed(123) # for reproducibility
sample1 <- data1[sample(.N, min(10000, .N)), .(V4)]
sample2 <- data2[sample(.N, min(10000, .N)), .(V4)]

# Determine source names
source1 <- if (is.null(args$name1)) basename(args$file1) else args$name1
source2 <- if (is.null(args$name2)) basename(args$file2) else args$name2

# Combine the samples into one data.table
sample1[, source := source1]
sample2[, source := source2]
combined_data <- rbindlist(list(sample1, sample2), use.names = TRUE)

# Save the combined data as an RDS file
rds_output_file <- "combined_pvalue_data.rds"
saveRDS(combined_data, rds_output_file)

# Define custom breaks for the x-axis
breaks <- 10^seq(-300, 0, by = 10)

# Create the histogram plots
p1 <- ggplot(combined_data, aes(x = V4, fill = source)) +
  geom_histogram(binwidth = 1, color = "black", alpha = 0.7, position = "identity") +
  scale_x_log10(breaks = breaks, labels = scales::trans_format("log10", scales::math_format(10^.x))) +
  labs(
    title = "Histogram of p-values Distribution (Bin size = 1)",
    x = "p-values",
    y = "Frequency",
    fill = "Source"
  ) +
  theme_minimal() +
  theme(legend.position = "top")

p2 <- ggplot(combined_data, aes(x = V4, fill = source)) +
  geom_histogram(binwidth = 10, color = "black", alpha = 0.7, position = "identity") +
  scale_x_log10(breaks = breaks, labels = scales::trans_format("log10", scales::math_format(10^.x))) +
  labs(
    title = "Histogram of p-values Distribution (Bin size = 10)",
    x = "p-values",
    y = "Frequency",
    fill = "Source"
  ) +
  theme_minimal() +
  theme(legend.position = "top")

# Combine the two plots using cowplot
combined_plot <- plot_grid(p1, p2, labels = c("A", "B"), ncol = 1)

# Save the combined plot
output_file <- "combined_pvalue_histogram.pdf"
ggsave(output_file, combined_plot, width = 10, height = 12)

# Print a message indicating where the plot and data were saved
cat("Combined plot saved to", output_file, "\n")
cat("Combined data saved to", rds_output_file, "\n")