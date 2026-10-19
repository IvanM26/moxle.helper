# Moxle Helper

A [Shinylive](https://posit-dev.github.io/r-shinylive/) app for narrowing down
Moxle answers, using 5-letter words from Magic: The Gathering card text. The app runs
entirely in the browser (webR), so it can be hosted as a static site.

## Layout

```
data-raw/                 preprocessing (not shipped with the app)
  build_word_list.R       Scryfall bulk JSONL -> app/data/five_letter_words.rds
  oracle-cards-*.jsonl.gz Scryfall "Oracle Cards" bulk download
app/                      the Shiny app (everything here is bundled by Shinylive)
  app.R                   UI + server
  R/filter_words.R        filtering / ranking logic (auto-sourced by Shiny)
  data/five_letter_words.rds
  www/                    CSS and JS
tests/testthat/           unit tests for the filtering logic
```

## Using the app

- **Top row (green):** letters you know are in the right position.
- **Below each tile (yellow):** letters that are in the word but *not* at that
  position. Type several letters if needed (e.g. `EL`).
- **Not in the word (grey):** letters that don't appear.

If a letter is grey *and* green/yellow (for example, you guessed a word with two E's and
one came back grey), the app treats it as "no extra copies", following Wordle rules.

Candidates sort either alphabetically or by **best guess**, which ranks words by
how evenly their letters split the remaining candidates.

## Development

```sh
# 1. Rebuild the word list (only needed when the Scryfall dump changes).
#    Download "Oracle Cards" from https://scryfall.com/docs/api/bulk-data into
#    data-raw/ (git-ignored); the newest oracle-cards-*.jsonl.gz is used.
Rscript data-raw/build_word_list.R

# 2. Run tests
Rscript -e 'testthat::test_dir("tests/testthat")'

# 3. Run the app locally
Rscript -e 'shiny::runApp("app", port = 3838)'

# 4. Build and preview the static Shinylive site
Rscript -e 'shinylive::export("app", "site")'
Rscript -e 'httpuv::runStaticServer("site", port = 8000)'
```

Pushing to `main` builds the site and deploys it to GitHub Pages
(`.github/workflows/deploy.yml`). To enable it, set Pages to use "GitHub Actions" in the repo settings.
