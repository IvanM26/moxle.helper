library(shiny)
library(bslib)

# Helpers in R/ are sourced automatically by Shiny.

words_df <- readRDS(file.path("data", "five_letter_words.rds"))
words_matrix <- word_letter_matrix(words_df$word)

MAX_SHOWN <- 500L
KEYBOARD_ROWS <- c("qwertyuiop", "asdfghjkl", "zxcvbnm")

letter_input <- function(id, class, placeholder = NULL, maxlength = NULL) {
  tags$input(
    id = id, type = "text", class = paste("form-control", class),
    maxlength = maxlength, placeholder = placeholder,
    autocomplete = "off", autocapitalize = "characters", spellcheck = "false"
  )
}

position_column <- function(i) {
  div(
    class = "position-col",
    div(class = "position-label", i),
    letter_input(paste0("green_", i), "tile tile-green", placeholder = " ", maxlength = 1),
    letter_input(paste0("yellow_", i), "tile-yellow", placeholder = "...")
  )
}

ui <- page_fluid(
  title = "Moxle Helper",
  theme = bs_theme(version = 5, primary = "#538d4e"),
  tags$head(
    tags$link(rel = "stylesheet", href = "styles.css"),
    tags$script(src = "tiles.js")
  ),
  h2("Moxle Helper", class = "my-3"),
  layout_columns(
    col_widths = breakpoints(sm = 12, lg = c(5, 7)),
    card(
      card_header("Clues"),
      card_body(
        p(class = "hint",
          span(class = "swatch swatch-green"), "Top row: letters in the right spot. ",
          span(class = "swatch swatch-yellow"), "Below: letters in the word but ",
          em("not"), " in that spot."),
        div(class = "board", lapply(seq_len(WORD_LENGTH), position_column)),
        div(
          class = "mt-3",
          tags$label(`for` = "excluded", class = "form-label",
                     span(class = "swatch swatch-grey"), "Not in the word"),
          letter_input("excluded", "excluded-input", placeholder = "e.g. CRANT")
        ),
        uiOutput("clue_warnings"),
        uiOutput("keyboard"),
        actionButton("reset", "Clear all", icon = icon("rotate-left"),
                     class = "btn-outline-secondary mt-2")
      )
    ),
    card(
      card_header(
        class = "d-flex justify-content-between align-items-center flex-wrap gap-2",
        textOutput("candidate_count", inline = TRUE),
        radioButtons("sort", NULL, inline = TRUE,
                     choices = c("Best guess" = "score", "A-Z" = "alpha"))
      ),
      card_body(uiOutput("candidates"))
    )
  )
)

server <- function(input, output, session) {
  greens <- reactive({
    vapply(seq_len(WORD_LENGTH), function(i) {
      l <- parse_letters(input[[paste0("green_", i)]])
      if (length(l) == 0) "" else l[1]
    }, character(1))
  })

  yellows <- reactive({
    lapply(seq_len(WORD_LENGTH), function(i) parse_letters(input[[paste0("yellow_", i)]]))
  })

  excluded <- reactive(parse_letters(input$excluded))

  candidates <- reactive({
    out <- filter_words(words_df, greens(), yellows(), excluded(),
                        letter_matrix = words_matrix)
    out$score <- score_words(out$word)
    if (input$sort == "score") {
      out[order(-out$score, out$word), , drop = FALSE]
    } else {
      out[order(out$word), , drop = FALSE]
    }
  })

  output$candidate_count <- renderText({
    n <- nrow(candidates())
    sprintf("%s candidate%s", format(n, big.mark = ","), if (n == 1) "" else "s")
  })

  output$candidates <- renderUI({
    cands <- candidates()
    n <- nrow(cands)
    if (n == 0) {
      return(p(class = "text-muted", "No words match these clues. Check for typos or contradictions."))
    }
    shown <- head(cands$word, MAX_SHOWN)
    chips <- lapply(seq_along(shown), function(i) {
      cls <- if (i == 1 && input$sort == "score" && n > 1) "word-chip top-pick" else "word-chip"
      span(class = cls, toupper(shown[i]))
    })
    tagList(
      if (input$sort == "score" && n > 1) {
        p(class = "hint", "Sorted by how well each word splits the remaining candidates.")
      },
      div(class = "word-list", chips),
      if (n > MAX_SHOWN) p(class = "text-muted mt-2", sprintf("...and %d more.", n - MAX_SHOWN))
    )
  })

  output$clue_warnings <- renderUI({
    msgs <- check_clues(greens(), yellows())
    if (length(msgs) == 0) return(NULL)
    div(class = "alert alert-warning mt-3 mb-0 py-2", lapply(msgs, div))
  })

  output$keyboard <- renderUI({
    green_set <- greens()[nzchar(greens())]
    yellow_set <- unlist(yellows())
    grey_set <- excluded()
    key_status <- function(l) {
      if (l %in% green_set) "key-green"
      else if (l %in% yellow_set) "key-yellow"
      else if (l %in% grey_set) "key-grey"
      else ""
    }
    div(
      class = "keyboard mt-3",
      lapply(KEYBOARD_ROWS, function(row) {
        div(class = "key-row", lapply(strsplit(row, "")[[1]], function(l) {
          span(class = paste("key", key_status(l)), toupper(l))
        }))
      })
    )
  })

  observeEvent(input$reset, {
    for (i in seq_len(WORD_LENGTH)) {
      updateTextInput(session, paste0("green_", i), value = "")
      updateTextInput(session, paste0("yellow_", i), value = "")
    }
    updateTextInput(session, "excluded", value = "")
  })
}

shinyApp(ui, server)
