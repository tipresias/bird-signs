# We don't need to install any tidyverse packages, because they are included
# in the rocker/tidyverse base image along with devtools.
install.packages(
  c(
    "future",
    "plumber",
    "wdman", # Required for RSelenium
    "RSelenium",
    "here",
    "RCurl",
    quiet = TRUE,
    verbose = FALSE
  ),
)

# Installing via git rather than github to avoid unauthenticated API
# rate limits in CI
devtools::install_git("git://github.com/cfranklin11/fitzRoy.git", quiet = TRUE, branch = "fix/2020-rounds")

# Dev environment packages
install.packages(c("roxygen2", "testthat"), quiet = TRUE, verbose = FALSE)
