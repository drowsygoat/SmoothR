#' Run Group eQTL Analysis
#'
#' This function performs eQTL analysis for a specified group using SNP and gene expression data across different statistical models. It handles both cis and trans eQTLs and allows for comprehensive output management including saving results to specified paths and optional result plotting.
#'
#' @param feature_locations_path String; path to the file containing genomic feature locations.
#' @param feature_data_path String; path to the file containing feature data.
#' @param snpFilePath String; path to the file containing SNP data.
#' @param covFilePath String; path to the file containing covariate data.
#' @param snpLocPath String; path to the file containing SNP locations.
#' @param group_name String; name of the group being analyzed.
#' @param resultsDir String; directory to store results files, defaults to the current working directory.
#' @param cisDist Numeric; maximum distance for considering cis interactions, default is 1e6 (1 million bases).
#' @param pvOutputThreshold Numeric; p-value output threshold for trans eQTLs, default is 1e-5.
#' @param pvOutputThresholdCis Numeric; p-value output threshold for cis eQTLs, default is 1e-4.
#' @param useModel String; statistical model used for the analysis ('linear', 'anova', 'cross'). Default is 'linear'.
#' @param minPvByGeneSnp Logical; if TRUE, the minimum p-value by gene-SNP pair will be reported.
#' @param noFDRsaveMemory Logical; if TRUE, FDR calculation will not save memory usage.
#' @param pvalueHist String; type of p-value histogram to produce ('qqplot', 'histogram', etc.).
#' @param SNPsInChunks Logical; indicates if SNP data are in chunks and require specific handling.
#' @param prefix Nullable String; additional prefix for output files, helps in identifying files when running multiple models.
#'
#' @return Logical TRUE if the function executes successfully, otherwise it logs an error and stops.
#' @export
#'
#' @examples
#' matrixEQTLwrapper(
#'   feature_locations_path = "path/to/features.rds",
#'   feature_data_path = "path/to/feature_data.rds",
#'   snpFilePath = "path/to/snps.rds",
#'   covFilePath = "path/to/covariates.txt",
#'   snpLocPath = "path/to/snp_locations.txt",
#'   group_name = "group_cluster1",
#'   resultsDir = "path/to/results"
#' )

matrixEQTLwrapper <- function(feature_locations_path = NULL, feature_data_path = NULL, snpFilePath = NULL, covFilePath, snpLocPath = NULL, group_name, resultsDir = getwd(), cisDist = 1e6, pvOutputThreshold = 1e-5, pvOutputThresholdCis = 1e-4, useModel = "linear", minPvByGeneSnp = TRUE, noFDRsaveMemory = FALSE, pvalueHist = "qqplot", SNPsInChunks = NULL, prefix = NULL) {
    
    if (is.null(prefix)) {
        prefix <- paste(useModel, cisDist, sep = "_")
    } else {
        prefix <- paste(useModel, cisDist, prefix, sep = "_")
    }

    subdir_name <- group_name # dir variable from fork

    group_name <- gsub("group_|_results", "", group_name)

    # grep_o is from SmoothR
    chunk_snp <- grep_o(snpFilePath, "chunk_[0-9]+")
    chunk_feature <- grep_o(feature_data_path, "chunk_[0-9]+")

    print(feature_locations_path)
    feature_locations <- readRDS(feature_locations_path)

    print(feature_data_path)
    feature_data <- readRDS(feature_data_path)

    COV_sliced <- SlicedData$new()
    COV_sliced$fileDelimiter <- "\t"
    COV_sliced$fileOmitCharacters <- "NA"
    COV_sliced$fileSkipRows <- 1
    COV_sliced$fileSkipColumns <- 1
    COV_sliced$fileSliceSize <- 2000
    COV_sliced$LoadFile(covFilePath)

    if (COV_sliced$nRows() > feature_data$nCols()) {
        stop("More covariates than samples.")
    }

        # Determine the model based on the input
    if (useModel == "linear") {
        useModel <- modelLINEAR
    } else if (useModel == "anova") {
        useModel <- modelANOVA
    } else if (useModel == "cross") {
        useModel <- modelLINEAR_CROSS
    } else {
        stop("'useModel' must be one of 'linear', 'cross', or 'anova'")
    }


    prefix <- paste(chunk_snp, chunk_feature, prefix, sep = "_")
    
    SNPs_sliced <- SlicedData$new()
    SNPs_sliced$fileDelimiter <- "\t"
    SNPs_sliced$fileOmitCharacters <- "NA"
    SNPs_sliced$fileSkipRows <- 1
    SNPs_sliced$fileSkipColumns <- 1
    SNPs_sliced$fileSliceSize <- 2000
    SNPs_sliced$LoadFile(snpFilePath)

    if (length(feature_data$columnNames) > length(SNPs_sliced$columnNames)) {
        stop("More samples in features data than in SNP data")
    }
    
    print("1")

    if (!check_complete_match(SNPs_sliced$columnNames, feature_data$columnNames)) {
        print("2")
        message("Reordering/subsetting SNP and COV data based on samples")
        sample_to_keep_from_genomic_data <- sort(which(sapply(SNPs_sliced$columnNames, check_match, group_name_vector = feature_data$columnNames)))
        SNPs_sliced$ColumnSubsample(sample_to_keep_from_genomic_data)
        COV_sliced$ColumnSubsample(sample_to_keep_from_genomic_data)
    }

    snp_locations <- read.table(snpLocPath, header = TRUE)

    # Output paths
    output_file_name_trans <- file.path(resultsDir, subdir_name, paste(subdir_name, tolower(prefix), "eQTL_trans.txt", sep = "_"))
    output_file_name_cis <- file.path(resultsDir, subdir_name, paste(subdir_name, tolower(prefix), "eQTL_cis.txt", sep = "_"))
    result_path <- file.path(resultsDir, subdir_name, paste(subdir_name, tolower(prefix), "results_MEQTL.rds", sep = "_")) 
    log_path <- file.path(resultsDir, subdir_name, paste(subdir_name, tolower(prefix), "MEQTL_runtime_log.txt", sep = "_"))

    log_con <- file(log_path, open = "a")
    on.exit(close(log_con))

    start_time <- Sys.time()
    writeLines(paste(Sys.time(), "Started logging...:"), log_con)

        tryCatch(
            withCallingHandlers({
                # Run Matrix eQTL analysis
                result <- Matrix_eQTL_main(
                    snps = SNPs_sliced,
                    gene = feature_data,
                    cvrt = COV_sliced,
                    output_file_name = output_file_name_trans,
                    pvOutputThreshold = pvOutputThreshold,
                    useModel = useModel,
                    errorCovariance = numeric(0),
                    output_file_name.cis = output_file_name_cis,
                    pvOutputThreshold.cis = pvOutputThresholdCis,
                    snpspos = snp_locations,
                    genepos = feature_locations,
                    cisDist = cisDist,
                    pvalue.hist = pvalueHist,
                    min.pv.by.genesnp = minPvByGeneSnp,
                    noFDRsaveMemory = noFDRsaveMemory,
                    verbose = TRUE
                )
                # Log the results
                end_time <- Sys.time()
                duration <- end_time - start_time
                message(sprintf("MatrixEQTL completed in %s seconds.", duration), file = log_con)

                result <- list(result=result,
                            feature_data_path = feature_data_path,
                            feature_locations_path = feature_locations_path,
                            snpFilePath = snpFilePath,
                            covFilePath = covFilePath,
                            snpLocPath = snpLocPath)
                            
                # Save results 
                saveRDS(result, file = result_path)

                print("Data saved...")

                # compress lists
                gzip(output_file_name_cis, destname = paste0(output_file_name_cis, ".gz"), remove = TRUE)

                gzip(output_file_name_trans, destname =  paste0(output_file_name_trans, ".gz"), remove = TRUE)
                
                print("Data compressed...")

            return(TRUE)

            }, warning = function(w) {
                writeLines(paste(Sys.time(), "Warning:", w$message), log_con)
                invokeRestart("muffleWarning")
            }, error = function(e) {
                writeLines(paste(Sys.time(), "Error:", e$message), log_con)
                stop(e)
            })
        )
}

#' Check for Partial Matches in Vector
#'
#' This function checks if any part of a given sample name appears in any of the elements
#' of a vector of group names. It returns TRUE if any match is found, otherwise FALSE.
#'
#' @param sample_name Character; a single string to look for within group_name_vector.
#' @param group_name_vector Character vector; vector within which to search for sample_name.
#'
#' @return Logical; TRUE if there is any match, otherwise FALSE.
#' @keywords internal
check_match <- function(sample_name, group_name_vector) {
    any(sapply(group_name_vector, function(x) grepl(sample_name, x)))
}

#' Check Complete Matches for All Elements
#'
#' This function verifies whether all elements of sample_name_vector find a match
#' in group_name_vector using the check_match function. It returns TRUE if all elements match,
#' otherwise FALSE.
#'
#' @param sample_name_vector Character vector; strings to match against group_name_vector.
#' @param group_name_vector Character vector; vector within which to search for each element of sample_name_vector.
#'
#' @return Logical; TRUE if all elements from sample_name_vector match any element in group_name_vector, otherwise FALSE.
#' @keywords internal
check_complete_match <- function(sample_name_vector, group_name_vector) {
   all(sapply(sample_name_vector, check_match, group_name_vector = group_name_vector))
}
