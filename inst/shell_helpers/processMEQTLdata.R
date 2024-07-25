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
require(rasterpdf)
require(Cairo)

options(datatable.showProgress = TRUE)


print(detectCores())

num_cores <- 3

print(num_cores)

# Function to parse command-line arguments
parse_args <- function() {
    parser <- ArgumentParser(description = "Process eQTL files")
    parser$add_argument("directory", help = "Directory containing the eQTL files")
    args <- parser$parse_args()
    return(args)
}

# Function to read and process ntests file
read_ntests <- function(directory) {
    ntests_file <- list.files(directory, pattern = "ntests_combined\\.txt", full.names = TRUE)
    if (length(ntests_file) == 0) {
        stop("No ntests_combined.txt file found in the directory")
    }
    n_tests <- fread(ntests_file)
    n_tests <- lapply(n_tests, as.double)
    return(list(n_tests_cis = n_tests[[3]], n_tests_trans = n_tests[[2]]))
}

# Function to adjust p-values and filter data
load_and_filter <- function(file) {

    print("load_and_filter")

    con <- gzfile(file, open = "rt")
    num_lines <- length(readLines(con, warn = FALSE))
    close(con)
    
    if (num_lines <= 1) {
        message(paste("Skipping file due to insufficient lines:", file))
        return(NULL)
    }

    data <- fread(file, header = FALSE, skip = 1, showProgress = TRUE)

    if (nrow(data) < 2 && ncol(data) < 4) {
        message(paste("Skipping file due to insufficient data:", file))
        return(NULL)
    }
    
    print(paste("1", file, nrow(data)))
    # data <- data[sample(.N, .N * 0.1)]
    print(paste("2", file, nrow(data)))
    data <- data[V4 < 10^-10]
    print(paste("3", file, nrow(data)))
    
    gc()

    return(data)
}

# Function to process eQTL files and adjust p-values
process_eqtl_files <- function(directory, results_path) {

    print("process_eqtl_files")

    n_tests <- read_ntests(directory)

    n_tests_trans <- n_tests$n_tests_trans
    n_tests_cis <- n_tests$n_tests_cis

    print(n_tests_trans)
    print(n_tests_cis)

    # Validate n_tests values
    if (any(c(n_tests_trans, n_tests_cis) <= 1)) {
        stop("Invalid n_tests value")
    }

    trans_files <- list.files(directory, pattern = "eQTL_trans_reduced\\.txt\\.gz", full.names = TRUE)

    cis_files <- list.files(directory, pattern = "eQTL_cis_reduced\\.txt\\.gz", full.names = TRUE)

    eqtl_data_trans <- mclapply(trans_files, load_and_filter, mc.cores = num_cores, mc.preschedule = FALSE)
    
    eqtl_data_trans <- rbindlist(eqtl_data_trans)
    saveRDS(eqtl_data_trans, file = "prior_to_adj.rds")

    eqtl_data_trans[, FDR := p.adjust(V4, method = "BH", n = n_tests_trans)]
    eqtl_data_trans[, bonferroni := p.adjust(V4, method = "bonferroni", n = n_tests_trans)]

    saveRDS(eqtl_data_trans, file = "after_adj.rds")

    print(eqtl_data_trans)

    eqtl_data_trans <- eqtl_data_trans[bonferroni < 0.1]
    eqtl_data_trans[, QTL_type := "trans"]

    print(eqtl_data_trans)

    ######
    eqtl_data_cis <- mclapply(cis_files, load_and_filter, mc.cores = num_cores, mc.preschedule = FALSE)

    eqtl_data_cis <- rbindlist(eqtl_data_cis)
    
    eqtl_data_cis[, FDR := p.adjust(V4, method = "BH", n = n_tests_cis)]
    eqtl_data_cis[, bonferroni := p.adjust(V4, method = "bonferroni", n = n_tests_cis)]

    eqtl_data_cis <- eqtl_data_cis[bonferroni < 0.1]
    eqtl_data_cis[, QTL_type := "cis"]

    ######

    gc()

    bon_plotdata <- rbindlist(list(eqtl_data_cis, eqtl_data_trans))

    print("0")
    print(bon_plotdata)

    # Data manipulation for plotting
    setnames(bon_plotdata, c("V1", "V2", "V3", "V4", "V5"), c("snp_id", "peak_id", "F_stat", "p_value", "FDR_legacy"))
    bon_plotdata[, ppts := qunif(ppoints(.N)), by = QTL_type]
    bon_plotdata[, c("chr_snp", "location_snp") := tstrsplit(snp_id, "_", fixed = TRUE)]
    bon_plotdata[, location := as.integer(location_snp)]
    bon_plotdata[, chr_snp := paste0("chr", chr_snp)]
    bon_plotdata <- bon_plotdata[nchar(chr_snp) < 6]

    print("1")
    print(bon_plotdata)

    non_finite_rows <- bon_plotdata[!is.finite(-log10(bonferroni))]


    if (nrow(non_finite_rows) > 0) {
        saveRDS(non_finite_rows, file = file.path(directory, paste0("non_finite_", basename(results_path))))
    }

    bon_plotdata[, bon_bins := cut_width(-log10(bonferroni), width = 1, center = 0.5)]

    print("2")
    print(bon_plotdata)

    sorted_levels <- gtools::mixedsort(unique(bon_plotdata$chr_snp))

    bon_plotdata[, chr_snp := factor(chr_snp, levels = sorted_levels)]
    setorder(bon_plotdata, chr_snp)

    saveRDS(bon_plotdata, file = results_path)

    # Create plotdata_trans_hotspots
    threshold <- 100  

    plotdata_trans_hotspots <- bon_plotdata[QTL_type == "trans", 
                                            hotspot := dbscan(as.matrix(.SD), eps = threshold, minPts = 1)$cluster, 
                                            by = .(chr_snp), .SDcols = "location"
                                            ][, .(unique_peaks = uniqueN(peak_id), 
                                                  center_location = mean(location)), 
                                              by = .(chr_snp, hotspot)]

    plotdata_trans_hotspots <- plotdata_trans_hotspots[!is.na(hotspot)]

    saveRDS(plotdata_trans_hotspots, file = file.path(directory, "plotdata_trans_hotspots.rds"))

    # Filter out rows where hotspot is NA

    # bon_plotdata <<- bon_plotdata

    # Create plotdata_stats
    plotdata_stats <- bon_plotdata[, .(QTL_count = .N), by = .(QTL_type)]

    # plotdata_stats <<- plotdata_stats

    saveRDS(plotdata_stats, file = file.path(directory, "plotdata_stats.rds"))

    # Create plotdata_sum_chr
    plotdata_sum_chr <- bon_plotdata[, .(QTL_count = .N), by = .(chr_snp, bon_bins)]

    # plotdata_sum_chr <<- plotdata_sum_chr

    saveRDS(plotdata_sum_chr, file = file.path(directory, "plotdata_sum_chr.rds"))

    return(invisible(NULL))
}

# Function to plot the results
plot_results <- function(directory) {
    plotdata_trans_hotspots <- readRDS(file.path(directory, "plotdata_trans_hotspots.rds"))

    plotdata_sum_chr <- readRDS(file.path(directory, "plotdata_sum_chr.rds"))

    # Define the common size parameters
    common_theme <- theme(
        legend.key.size = unit(0.3, "lines"),  # Custom key size
        legend.spacing.y = unit(0.1, "cm"),    # Tighter vertical spacing
        legend.text = element_text(size = 8),   # Smaller text in the legend
        legend.title = element_text(size = 10),
        legend.position = "right",
        axis.text.x = element_text(angle = 45, hjust = 1, size = 6)
    )

    # Plot histogram of number of unique peaks per cluster
    plot1 <- ggplot(plotdata_trans_hotspots[plotdata_trans_hotspots$unique_peaks > 9, ], aes(x = unique_peaks)) +
        geom_histogram(binwidth = 1, fill = "blue", color = "black") +
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

    plotlist <- lapply(list(plot1, plot2), function(plot) {
        plot + common_theme
    })

    combined_plot <- plot_grid(plotlist = plotlist, labels = c("A", "B"), ncol = 1)
    # combined_plot <<- plot_grid(plotlist = plotlist, labels = c("A", "B"), ncol = 1)

    # Save the combined plot as a rasterized PDF using cairo_pdf
    # rasterpdf::raster_pdf(file.path(directory, "combined_plot.pdf"), width = 10, height = 12, res = 300)
    # print(combined_plot)
    # dev.off()

    pdf(file.path(directory, "combined_plot.pdf"))
    print(combined_plot)
    dev.off()
}

# Main function
main <- function() {
    if (!interactive()) {
        args <- parse_args()
        directory <- args$directory
    } else {
        directory <- getwd()
    }
    
    results_path <- file.path(directory, paste0(basename(directory), "_results.rds"))

    process_eqtl_files(directory, results_path)

    plot_results(directory)
}

# Run the main function
main()
