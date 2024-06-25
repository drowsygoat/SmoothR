#' A case-insensitive intersect.
#'
#' @return A character vector.
#' @examples
#' lowersect(c("A", "B", "C"), c("a", "B", "D"))
#' @export
lowersect <- function(vec1, vec2) {
  vec1_lower <- tolower(vec1)
  vec2_lower <- tolower(vec2)
  common_elements <- intersect(vec1_lower, vec2_lower)
  original_case_common <- vec1[vec1_lower %in% common_elements]
  return(original_case_common)
}