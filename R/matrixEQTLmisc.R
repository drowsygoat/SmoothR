library(SummarizedExperiment)
library(MatrixEQTL)
library(Matrix)
library(tibble)
library(dplyr)
library(parallel)

# Prepare feature locations function; helper function
runGroupEQTL <- function(group, group_data, se_sample_ids, summarizedExp, se_sample_data, matrixName, SNPs_sliced, topNrows, common_samples, snp_locations, feature_locations, resultsDir, cisDist = 1e6, pvOutputThreshold = 1e-5, pvOutputThresholdCis = 1e-4, useModel = "linear") {

    if (useModel == "linear") {
      useModel <- MatrixEQTL::modelLINEAR
    } else if (useModel == "anova") {
      useModel <- MatrixEQTL::modelANOVA
    } else if (useModel == "cross") {
      useModel <- MatrixEQTL::modelLINEAR_CROSS
    } else {
      stop("'use model' must be one of \"linear\", \"cross\" or \"anova\"")
    }

    # Ensure directory exists
    if (!dir.exists(resultsDir)) {
        dir.create(resultsDir, recursive = TRUE)
    }

    dir_name <- file.path(resultsDir, paste0("group_", group, "_results"))
    
    if (!dir.exists(dir_name)) {
      dir.create(dir_name, recursive = TRUE)
    }

    output_file_name_trans <- file.path(dir_name, paste0(group, "_eQTL_trans.txt"))
    result_path <- file.path(dir_name, paste0(group, "_result.rds"))
    log_path <- file.path(dir_name, paste0(group, "_log.txt"))
    plot_path <- file.path(dir_name, paste0(group, "_plot.pdf"))
    output_file_name_cis <- file.path(dir_name, paste0(group, "_eQTL_cis.txt"))

    # Start time for execution timing
    start_time <- Sys.time()

    # Execute analysis with error and warning handling
    group_results <- withCallingHandlers({

        group_indices <- which(group_data == group & se_sample_ids %in% common_samples)
        
        sample_to_keep_from_SNPs <- which(SNPs_sliced$columnNames %in% se_sample_data[group_data == group])

        feature_matrix <- as(assays(summarizedExp)[[matrixName]], "sparseMatrix")
        
        group_data_matrix <- feature_matrix[, group_indices, drop = FALSE]

        feature_locations <- prepareLocationsForMatrixEQTL(as.data.frame(rowData(summarizedExp)))

        # Clone and update SNPs_sliced to include only common samples
        SNPs_sliced_cloned <- SNPs_sliced$Clone()
        SNPs_sliced_cloned$ColumnSubsample(sample_to_keep_from_SNPs)

        COV_sliced_cloned <- COV_sliced$Clone()
        COV_sliced_cloned$ColumnSubsample(sample_to_keep_from_SNPs)

        if (!is.null(topNrows)) {
            rowSums <- Matrix::rowSums(group_data_matrix)
            top_indices <- order(rowSums, decreasing = TRUE)[1:min(topNrows, length(rowSums))]
            group_data_matrix <- group_data_matrix[top_indices, , drop = FALSE]
            feature_locations <- feature_locations[top_indices, , drop = FALSE]
        }
        features_data <- SlicedData$new()
        features_data$CreateFromMatrix(as(group_data_matrix, "matrix"))

        MatrixEQTL::Matrix_eQTL_main(
            snps = SNPs_sliced_cloned,
            gene = features_data,
            cvrt = COV_sliced_cloned,
            output_file_name = output_file_name_trans,
            pvOutputThreshold = pvOutputThreshold,
            useModel = useModel,
            errorCovariance = numeric(0),
            output_file_name.cis = output_file_name_cis,
            pvOutputThreshold.cis = pvOutputThresholdCis,
            snpspos = snp_locations,
            genepos = feature_locations,
            cisDist = cisDist,
            pvalue.hist = "qqplot",
            min.pv.by.genesnp = TRUE,
            noFDRsaveMemory = FALSE,
            verbose = TRUE
        )

    }, warning = function(w) {
        # Handle warnings
        message(paste("Warning in group", group, ":", w$message))
        invokeRestart("muffleWarning")
    }, error = function(e) {
        # Handle errors
        message(paste("Error in group", group, ":", e$message))
        writeLines(paste(Sys.time(), "Error:", e$message), con = log_path)
    })

    # Save results and log execution time
    saveRDS(group_results, file = result_path)
    writeLines(paste("Execution time:", difftime(Sys.time(), start_time, units = "mins")), con = log_path)

    # Plot results if available
    if (!is.null(group_results)) {
        pdf(plot_path)
        plot(group_results, pch = 16, cex = 0.7)
        dev.off()
    }
    
    return(group_results)
}

# Prepare feature locations function; helper function
prepareLocationsForMatrixEQTL <- function(data) {
  data <- tibble::rownames_to_column(data, var = "feature_id")
  result <- data %>%
    dplyr::select(feature_id, seqnames, start, end)
    return(result)
}

runMatrixEQTL <- function(summarizedExp, resultsDir, matrixName, snpFilePath, snpLocPath, covFilePath, groupColName, sampleColName = "Cluster",  topNrows = NULL, groupSubset = NULL) {
  # Load necessary packages
  if (!requireNamespace("MatrixEQTL", quietly = TRUE)) {
    stop("Package 'MatrixEQTL' is needed but not installed.")
  }

  # Argument checks
  if (!inherits(summarizedExp, "SummarizedExperiment")) {
    stop("summarizedExp must be a SummarizedExperiment object.")
  }

  if (!matrixName %in% names(assays(summarizedExp))) {
    stop(paste("Matrix", matrixName, "not found in SummarizedExperiment object."))
  }

  if (!groupColName %in% names(colData(summarizedExp))) {
    stop(paste("groupColName", groupColName, "not found in colData of the SummarizedExperiment."))
  }

  if (!sampleColName %in% names(colData(summarizedExp))) {
    stop(paste("groupColName", groupColName, "not found in colData of the SummarizedExperiment."))
  }

  if (!file.exists(snpFilePath) || !file.exists(snpLocPath) || !file.exists(covFilePath)) {
    stop("One or more files specified do not exist.")
  }

  # SNP Data
  SNPs_sliced <- SlicedData$new()
  SNPs_sliced$fileDelimiter <- "\t"
  SNPs_sliced$fileOmitCharacters <- "NA"
  SNPs_sliced$fileSkipRows <- 1
  SNPs_sliced$fileSkipColumns <- 1
  SNPs_sliced$fileSliceSize <- 2000
  SNPs_sliced$LoadFile(snpFilePath)

  SNPs_locations <- read.table(snpLocPath, header = TRUE)

  # Covariate Data
  COV_sliced <- SlicedData$new()
  COV_sliced$fileDelimiter <- "\t"
  COV_sliced$fileOmitCharacters <- "NA"
  COV_sliced$fileSkipRows <- 1
  COV_sliced$fileSkipColumns <- 1
  COV_sliced$fileSliceSize <- 2000
  COV_sliced$LoadFile(covFilePath)

  if (!is.null(groupSubset)) {
    cat("Subsetting SE.\n")
    summarizedExp <- summarizedExp[ , colData(summarizedExp)[[groupColName]] %in% groupSubset]
  }

  se_sample_ids <- unique(colData(summarizedExp)[[sampleColName]])
  se_sample_data <- colData(summarizedExp)[[sampleColName]]

  group_data <- colData(summarizedExp)[[groupColName]]
  groups_to_process <- unique(group_data)

  cat("Sample IDs in SE:", se_sample_ids, "\n")

  snp_sample_ids <- SNPs_sliced$columnNames
  cov_sample_ids <- COV_sliced$columnNames

  if (!all(snp_sample_ids == cov_sample_ids)) {
    stop("Sample IDs not matching.")
  }

  cat("Found ", length(snp_sample_ids), " sample IDs in the provided SNP matrix.\n")

  # common samples between groups
  common_samples <- intersect(se_sample_ids, snp_sample_ids)

  if (length(common_samples) / length(se_sample_ids) < 0.5) {
    warning("Less than 50% of the sample IDs in the SE object match those in the SNP file.")
  } 

  cat("Matched sample IDs:", common_samples, "(", length(common_samples), " out of ", length(se_sample_ids), ")\n")
  
  # Run analysis for each group
  results <- lapply(groups_to_process, runGroupEQTL, 
                      group_data = group_data, se_sample_ids = se_sample_ids, se_sample_data = se_sample_data,
                      summarizedExp = summarizedExp, SNPs_sliced = SNPs_sliced, 
                      topNrows = topNrows, snp_locations = SNPs_locations, 
                      feature_locations = feature_locations, resultsDir = resultsDir, common_samples = common_samples, matrixName = matrixName)

  names(results) <- groups_to_process
  return(results)
}
# add argument seurat_obj that could be used instead of SE argument. Then matrix name will be the surta object slot (e.g., RNA, SCT, etc.)

res_pilot <- runMatrixEQTL(summarizedExp = pms, resultsDir = "first_run_dir", matrixName = "PeakMatrix", 

snpFilePath = "/proj/sllstore2017078/private/lech_rackham/scAnalysis_rackham/QTL_analysis/atac_QTL/data/SNPs_VK_fixed_colnames_toy.txt", 

snpLocPath = "/proj/sllstore2017078/private/lech_rackham/scAnalysis_rackham/QTL_analysis/atac_QTL/data/snpsloc_fixed_chr_names.txt", 

covFilePath = "/proj/sllstore2017078/private/lech_rackham/scAnalysis_rackham/QTL_analysis/atac_QTL/data/COV_VK_fixed_colnames.txt", 

groupColName = "Sample", topNrows = 1000, groupSubset = c("1","2"))