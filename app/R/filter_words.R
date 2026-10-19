# Wordle-style filtering and ranking of the 5-letter word list.
#
# Clues are expressed per position:
#   greens   character(5): the known letter at each position ("" if unknown)
#   yellows  list of 5 character vectors: letters that are in the word but
#            known NOT to be at that position
#   excluded character vector: letters marked grey ("not in word")
#
# Duplicate letters follow Wordle rules: a letter that is grey but also
# green/yellow means the word has no *extra* copies of it, i.e. it appears
# exactly as many times as the green/yellow clues require.

WORD_LENGTH <- 5L

# Normalise free text to a vector of unique lowercase letters.
parse_letters <- function(x) {
  if (is.null(x) || length(x) == 0 || is.na(x[1])) return(character())
  unique(strsplit(gsub("[^a-z]", "", tolower(x[1])), "")[[1]])
}

# n x 5 character matrix with one letter per cell.
word_letter_matrix <- function(words) {
  matrix(unlist(strsplit(words, ""), use.names = FALSE),
         ncol = WORD_LENGTH, byrow = TRUE)
}

# Minimum number of times each green/yellow letter must appear.
min_letter_counts <- function(greens, yellows) {
  green_letters <- greens[nzchar(greens)]
  yellow_letters <- unique(unlist(yellows, use.names = FALSE))
  known <- union(green_letters, yellow_letters)
  vapply(known, function(l) {
    max(sum(green_letters == l), as.integer(l %in% yellow_letters))
  }, integer(1))
}

filter_words <- function(df, greens = rep("", WORD_LENGTH),
                         yellows = vector("list", WORD_LENGTH),
                         excluded = character(),
                         letter_matrix = word_letter_matrix(df$word)) {
  greens[is.na(greens)] <- ""
  m <- letter_matrix
  keep <- rep(TRUE, nrow(m))

  for (p in seq_len(WORD_LENGTH)) {
    if (nzchar(greens[[p]])) keep <- keep & m[, p] == greens[[p]]
    for (l in yellows[[p]]) keep <- keep & m[, p] != l
  }

  min_counts <- min_letter_counts(greens, yellows)
  for (l in names(min_counts)) {
    n <- rowSums(m == l)
    keep <- keep & n >= min_counts[[l]]
    if (l %in% excluded) keep <- keep & n <= min_counts[[l]]
  }

  for (l in setdiff(excluded, names(min_counts))) {
    keep <- keep & rowSums(m == l) == 0
  }

  df[keep, , drop = FALSE]
}

# Human-readable problems with the clues (contradictions that guarantee
# zero candidates). Returns a character vector, empty if all is well.
check_clues <- function(greens, yellows) {
  msgs <- character()
  for (p in seq_len(WORD_LENGTH)) {
    if (nzchar(greens[[p]]) && greens[[p]] %in% yellows[[p]]) {
      msgs <- c(msgs, sprintf(
        "'%s' is both the green letter and a wrong-spot letter at position %d.",
        toupper(greens[[p]]), p
      ))
    }
  }
  free <- which(!nzchar(greens))
  for (l in unique(unlist(yellows, use.names = FALSE))) {
    banned <- which(vapply(yellows, function(y) l %in% y, logical(1)))
    if (!l %in% greens && length(setdiff(free, banned)) == 0) {
      msgs <- c(msgs, sprintf("No open position left for '%s'.", toupper(l)))
    }
  }
  msgs
}

# Rank words by how well they split the remaining candidates: each distinct
# letter scores p * (1 - p), where p is the share of candidates containing it.
# Letters every candidate already has (or none has) add nothing.
score_words <- function(words) {
  if (length(words) == 0) return(numeric())
  letter_sets <- lapply(strsplit(words, ""), unique)
  p <- table(unlist(letter_sets)) / length(words)
  split_value <- p * (1 - p)
  vapply(letter_sets, function(ls) sum(split_value[ls]), numeric(1))
}
