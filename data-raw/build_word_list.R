# Build the 5-letter word list used by the Moxle helper app.
#
# Input:  the most recent Scryfall "Oracle Cards" bulk file in data-raw/
#         (oracle-cards-*.jsonl.gz, https://scryfall.com/docs/api/bulk-data)
# Output: app/data/five_letter_words.rds, a data frame with columns
#           word               lowercase 5-letter word
#           n_distinct_letters number of distinct letters
#           n_distinct_vowels  number of distinct vowels (a, e, i, o, u)
#
# Run from the project root:  Rscript data-raw/build_word_list.R

library(jsonlite)

raw_path <- sort(list.files("data-raw", "^oracle-cards-.*\\.jsonl\\.gz$", full.names = TRUE),
                 decreasing = TRUE)[1]
if (is.na(raw_path)) stop("No oracle-cards-*.jsonl.gz file found in data-raw/")
out_path <- file.path("app", "data", "five_letter_words.rds")

message("Reading ", raw_path)
con <- gzfile(raw_path, open = "rt")
cards <- stream_in(con, verbose = FALSE)
close(con)

cards_en <- cards[cards$lang == "en", ]

# Multi-faced cards (transform, MDFC, adventure, ...) keep their text in
# `card_faces` rather than in the top-level columns, so pull it from there too.
face_text <- vapply(cards_en$card_faces, function(faces) {
  if (is.null(faces) || !is.data.frame(faces)) return("")
  cols <- intersect(c("name", "oracle_text", "flavor_text"), names(faces))
  paste(unlist(faces[cols]), collapse = " ")
}, character(1))

text_combined <- paste(
  cards_en$name,
  cards_en$oracle_text,
  cards_en$flavor_text,
  face_text,
  sep = " "
)

words <- unlist(regmatches(text_combined, gregexpr("[A-Za-z]+", text_combined)))
words <- tolower(words[nchar(words) == 5])
words <- sort(unique(words))

letters_of <- strsplit(words, "")

five_letter_words <- data.frame(
  word = words,
  n_distinct_letters = vapply(letters_of, function(x) length(unique(x)), integer(1)),
  n_distinct_vowels = vapply(letters_of, function(x) length(unique(x[x %in% c("a", "e", "i", "o", "u")])), integer(1)),
  stringsAsFactors = FALSE
)

dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
saveRDS(five_letter_words, out_path)

message(sprintf("Saved %d five-letter words to %s", nrow(five_letter_words), out_path))
