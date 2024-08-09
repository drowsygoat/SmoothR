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
    parser$add_argument("p_value_threshold", help = "p_value_threshold")

    args <- parser$parse_args()
    return(args)
}

exists_and_not_empty <- function(directory_path) {
  # Check if the directory exists
  if (dir.exists(directory_path)) {
    # List files in the directory
    files <- list.files(directory_path)
    # Check if the directory is not empty
    if (length(files) > 0) {
      return(TRUE)
    } else {
      return(FALSE)
    }
  } else {
    return(FALSE)
  }
}

# Function to read and process ntests file

read_ntests <- function(directory, pattern, prefix) {
    ntests_file <- list.files(directory, pattern = pattern, full.names = TRUE)
    ntests_file <- grep(prefix, ntests_file, value = TRUE)

    if (length(ntests_file) == 0) {
        stop("No ntests_combined.txt file found in the directory")
    }
    n_tests <- fread(ntests_file)
    n_tests <- lapply(n_tests, as.double)
    return(list(n_tests_cis = n_tests[[3]], n_tests_trans = n_tests[[2]]))
}

# Function to adjust p-values and filter data
load_and_filter <- function(file, p_val_threshold = NULL) {

    print("load_and_filter")

    con <- gzfile(file, open = "rt")
    num_lines <- length(readLines(con, warn = FALSE))
    close(con)
    
    if (num_lines <= 2) { # change this is skipping line to
        message(paste("Skipping file due to insufficient lines:", file))
        return(NULL)
    }

    data <- fread(
        file,
        header = FALSE, # make sure that the file is formatted forrectly (tab separated and with header)
        skip = 1, ########
        showProgress = TRUE,
        select = c(1, 2, 4))

    # setnames(data, c("SNP", "gene", "p-value"), c("snp_id", "peak_id", "p_value"))

    setnames(data, c("V1", "V2", "V4"), c("snp_id", "peak_id", "p_value"))

    print(colnames(data))

    if (nrow(data) < 2 && ncol(data) < 4) {
        message(paste("Skipping file due to insufficient data:", file))
        return(NULL)
    }

    print(paste("1", file, nrow(data)))

    if (!is.null(p_val_threshold)) {
        data <- data[ p_value < p_val_threshold ]
    }

    print(paste("2", file, nrow(data)))
        
    gc()

    return(data)
}

# Function to process eQTL files and adjust p-values
process_eqtl_files <- function(directory, results_path, cis_pattern, trans_pattern, n_tests_pattern, threshold, prefix, p_val_threshold = NULL) {

    print("process_eqtl_files")

    n_tests <- read_ntests(directory, pattern = n_tests_pattern, prefix = prefix)

    n_tests_trans <- n_tests$n_tests_trans
    n_tests_cis <- n_tests$n_tests_cis

    print(n_tests_trans)
    print(n_tests_cis)

    # Validate n_tests values
    if (any(c(n_tests_trans, n_tests_cis) <= 1)) {
        stop("Invalid n_tests value")
    }

    trans_files <- list.files(directory, pattern = trans_pattern, full.names = TRUE)
    cis_files <- list.files(directory, pattern = cis_pattern, full.names = TRUE)

    cis_files <- grep(prefix, cis_files, value = TRUE)
    trans_files <- grep(prefix, trans_files, value = TRUE)

    # eqtl_data_trans <- mclapply(trans_files, load_and_filter, mc.cores = num_cores, mc.preschedule = FALSE)

    eqtl_data_trans <- lapply(trans_files, load_and_filter, p_val_threshold = p_val_threshold)
    eqtl_data_trans <- rbindlist(eqtl_data_trans)

    # eqtl_data_cis <- mclapply(cis_files, load_and_filter, mc.cores = num_cores, mc.preschedule = FALSE)

    eqtl_data_cis <- lapply(cis_files, load_and_filter, p_val_threshold = p_val_threshold)
    eqtl_data_cis <- rbindlist(eqtl_data_cis)

    gc()

    if (threshold == "FWER") {
        eqtl_data_trans[, FWER := p.adjust(p_value, method = "FWER", n = n_tests_trans)]
        eqtl_data_cis[, FWER := p.adjust(p_value, method = "FWER", n = n_tests_cis)]
        eqtl_data_cis <- eqtl_data_cis[FWER < 0.1]
        eqtl_data_trans <- eqtl_data_trans[FWER < 0.1]
    } else {
        eqtl_data_trans[, FDR := p.adjust(p_value, method = "BH", n = n_tests_trans)]
        eqtl_data_cis[, FDR := p.adjust(p_value, method = "BH", n = n_tests_cis)]
        eqtl_data_cis <- eqtl_data_cis[FDR < 0.1]
        eqtl_data_trans <- eqtl_data_trans[FDR < 0.1]
    }

    eqtl_data_trans[, QTL_type := "trans"]
    eqtl_data_cis[, QTL_type := "cis"]

    sig_cis <- nrow(eqtl_data_cis)
    sig_trans <- nrow(eqtl_data_trans)
    
    n_tests_trans
    n_tests_cis

    overall_numbers <- data.table(
        Type = c("cis", "trans"),
        Significant = c(sig_cis, sig_trans),
        Total = c(n_tests_cis, n_tests_trans)
    )

    overall_numbers[, Proportion := Significant / Total]

    saveRDS(overall_numbers, file = file.path(results_path, paste(prefix, "overall_numbers.rds", sep = "_")))

    ######

    gc()

    bon_plotdata <- rbindlist(list(eqtl_data_cis, eqtl_data_trans))

    print("0")
    # print(bon_plotdata)

    # Data manipulation for plotting
    bon_plotdata[, ppts := qunif(ppoints(.N)), by = QTL_type]
    bon_plotdata[, c("chr_snp", "location_snp") := tstrsplit(snp_id, "_", fixed = TRUE)]
    bon_plotdata[, location := as.integer(location_snp)]
    bon_plotdata[, chr_snp := paste0("chr", chr_snp)]
    bon_plotdata <- bon_plotdata[nchar(chr_snp) < 6]

    print("1")
    # print(bon_plotdata)

    # Determine the column to check based on the threshold
    check_column <- ifelse(threshold == "FDR", "FDR", "FWER")

    # Identify non-finite rows
    non_finite_rows <- bon_plotdata[!is.finite(-log10(get(check_column)))]

    # Save non-finite rows if any exist
    if (nrow(non_finite_rows) > 0) {
        saveRDS(non_finite_rows, file = file.path(directory, paste0("non_finite_values_debug_", basename(results_path), ".rds")))
    }

    # Apply the binning based on the threshold
    bin_column <- ifelse(threshold == "FDR", "FDR_bins", "FWER_bins")

    bon_plotdata[, (bin_column) := cut_width(-log10(get(check_column)), width = 1, center = 0.5)]

    # bon_plotdata[, FDR_bins := cut_width(-log10(FDR), width = 1, center = 0.5)]

    print("2")
    # print(bon_plotdata)

    sorted_levels <- gtools::mixedsort(unique(bon_plotdata$chr_snp))

    bon_plotdata[, chr_snp := factor(chr_snp, levels = sorted_levels)]
    setorder(bon_plotdata, chr_snp)

    gc()

    saveRDS(bon_plotdata, file = file.path(results_path, paste(prefix, "results.rds", sep = "_")))

}

make_all_plots_data <- function(results_path = results_path, prefix, threshold = "FDR") {

    bin_column <- ifelse(threshold == "FDR", "FDR_bins", "FWER_bins")

    bon_plotdata <- readRDS(file.path(results_path, paste(prefix, "results.rds", sep = "_")))

    # Create plotdata_trans_hotspots (trans only)
    threshold <- 100  

    plotdata_trans_hotspots <- bon_plotdata[QTL_type == "trans", 
                                        hotspot := dbscan(as.matrix(.SD), eps = threshold, minPts = 1)$cluster, 
                                        by = .(chr_snp), .SDcols = "location"
                                        ][, .(unique_peaks = uniqueN(peak_id), 
                                                center_location = mean(location)), 
                                            by = .(chr_snp, hotspot)]

    plotdata_trans_hotspots <- plotdata_trans_hotspots[!is.na(hotspot)]
    print("4")
    saveRDS(plotdata_trans_hotspots, file = file.path(results_path, paste(prefix, "plotdata_trans_hotspots.rds", sep = "_")))
    print("5")

    plotdata_stats <- bon_plotdata[, .(QTL_count = .N), by = .(snp_id, QTL_type)]
    saveRDS(plotdata_stats, file = file.path(results_path, paste(prefix, "plotdata_stats.rds", sep = "_")))
    print("6")

    snp_target_stats <- bon_plotdata[, .(targets_count = uniqueN(peak_id)), by = .(snp_id, QTL_type)]
    saveRDS(snp_target_stats, file = file.path(results_path, paste(prefix, "snp_target_stats.rds", sep = "_")))
    print("7")

    plotdata_sum_chr <- bon_plotdata[, .(QTL_count = .N), by = .(chr_snp, QTL_type, bins = get(bin_column))]
    saveRDS(plotdata_sum_chr, file = file.path(results_path, paste(prefix, "plotdata_sum_chr.rds", sep = "_")))
    print("8")

    return(invisible(NULL))
}


# Function to plot the results
plot_results <- function(input_dir = input_dir, output_dir = NULL, threshold = "FDR", prefix = prefix) {

    plotdata_trans_hotspots <- readRDS(file.path(input_dir, paste(prefix,"plotdata_trans_hotspots.rds", sep = "_")))

    plotdata_sum_chr <- readRDS(file.path(input_dir, paste(prefix, "plotdata_sum_chr.rds", sep = "_")))
    
    snp_target_stats <- readRDS(file.path(input_dir, paste(prefix, "snp_target_stats.rds", sep = "_")))

    overall_numbers <- readRDS(file.path(input_dir, paste(prefix, "overall_numbers.rds", sep = "_")))

    bin_column <- ifelse(threshold == "FDR", "FDR_bins", "FWER_bins")

    # Define the common size parameters
    common_theme <- theme(
        legend.key.size = unit(0.3, "lines"),  # Custom key size
        legend.spacing.y = unit(0.1, "cm"),    # Tighter vertical spacing
        legend.text = element_text(size = 8),   # Smaller text in the legend
        legend.title = element_text(size = 10),
        legend.position = "right",
        axis.text.x = element_text(angle = 45, hjust = 1, size = 6)
    )
print(overall_numbers)
# Create the ggplot
    plot0 <- ggplot(overall_numbers, aes(x = Type, y = Proportion, fill = Type)) +
    geom_bar(stat = "identity", position = "dodge") +
    geom_text(aes(label = Significant), vjust = -0.5, size = 5) +
    labs(
        title = "Proportion of Significant eQTLs",
        x = "eQTL Type",
        y = "Proportion of Significant eQTLs"
    )

    # Plot histogram of number of unique peaks per cluster
    plot1 <- ggplot(plotdata_trans_hotspots[plotdata_trans_hotspots$unique_peaks > 9, ], aes(x = unique_peaks)) +
        geom_histogram(binwidth = 1, fill = "blue") +
        labs(title = "Histogram of Unique Peaks per Hotspot", x = "Number of Unique Peaks", y = "Frequency") +
        theme_minimal(base_size = 6)

    # Plot QTL_count
    plot2 <- ggplot(plotdata_sum_chr, aes(x = chr_snp, y = QTL_count, fill = 
    bins)) +
        geom_bar(stat = "identity") +
        labs(title = "Peak Values per Chromosome", x = "Chromosome", y = "Count") +
        guides(fill = guide_legend(
            title = bin_column,
            title.position = "top",
            label.position = "left",
            ncol = 3,
            keywidth = 0.2,      # Smaller width of legend keys
            keyheight = 0.2,     # Smaller height of legend keys
            default.unit = "cm"
        )) + theme_minimal(base_size = 10) + common_theme

    # Plot histogram for np_target_stats
    plot3 <- ggplot(snp_target_stats[snp_target_stats$targets_count > 1, ], aes(x = targets_count)) +
        geom_histogram(binwidth = 1, fill = "#537b53") +
        labs(title = "Histogram of Peak Targets Count per SNP", x = "Targets Count", y = "Frequency")

    plot4 <- plot3 + scale_y_log10()
    plot5 <- plot1 + scale_y_log10()

    plotlist <- lapply(list( plot0, plot2, plot1, plot5, plot3, plot4 ), function(plot) {
        plot + theme_minimal(base_size = 10) + common_theme
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

    if (! interactive()) {
        args <- parse_args()
        directory <- args$directory
        prefix <- args$prefix
        p_val_threshold <- args$p_val_threshold


    } else {

        directory <- getwd()
        prefix <- "linear"
        p_val_threshold <- NULL

    }

    results_path <- file.path(directory, paste(prefix, "results", sep = "_"))

    # if (! exists_and_not_empty(results_path)) {

    #     dir.create(results_path, recursive = TRUE, showWarnings = FALSE)

    #     process_eqtl_files(
    #         directory = directory,
    #         results_path = results_path,
    #         trans_pattern = "eQTL_trans_reduced_reduced_sub\\.txt\\.gz",
    #         cis_pattern = "eQTL_cis_reduced_reduced_sub\\.txt\\.gz",
    #         n_tests_pattern = "ntests_combined\\.txt",
    #         prefix = prefix,
    #         threshold = "FDR",
    #         p_val_threshold = p_val_threshold)
    # } else {
    #     message("Directory with results exists. Skipping step.")
    # }

     make_all_plots_data(
        results_path = results_path,
        prefix = prefix,
        threshold = "FDR")
    
    plots_path <- file.path(directory, paste(prefix, "plots", sep = "_"))

    if (! exists_and_not_empty(plots_path)) {

        dir.create(plots_path, recursive = TRUE, showWarnings = FALSE)

        plot_results(input_dir = results_path, output_dir = plots_path, threshold = "FDR", prefix = prefix)
    } else {
        message("Directory with plots exists. Skipping step.")
    }
}

# Run the main function
main()

            # trans_pattern = "eQTL_trans_reduced\\.txt\\.gz",
            # cis_pattern = "eQTL_cis_reduced\\.txt\\.gz",
            # n_tests_pattern = "ntests_combined\\.txt",