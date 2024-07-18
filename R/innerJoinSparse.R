#' Inner Join Two Sparse Matrices
#'
#' This function performs an inner join operation on two sparse matrices, returning
#' a combined matrix that contains only the rows and columns present in both input matrices.
#' It is specifically designed to work with matrices where both rows and columns can
#' be matched, typical in genomics data (e.g., gene expression matrices).
#'
#' @param matrix1 A sparse matrix object of class \code{\link[S4Vectors]{sparseMatrix}}.
#' @param matrix2 A sparse matrix object of class \code{\link[S4Vectors]{sparseMatrix}}.
#' @param verbose Logical; if TRUE, the function prints the number of common rows and columns found.
#'
#' @return Returns a sparse matrix containing the columns of both `matrix1` and `matrix2`
#' that have the same row names and column names, effectively binding the columns
#' of the two matrices together after subsetting to common rows and columns.
#'
#' @examples
#' # Load the Matrix package if not already loaded
#' if (!requireNamespace("Matrix", quietly = TRUE)) {
#'   install.packages("Matrix")
#'   library(Matrix)
#' }
#' # Create example sparse matrices
#' matrix1 <- Matrix::Matrix(c(0,0,2:0), 3, 5, sparse = TRUE,
#'                           dimnames = list(c("gene1", "gene2", "gene3"),
#'                                           c("sample1", "sample2", "sample3", "sample4", "sample5")))
#' matrix2 <- Matrix::Matrix(c(1,0,0:2), 3, 5, sparse = TRUE,
#'                           dimnames = list(c("gene1", "gene3", "gene4"),
#'                                           c("sample1", "sample3", "sample5", "sample6", "sample7")))
#' result <- innerJoinSparse(matrix1, matrix2, verbose = TRUE)
#' print(result)
#'
#' @importFrom Matrix sparseMatrix
#' @importMethodsFrom Matrix cBind
#' @export
innerJoinSparse <- function(matrix1, matrix2, verbose = FALSE) {
  # Check if the inputs are sparse matrices
  if (!is(matrix1, "sparseMatrix") || !is(matrix2, "sparseMatrix")) {
    stop("Both inputs must be sparse matrices")
  }

  # Get common row names (genes)
  common_rows <- intersect(rownames(matrix1), rownames(matrix2))
  if (verbose) cat("Number of common rows (genes):", length(common_rows), "\n")
  
  # Get common column names (samples/cells)
  common_cols <- intersect(colnames(matrix1), colnames(matrix2))
  if (verbose) cat("Number of common columns (samples/cells):", length(common_cols), "\n")
  
  # Subset matrices to only include common rows and columns
  matrix1_common <- matrix1[common_rows, common_cols, drop = FALSE]
  matrix2_common <- matrix2[common_rows, common_cols, drop = FALSE]
  
  # Ensure the matrices are in sparse format
  matrix1_common <- as(matrix1_common, "sparseMatrix")
  matrix2_common <- as(matrix2_common, "sparseMatrix")
  
  # Combine the matrices by binding columns
  combined_matrix <- cBind(matrix1_common, matrix2_common)
  
  return(combined_matrix)
}