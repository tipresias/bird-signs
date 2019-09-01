install.packages("devtools", quiet = TRUE, verbose = FALSE)

install.packages("BH", quiet = TRUE, verbose = FALSE)
install.packages("dplyr", quiet = TRUE, verbose = FALSE)
install.packages("future", quiet = TRUE, verbose = FALSE)
install.packages("plogr", quiet = TRUE, verbose = FALSE)
install.packages("plumber", quiet = TRUE, verbose = FALSE)
install.packages("progress", quiet = TRUE, verbose = FALSE)
install.packages("purrr", quiet = TRUE, verbose = FALSE)
install.packages("rvest", quiet = TRUE, verbose = FALSE)
install.packages("stringr", quiet = TRUE, verbose = FALSE)

# Installing via git rather than github to avoid unauthenticated API
# rate limits in CI
devtools::install_git("git://github.com/jimmyday12/fitzRoy.git", quiet = TRUE)
# Only using master-branch install to get new pivot_wider function.
# Can switch back to CRAN once that gets released
devtools::install_git("git://github.com/tidyverse/tidyr.git", quiet = TRUE)

install.packages("roxygen2", quiet = TRUE, verbose = FALSE)
install.packages("testthat", quiet = TRUE, verbose = FALSE)
