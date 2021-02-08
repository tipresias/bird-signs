convert_to_snake_case <- function(string) {
  string %>% stringr::str_to_lower() %>% stringr::str_replace_all("\\.", "_")
}

is_empty <- function(data_frame) {
  nrow(data_frame) == 0
}
