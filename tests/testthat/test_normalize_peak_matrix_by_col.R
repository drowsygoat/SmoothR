test_that("Function executes without error", {
  data <- create_mock_summarized_experiment()  # Assume this is a helper to create mock data
  expect_s4_class(normalize_peak_matrix_by_col(data, "norm_factor"), "dgCMatrix")
})

test_that("Correct output type is returned", {
  data <- create_mock_summarized_experiment()  # Helper function for mock data
  result <- normalize_peak_matrix_by_col(data, "norm_factor", test = 10)
  expect_type(result, "list")
  expect_length(result, 2)
  dimensions <- lapply(result, dim)
  expect_identical(dimensions[[1]], dimensions[[2]])
})


# Helper function to create mock data
create_mock_summarized_experiment <- function() {
  library(SummarizedExperiment)
  library(Matrix)
  # Create a 50x50 sparse matrix
  sparse_matrix <- Matrix(0, 50, 50, sparse = TRUE)
  sparse_matrix[sample(length(sparse_matrix), 200, replace = FALSE)] <- runif(200)
  col_data <- DataFrame(norm_factor = runif(50, 1, 10))
  seRNA <- SummarizedExperiment(assays = list(PeakMatrix = sparse_matrix), colData = col_data)
  return(seRNA)
}

