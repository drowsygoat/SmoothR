#' Subset a SummarizedExperiment Object
#'
#' This function subsets a SummarizedExperiment object based on metadata criteria
#' and/or random sampling of rows and columns.
#'
#' @param SE A SummarizedExperiment object.
#' @param nrow Optional; the number of rows to randomly sample from the SE object.
#'             If more than the available rows, all rows are used.
#' @param ncol Optional; the number of columns to randomly sample from the SE object.
#'             If more than the available columns, all columns are used.
#' @param byCol Optional; a vector where the first element is the name of the column
#'              in 'colData' used for subsetting, followed by values to filter by.
#'              Only character subsetting is supported.
#'
#' @return A subsetted SummarizedExperiment object.
#' @export
#'
#' @examples
#' \dontrun{
#'   # Assuming `se` is your SummarizedExperiment object
#'   subset_se <- subsetSE(se, nrow = 100, ncol = 50, byCol = c("condition", "treated", "control"))
#' }
subsetSE <- function(SE, nrow = NULL, ncol = NULL, byCol = NULL) {
  # Validate input
  if (!inherits(SE, "SummarizedExperiment")) {
    stop("The first argument must be a SummarizedExperiment object.")
  }
  
  # Handle column subsetting by metadata criteria
  if (!is.null(byCol) && length(byCol) > 1) {
    col_name <- byCol[1]
    values_to_keep <- byCol[-1]
    if (!col_name %in% colnames(colData(SE))) {
      stop("Column name provided in 'byCol' does not exist in 'colData' of the SummarizedExperiment.")
    }
    col_indices <- colData(SE)[[col_name]] %in% values_to_keep
    if (sum(col_indices) == 0) {
      stop("No columns match the criteria in 'byCol'.")
    }
    SE <- SE[, col_indices, drop = FALSE]
  }

  # Random subsetting of columns if ncol is specified after byCol filtering
  if (!is.null(ncol) && ncol < ncol(SE)) {
    col_indices <- sample(ncol(SE), ncol)
    SE <- SE[, col_indices, drop = FALSE]
  }

  # Random subsetting of rows if nrow is specified
  if (!is.null(nrow) && nrow < nrow(SE)) {
    row_indices <- sample(nrow(SE), nrow)
    SE <- SE[row_indices, , drop = FALSE]
  }

  # Return the subsetted object
  return(SE)
}