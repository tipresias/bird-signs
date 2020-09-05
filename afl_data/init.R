# We don't need to install any tidyverse packages, because they are included
# in the rocker/tidyverse base image along with devtools.
install.packages(
  c(
    "future",
    "plumber",
    "here",
    "RCurl",
    quiet = TRUE,
    verbose = FALSE
  ),
)

# Installing via git rather than github to avoid unauthenticated API
# rate limits in CI
devtools::install_git("git://github.com/jimmyday12/fitzRoy.git", quiet = TRUE)

# Dev environment packages
install.packages(c("roxygen2", "testthat"), quiet = TRUE, verbose = FALSE)
