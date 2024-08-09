#!/usr/bin/env Rscript

wd <- getwd()

setwd("/cfs/klemming/projects/snic/sllstore2017078/lech")
source("/cfs/klemming/projects/snic/sllstore2017078/lech/renv/activate.R")

setwd(wd)

# Load necessary librariescd gr 
require(argparse)
require(data.table)
require(parallel)
require(tidyverse)
require(gtools)  # For mixedsort
require(ggplot2)
require(dbscan)
require(cowplot)
library(ggpubr)
# require(rasterpdf)
# require(Cairo)

options(datatable.showProgress = TRUE)

print(detectCores())

num_cores <- 1

print(num_cores)

# Function to parse command-line arguments
parse_args <- function() {

    parser <- ArgumentParser(description = "Process eQTL files")
    parser$add_argument("directory", help = "Directory containing the files")
    parser$add_argument("prefix", help = "prefix")

    args <- parser$parse_args()
    
    return(args)
}

# Function to plot the results
plot_results <- function(input_dir = input_dir, output_dir = NULL) {

    plotdata_trans_hotspots <- readRDS(file.path(input_dir, "plotdata_trans_hotspots.rds"))

    plotdata_sum_chr <- readRDS(file.path(input_dir, "plotdata_sum_chr.rds"))
    
    snp_target_stats <- readRDS(file.path(input_dir, "snp_target_stats.rds"))

    overall_numbers <- readRDS(file.path(input_dir, "overall_numbers.rds"))


    if (is.null(output_dir)) {
        output_dir <- input_dir
    } else {
        dir.create(output_dir)
    }

    # Define the common size parameters
    common_theme <- theme(
        legend.key.size = unit(0.3, "lines"),  # Custom key size
        legend.spacing.y = unit(0.1, "cm"),    # Tighter vertical spacing
        legend.text = element_text(size = 8),   # Smaller text in the legend
        legend.title = element_text(size = 10),
        legend.position = "right",
        axis.text.x = element_text(angle = 45, hjust = 1, size = 6)
    )


# Create the ggplot
    plot0 <- ggplot(dt, aes(x = Category, y = Proportion, fill = Category)) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_text(aes(label = Significant), vjust = -0.5, size = 5) +
    labs(
        title = "Proportion of Significant eQTLs",
        x = "eQTL Type",
        y = "Proportion of Significant eQTLs"
    ) +
    theme_minimal()


    # Plot histogram of number of unique peaks per cluster
    plot1 <- ggplot(plotdata_trans_hotspots[plotdata_trans_hotspots$unique_peaks > 9, ], aes(x = unique_peaks)) +
        geom_histogram(binwidth = 1, fill = "blue") +
        labs(title = "Histogram of Unique Peaks per Hotspot", x = "Number of Unique Peaks", y = "Frequency") +
        theme_minimal()

    # Plot QTL_count
    plot2 <- ggplot(plotdata_sum_chr, aes(x = chr_snp, y = QTL_count, fill = bon_bins)) +
        geom_bar(stat = "identity") +
        labs(title = "Peak Values per Chromosome", x = "Chromosome", y = "Count") +
        theme_minimal() +
        guides(fill = guide_legend(
            title = "FWER bin",
            title.position = "top",
            label.position = "left",
            ncol = 3,
            keywidth = 0.2,      # Smaller width of legend keys
            keyheight = 0.2,     # Smaller height of legend keys
            default.unit = "cm"
        ))

    # Plot histogram for np_target_stats
    plot3 <- ggplot(snp_target_stats, aes(x = targets_count)) +
        geom_histogram(binwidth = 1, fill = "green") +
        labs(title = "Histogram of Peak Targets Count per SNP", x = "Targets Count", y = "Frequency") +
        theme_minimal()

    plotlist <- lapply(list(plot0, plot1, plot2, plot3), function(plot) {
        plot + common_theme
    })

    # combined_plot <- plot_grid(plotlist = plotlist, labels = c("A", "B"), ncol = 1)

    # combined_plot <<- plot_grid(plotlist = plotlist, labels = c("A", "B"), ncol = 1)

    # Save the combined plot as a rasterized PDF using cairo_pdf
    # rasterpdf::raster_pdf(file.path(directory, "combined_plot.pdf"), width = 10, height = 12, res = 300)
    # print(combined_plot)
    # dev.off()

    # pdf(file.path(plots_dir, "combined_plot.pdf"))
    # print(combined_plot)
    # dev.off()

    # combined_plot <- ggpubr::ggarrange(
    #     common.legend = FALSE,
    #     plotlist = p,
    #     nrow = 1,
    #     ncol = 1,
    #     # labels = paste("Sample:", sample_name),
    #     hjust = -0.2,
    #     vjust = 1.6
    # )

    ggpubr::ggexport(plotlist, filename = file.path(output_dir, "combined_plot.pdf"))
}

# Main function
main <- function() {

    if (!interactive()) {
        args <- parse_args()
        directory <- args$directory
        prefix <- args$prefix
    } else {
        directory <- getwd()
        prefix <- "anova"
    }
    
    plots_dir <- file.path(directory, paste(basename(directory), prefix, "plots", sep = "_"))

    plot_results(input_dir = directory, output_dir = plots_dir)

}

# Run the main function
main()

