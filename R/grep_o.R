#' Extract Matching Strings Similar to grep -o in Bash
#'
#' This function performs a pattern matching operation similar to the `grep -o` command in Bash,
#' returning only the parts of strings that match the specified pattern. It works across a vector
#' of strings and returns a vector of all matches found.
#'
#' @param strings A character vector of strings to search within.
#' @param pattern A character string containing a regular expression to be matched in the `strings`.
#'
#' @return A character vector of all substrings that match the pattern.
#' @export
#'
#' @examples
#' texts <- c("apple pie", "banana split", "blueberry muffin", "strawberry cake")
#' grep_o(texts, "berry")
grep_o <- function(strings, pattern) {
  match_positions <- gregexpr(pattern, strings)
  matches <- regmatches(strings, match_positions)
  matches <- unlist(matches, use.names = FALSE)
  return(matches)
}