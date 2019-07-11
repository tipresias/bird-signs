# Suppressing all messages during installation, because R is excessive,
# and it overloads the CI logs

# store a copy of system2
assign("system2.default", base::system2, baseenv())

# create a quiet version of system2
assign(
  "system2.quiet",
  function(...)system2.default(..., stdout = FALSE, stderr = FALSE),
  baseenv()
)

# overwrite system2 with the quiet version
assignInNamespace("system2", system2.quiet, "base")

# this is now message-free:
res <- eval(suppressMessages(install_github('ROAUth', 'duncantl')))

install.packages("devtools")

install.packages("BH")
install.packages("dplyr")
install.packages("plogr")
install.packages("plumber")
install.packages("progress")
install.packages("purrr")
install.packages("rvest")
install.packages("stringr")

# Installing via git rather than github to avoid unauthenticated API
# rate limits in CI
devtools::install_git("git://github.com/jimmyday12/fitzRoy.git")
# Only using master-branch install to get new pivot_wider function.
# Can switch back to CRAN once that gets released
devtools::install_git("git://github.com/tidyverse/tidyr.git")

install.packages("roxygen2")
install.packages("testthat")

# reset system2 to its original version
assignInNamespace("system2", system2.default, "base")
