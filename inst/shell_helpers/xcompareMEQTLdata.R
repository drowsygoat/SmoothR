#!/usr/bin/env Rscript

# wd <- getwd()

# setwd("/cfs/klemming/projects/snic/sllstore2017078/lech")
# source("renv/activate.R")

# setwd(wd)

# Load necessary librariescd gr 
require(argparse)
require(data.table)
require(parallel)
require(tidyverse)
require(gtools)  # For mixedsort
require(ggplot2)
require(dbscan)
require(cowplot)
require(rasterpdf)
require(Cairo)
require(UpSetR)
library(gridExtra)
library(ggupset)
library(SmoothR)

dir_pattern = "group_[0-4]_results"
file_name = "plotdata_sum_chr.rds"
prefix = "linear"

combine_plotdata_files <- function(parent_directory = getwd(), file_name, prefix = prefix, dir_pattern) {

    directories <- list.dirs(path = parent_directory, full.names = FALSE, recursive = FALSE)

    if (! is.null(dir_pattern)) {
        directories <- directories[grepl(dir_pattern, directories)]
    }

    all_data <- list()
    
    for (dir in directories) {

        file_path <- list.files(dir, recursive = TRUE, pattern = file_name, full.names = TRUE)
        
        file_path <- file_path[grepl(prefix, file_path)]

        if (length(file_path) == 1 && file.exists(file_path)) {
            data <- readRDS(file_path)
            data[, sample := dir]
            all_data[[length(all_data) + 1]] <- data
        } else {
            warning(paste("No or multiple file(s) found:", file_path))
        }
    }

    combined_data <- rbindlist(all_data)

    return(combined_data)
}

plotdata_trans_hotspots_combined <- combine_plotdata_files(file_name = "plotdata_trans_hotspots.rds", prefix = prefix, dir_pattern = dir_pattern)

plotdata_sum_chr_combined <- combine_plotdata_files(file_name = "plotdata_sum_chr.rds", prefix = prefix, dir_pattern = dir_pattern)

plotdata_stats_combined <- combine_plotdata_files(file_name =  "plotdata_stats.rds", prefix = prefix, dir_pattern = dir_pattern)

overall_numbers_combined <- combine_plotdata_files(file_name = "overall_numbers.rds", prefix = prefix, dir_pattern = dir_pattern)

# Perform DBSCAN clustering on center_location by chromosome and sample
threshold <- 50

plotdata_trans_hotspots_combined[, cluster := dbscan(as.matrix(.SD), eps = threshold, minPts = 1)$cluster, by = .(chr_snp, sample), .SDcols = "center_location"]

# Add combined chr_location_cluster column
plotdata_trans_hotspots_combined[, chr_x_locationCluster:= paste0(chr_snp, "_x_", cluster)]

common_theme <- theme(
    legend.key.size = unit(0.3, "lines"),  # Custom key size
    legend.spacing.y = unit(0.1, "cm"),    # Tighter vertical spacing
    legend.text = element_text(size = 5),   # Smaller text in the legend
    legend.title = element_text(size = 6),
    legend.position = "top",
    axis.text.x = element_text(angle = 45, hjust = 1, size = 4))


upper_limit <- quantile(plotdata_trans_hotspots_combined$unique_peaks[plotdata_trans_hotspots_combined$unique_peaks > 9], 0.95)

# Plot 1: Histogram of Unique Peaks per Hotspot for Each Sample
plot1 <- ggplot(plotdata_trans_hotspots_combined[unique_peaks > 9, ], aes(x = unique_peaks)) +
    geom_histogram(binwidth = 1, alpha = 1, position = "dodge") +
    facet_wrap(~sample, scales = "fixed", ncol = 1) +
    labs(title = "Histogram of Unique Peaks per Hotspot", x = "Number of Unique Peaks", y = "Frequency") +
    ylim(c(0,upper_limit))

plot1lim <- ggplot(plotdata_trans_hotspots_combined[unique_peaks > 9, ], aes(x = unique_peaks)) +
    geom_histogram(binwidth = 1, alpha = 1, position = "dodge") +
    facet_wrap(~sample, scales = "fixed", ncol = 1) +
    scale_y_log10() +
    labs(title = "Histogram of Unique Peaks Frequency per Hotspot", x = "Number of Unique Peaks", y = "Frequency") +
    ylim(c(0,upper_limit)) 

plot1sqrt <- ggplot(plotdata_trans_hotspots_combined[unique_peaks > 9, ], aes(x = unique_peaks)) +
    geom_histogram(binwidth = 1, alpha = 1 position = "dodge") +
    scale_y_log10() +
    facet_wrap(~sample, scales = "fixed", ncol = 1) +
    labs(title = "Histogram of Unique Peaks Frequency per Hotspot", x = "Number of Unique Peaks", y = "Frequency (Log)") +
    ylim(c(0,upper_limit)) +
    xlim(c(0,10000))

# Plot 2: Bar Plot of QTL Count per Chromosome for Each Sample
plot2 <- ggplot(plotdata_sum_chr_combined, aes(x = chr_snp, y = QTL_count, fill = QTL_type)) +
    geom_bar(stat = "identity", position = "dodge", color = "black") +
    facet_wrap(~sample+QTL_type, scales = "free", ncol=2) +
    labs(title = "Peak Values per Chromosome", x = "Chromosome", y = "Count") 

# Plot 3: Bar Plot of QTL Count by QTL Type for Each Sample
plot3 <- ggplot(plotdata_stats_combined[sample(1:nrow(plotdata_stats_combined), 10000)] , aes(x = sample, y = QTL_count, fill = QTL_type)) +
    geom_bar(stat = "identity", position = "dodge") +
    labs(title = "Count of Significant QTLs (by snp_id and qtl type)", x = "QTL Type", y = "Count") 

plot4 <- ggplot(overall_numbers_combined, aes(x = sample, y = Proportion, fill = Type)) +
    geom_bar(stat = "identity", position = "dodge") +
    labs(title = "Fractions of Significant Counts", x = "Cluster", y = "Fraction of Significant") 


# Extract legend from the first plot (before applying common_theme)

# legend <- get_legend(plot1)

# Prepare data for the UpSet plot using ggupset
upset_data <- plotdata_trans_hotspots_combined[, .(chr_x_locationCluster, sample)]

upset_data <- upset_data[, .(sample_list = list(unique(sample))), by = chr_x_locationCluster]

# Plot 4: UpSet plot showing overlaps of unique chr_location_cluster combinations between samples
plot5 <- ggplot(upset_data, aes(x = sample_list)) +
    geom_bar() +
    scale_x_upset() +
    labs(title = "UpSet Plot of chr_location_cluster Combinations", x = "Samples", y = "Count")

plotlist <- lapply(list(plot1, plot1lim, plot1sqrt, plot2, plot3, plot4, plot5), function (x) {
    x <- x + theme_minimal(base_size = 9) + common_theme
})

# Combine the Plots into a Single PDF
# combined_plot <- plot_grid(plotlist = plotlist[[1]], plotlist[[2]], plotlist[[3]], plotlist[[4]], plotlist[[5]], plot5, 
#     labels = c("A", "B", "C", "D", "E"), ncol = 1, nrow = 1)

# final_plot <- plot_grid(combined_plot, legend, ncol = 1, rel_heights = c(1, 0.1))

# Save the combined plot as a PDF
# pdf("combined_plot_comparison2.pdf", width = 10, height = 12)
# print(final_plot)
# dev.off()

ggpubr::ggexport(plotlist, filename = file.path(parent_directory, "summary_plot_linear.pdf"))





# Prepare data for the UpSet plot
# upset_data <- dcast(plotdata_trans_hotspots_combined, chr_x_locationCluster ~ sample, length, value.var = "unique_peaks")
# upset_data <- upset_data[!is.na(chr_x_locationCluster), ]

# Convert data to binary format for UpSetR
# upset_binary <- as.data.table(t(apply(upset_data[, -1, with = FALSE], 1, function(x) as.numeric(x > 0))))
# setnames(upset_binary, colnames(upset_data)[-1])
# upset_binary[, chr_x_locationCluster := upset_data$chr_x_locationCluster]

# # Plot 4: UpSet plot showing overlaps of unique chr_location_cluster combinations between samples
# plot4 <- upset(upset_binary, sets = colnames(upset_binary)[-ncol(upset_binary)], order.by = "freq", main.bar.color = "blue", sets.bar.color = "red")

# upset_grob <- gridExtra::arrangeGrob(plot4)
# upset_grob <- grid.grabExpr(upset(upset_binary, sets = colnames(upset_binary)[-ncol(upset_binary)], order.by = "freq", main.bar.color = "blue", sets.bar.color = "red"))
