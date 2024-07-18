# Use roxygen comments above your function to document it
#' Normalize Peak Matrix by Column
#'
#' This function normalizes a peak matrix within a SummarizedExperiment object
#' by a specified column from `colData`.
#'
#' @param x A `SummarizedExperiment` object.
#' @param norm_col_name The name of the column in `colData` used for normalization.
#' @param test Optional integer to subset the matrix for testing.
#'
#' @return Returns a normalized matrix, or a list of matrices if testing.
#' @export
#' @examples
#' seRNA <- SummarizedExperiment::SummarizedExperiment(assays = list(PeakMatrix = matrix))
#' normalize_peak_matrix_by_col(seRNA, "norm_factor")
normalize_peak_matrix_by_col <- function(x, norm_col_name, test = NULL, scale = FALSE, ...) {
    # Extract sparse matrix and colData, converting colData to data.table for efficiency
    sparse_matrix <- assays(x)[["PeakMatrix"]]

    if (!inherits(sparse_matrix, "dgCMatrix")) {
        sparse_matrix <- as(sparse_matrix, "dgCMatrix")
    }

    col_data <- as.data.table(SummarizedExperiment::colData(x))

    # Check if the normalization column exists in colData
    if (!norm_col_name %in% names(col_data)) {
        stop("Normalization column not found in colData.")
    }

    # Extract normalization factors and check for zeros
    normalization_factors <- col_data[[norm_col_name]]
    if (any(normalization_factors == 0)) {
        stop("Normalization factors include zero, which would lead to division by zero.")
    }

    if (!is.null(test)) {
        # Randomly sample 1000 rows and columns if the matrix is large enough
        sample_size <- min(test, nrow(sparse_matrix), ncol(sparse_matrix))
        rows <- sample(nrow(sparse_matrix), sample_size)
        cols <- sample(ncol(sparse_matrix), sample_size)
        
        # Subset the matrix and normalization factors
        sparse_matrix <- sparse_matrix[rows, cols]
        normalization_factors <- normalization_factors[cols]
    }

    num_cores <- detectCores() / 2  # Using half of available cores

    a <-  Sys.time()

    # Normalize each column in parallel using mclapply
    normalized_matrix <- mclapply(1:ncol(sparse_matrix), function(col_idx) {
        col <- sparse_matrix[, col_idx, drop = FALSE]  # Keep it as a sparse matrix column
        indices <- which(col@x != 0)  # Extract indices where the entries are not zero
        values <- col@x[indices]  # Extract the non-zero values directly
        # values <- signif(values / normalization_factors[col_idx], digits = 3)
        values <- values / normalization_factors[col_idx]

        col@x[indices] <- values
        return(col)
    }, mc.cores = num_cores)
    
    b <-  Sys.time()
    print(paste("Runtime:", b-a))
       
    a <-  Sys.time()

    chunk_size = floor(sqrt(length(normalized_matrix)))
    # Split the list of columns into chunks
    column_chunks <- split(normalized_matrix, ceiling(seq_along(normalized_matrix) / chunk_size))

    # Combine each chunk using do.call with cbind
    combined_chunks <- mclapply(column_chunks, function(chunk) {
    do.call(cbind, chunk)
    }, mc.cores = num_cores)

    # Finally combine all chunks
    normalized_matrix_1 <- do.call(cbind, combined_chunks)

    b <-  Sys.time()
    print(paste("Runtime:", b-a))

    if(!is.null(test)){

        output <- list(sparse_matrix, normalized_matrix_1)

        if (scale) {
            scaled_output <- lapply(output, t)
            scaled_output <- lapply(scaled_output, scale, ...)
            scaled_output <- lapply(scaled_output, t)
            return(scaled_output)

        }

        return(output)

    }
    
    if (scale) {
        scaled_output <- t(sparse_matrix)
        scaled_output <- scale(scaled_output, ...)
        scaled_output <- t(scaled_output, t)
        return(scaled_output)

    output <- sparse_matrix
    return(output)
    }

}