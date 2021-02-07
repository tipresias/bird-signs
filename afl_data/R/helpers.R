convert_to_snake_case <- function(string) {
  string %>% stringr::str_to_lower() %>% stringr::str_replace_all("\\.", "_")
}