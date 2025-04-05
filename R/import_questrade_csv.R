#' import_questrade_csv
#' Import a questrade trade confirmation format and manipulate the columns
#' for compatibility with the calculate_adjusted_cost_base() function
#' an example csv is included in the package for comparison.
#' @param path path to the questrade trade confirmations csv
#'
#' @return a tibble containing an imported csv that was
#' @export
#'
#' @examples
#' library(acb)
#' df_questrade <- acb::import_questrade_csv(system.file("extdata", "questrade_trade_confirmations.csv", package="acb"))
#' calculate_adjusted_cost_base(df_questrade)
import_questrade_csv <- function(path){

  df <- readr::read_csv(path)  %>%
    janitor::clean_names()  %>%
    dplyr::mutate(dplyr::across(.cols = c("trade_date", "settlement_date"),
                                .fns =  lubridate::dmy),
                  dplyr::across(.cols = c(  "gross_amount" , "comm", "net_amount", "net_amount_account_currency"),
                                .fns =  ~dplyr::if_else(stringr::str_detect(.x, "\\("),
                                                        -readr::parse_number(stringr::str_replace_all(.x, "[(),]", "")),
                                                        readr::parse_number(.x))
                  )
    ) %>%
    dplyr::rename(commission = comm)

  return(df)
}
