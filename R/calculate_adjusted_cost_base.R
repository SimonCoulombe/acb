
#' calculate adjusted cost base
#'
#' @param df
#'
#' @return a table containing the original df augmented with the share_balance, adjusted_cost_base and capital_gain columns
#' @export
#'
#' @examples
#' library(acb)
#' calculate_adjusted_cost_base(df_example)
calculate_adjusted_cost_base <- function(df){
  df <- df %>%
    dplyr::group_by(symbol) %>%
    dplyr::arrange(settlement_date, action, .by_group = TRUE) %>%  # Sort by date within each group.  sort by action so that we alwayas buy before selling on a given day.
    dplyr::mutate(
      # Step 2: Cumulative quantity (accounting for buy/sell)
      share_balance = cumsum(quantity * dplyr::if_else(tolower(action) == "buy", 1, -1)),

      # Step 3: Calculate adjusted_cost_base with commission
      adjusted_cost_base = purrr::accumulate(
        .x = seq_len(dplyr::n()),  # Iterate over rows within each group
        .init = 0,
        .f = ~ {
          prev_cost <- if (.y == 1) 0 else .x
          prev_cum_qty <- if (.y == 1) 0 else share_balance[.y - 1]

          if (tolower(action[.y]) == "buy") {
            # Add commission when buying
            prev_cost + quantity[.y] * price[.y] + commission[.y]
          } else if (prev_cum_qty > 0) {
            # Reduce adjusted_cost_base proportionally on sell
            prev_cost * (prev_cum_qty - quantity[.y]) / prev_cum_qty
          } else {
            0
          }
        }
      )[-1],  # Remove initial value because the accumulate vector has an extra 0 at the beginning.

      # Step 4: Calculate capital_gain for sell transactions
      adjusted_cost_base_of_goods_sold = dplyr::if_else(
        tolower(action) == "sell" & dplyr::lag(share_balance, default = 0) > 0,
        (dplyr::lag(adjusted_cost_base, default = 0))*  quantity / dplyr::lag(share_balance, default = 1),
        NA_real_
      ), # NA if not a valid sell
      capital_gain = dplyr::if_else(
        tolower(action) == "sell" & dplyr::lag(share_balance, default = 0) > 0,
        (quantity * price) - adjusted_cost_base_of_goods_sold - commission,
        NA_real_  # NA if not a valid sell
      ),
      adjusted_cost_base_per_share = dplyr::if_else(share_balance > 0, adjusted_cost_base / share_balance, NA_real_)
    ) %>%
    dplyr::ungroup()  # Ungroup after calculations

  return(df)
}


