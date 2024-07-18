library(stringr)

#' Convert Cell IDs to ArchR Format
#'
#' This function takes a vector of cell IDs and converts them into a specific format
#' required by ArchR. It handles the prefix transformation and ensures that numeric
#' parts of the ID are formatted with two leading zeros. This function requires
#' the \code{\link[stringr]{str_replace}} function from the \pkg{stringr} package.
#'
#' @param cell_ids A character vector of cell IDs to be converted.
#' @return A character vector of transformed cell IDs in ArchR format.
#' @examples
#' IDsToArchR(c("samp_123_cell", "samp_2_cell"))
#' @importFrom stringr str_replace str_extract
#' @export
IDsToArchR <- function(cell_ids) {
  # Initial prefix transformation
  cell_ids <- str_replace(cell_ids, "^samp_", "id_")
  
  # Combine numeric transformation and formatting into one step
  cell_ids <- str_replace(cell_ids, "^id_([0-9]+)", function(x) {
    num <- as.numeric(str_extract(x, "[0-9]+"))
    sprintf("id_%02d#", num)
  })
  
  return(cell_ids)
}