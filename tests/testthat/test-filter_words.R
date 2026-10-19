source(test_path("..", "..", "app", "R", "filter_words.R"))

words <- data.frame(word = c("sleep", "spell", "steel", "smell", "sheet", "arise", "elbow"))

filtered <- function(...) filter_words(words, ...)$word

test_that("parse_letters normalises input", {
  expect_equal(parse_letters(" A,b c a1 "), c("a", "b", "c"))
  expect_equal(parse_letters(""), character())
  expect_equal(parse_letters(NULL), character())
})

test_that("no clues keeps everything", {
  expect_equal(filtered(), words$word)
})

test_that("greens fix letters at positions", {
  expect_equal(filtered(greens = c("s", "", "", "", "l")), c("spell", "steel", "smell"))
})

test_that("yellows require the letter elsewhere", {
  yellows <- list(character(), character(), character(), character(), "l")
  expect_equal(filtered(yellows = yellows), c("sleep", "elbow"))
})

test_that("excluded letters are removed", {
  expect_equal(filtered(excluded = c("e")), character())
  expect_equal(filtered(excluded = c("p", "t")), c("smell", "arise", "elbow"))
})

test_that("excluded + green means no extra copies", {
  # Green L at 5, grey L elsewhere: exactly one L
  greens <- c("", "", "", "", "l")
  expect_equal(filtered(greens = greens, excluded = "l"), "steel")
})

test_that("excluded + yellow means exactly one copy", {
  yellows <- list("e", character(), character(), character(), character())
  expect_equal(filtered(yellows = yellows, excluded = "e"), c("spell", "smell", "arise"))
})

test_that("check_clues flags contradictions", {
  yellows <- list(character(), "e", character(), character(), character())
  expect_length(check_clues(c("", "e", "", "", ""), yellows), 1)
  all_yellow <- rep(list("a"), 5)
  expect_match(check_clues(rep("", 5), all_yellow), "No open position")
  expect_length(check_clues(rep("", 5), vector("list", 5)), 0)
})

test_that("score_words prefers letters that split candidates", {
  s <- score_words(c("aaaab", "aaaac", "ddddb"))
  expect_length(s, 3)
  expect_equal(score_words(character()), numeric())
})
