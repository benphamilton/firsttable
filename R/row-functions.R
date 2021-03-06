# Row functions

# wilcox_row --------------------------------------------------------------

#' Wilcox test row
#'
#' @param data_item item to be taken from data for row
#' @param row_digits digits for data item (overrides table as a whole)
#' @param na.rm whether to remove NA before reporting median and quartiles
#' @param data separate dataset to use
#' @param data_filter filter to apply to dataset
#'
#' @export
#'
#' @examples
#' first_table(
#'   mtcars,
#'   .column_variable = am,
#'   wilcox_row(disp, row_digits = 2)
#' )
wilcox_row <- function(data_item,
                       data = NULL,
                       data_filter = NULL,
                       row_digits = NULL,
                       na.rm = TRUE) {
  list(
    data_item = enquo(data_item),
    data = data,
    data_filter = enquo(data_filter),
    data_function = function(row_item, col_item, ft_options) {
      digits <- row_digits %||% ft_options$digits
      list(row_output = med_iqr(row_item, col_item, digits, na.rm),
           p = if (ft_options$include_p) {
             if (length(unique(col_item[!is.na(row_item)])) == 2L) {
               stats::wilcox.test(row_item ~ col_item)$p.value
             } else {
               NA_real_
             }
           } else {
             NULL
           })
    }
  )
}

# med_iqr -----------------------------------------------------------------

med_iqr <- function(row_item, col_item, digits, na.rm) {
  quartiles <- tapply(
    row_item,
    col_item,
    stats::quantile,
    probs = seq(0.25, 0.75, 0.25),
    na.rm = na.rm,
    simplify = FALSE
  )
  quartiles <- simplify2array(quartiles)
  sprintf(
    "%2$.*1$f (%3$.*1$f - %4$.*1$f)",
    digits,
    quartiles[2, ],
    quartiles[1, ],
    quartiles[3, ]
  )
}

# parametric_row --------------------------------------------------------------

#' Row for parametric data
#'
#' @param data_item item to be taken from data for row
#' @param row_digits digits for data item (overrides table as a whole)
#' @param na.rm whether to remove NA before reporting median and quartiles
#' @param data separate dataset to use
#' @param data_filter filter to apply to dataset
#'
#' @export
#' @examples
#' first_table(
#'   mtcars,
#'   .column_variable = am,
#'   parametric_row(disp, row_digits = 2)
#' )

parametric_row <- function(data_item,
                           data = NULL,
                           data_filter = NULL,
                           row_digits = NULL,
                           na.rm = TRUE) {
  list(
    data_item = enquo(data_item),
    data = data,
    data_filter = enquo(data_filter),
    data_function = function(row_item, col_item, ft_options) {
      digits <- row_digits %||% ft_options$digits
      list(row_output = mean_sd(row_item, col_item, digits, na.rm),
           p = if (ft_options$include_p) {
             if (length(unique(col_item[!is.na(row_item)])) == 2L) {
               stats::t.test(row_item ~ col_item)$p.value
             } else {
               NA_real_
             }
           } else {
             NULL
           })
    }
  )
}

# mean_sd -----------------------------------------------------------------

mean_sd <- function(row_item, col_item, digits, na.rm) {
  values <- tapply(
    row_item,
    col_item,
    function(x) {c(mean(x, na.rm = na.rm), stats::sd(x, na.rm = na.rm))},
    simplify = FALSE
  )
  values <- simplify2array(values)
  sprintf(
    "%2$.*1$f (%3$.*1$f)",
    digits,
    values[1, ],
    values[2, ]
  )
}

# kruskal_row --------------------------------------------------------------

#' Kruskal Wallis test row
#'
#' @param data_item item to be taken from data for row
#' @param row_digits digits for data item (overrides table as a whole)
#' @param na.rm whether to remove NA before reporting median and quartiles
#' @param data separate dataset to use
#' @param data_filter filter to apply to dataset
#'
#' @export
#' @examples
#' first_table(
#'   mtcars,
#'   .column_variable = cyl,
#'   kruskal_row(disp, row_digits = 2)
#' )
kruskal_row <- function(data_item,
                        data = NULL,
                        data_filter = NULL,
                        row_digits = NULL,
                        na.rm = TRUE) {
  list(
    data_item = enquo(data_item),
    data = data,
    data_filter = enquo(data_filter),
    data_function = function(row_item, col_item, ft_options) {
      digits <- row_digits %||% ft_options$digits
      list(
        row_output = med_iqr(row_item, col_item, digits, na.rm),
        p = if (ft_options$include_p) {
          stats::kruskal.test(row_item ~ col_item)$p.value
        } else {
          NULL
        }
      )
    }
  )
}


# fisher_row --------------------------------------------------------------

#' Row using Fisher's exact test
#'
#' @inheritParams wilcox_row
#' @param na.rm whether to include NA in the denominator for percentages
#' @param reference_level a level of the variable to drop from display
#' @param include_reference whether to include the first level of the factor
#'        in the report
#' @param workspace passed onto \code{\link[stats]{fisher.test}}
#'
#' @export
#'
#' @examples
#' first_table(
#'   mtcars,
#'   .column_variable = cyl,
#'   fisher_row(gear, row_digits = 2, include_reference = TRUE)
#' )

fisher_row <- function(data_item,
                       data = NULL,
                       data_filter = NULL,
                       row_digits = NULL,
                       na.rm = TRUE,
                       reference_level = NULL,
                       include_reference = TRUE,
                       workspace = NULL) {
  list(
    data_item = enquo(data_item),
    data = data,
    data_filter = enquo(data_filter),
    data_function = function(row_item, col_item, ft_options) {
      digits <- row_digits %||% ft_options$digits
      workspace <- workspace %||% ft_options$workspace
      tab <- table(row_item, col_item)
      totals <- colSums(tab, na.rm = na.rm)
      output <- sprintf(
        "%2$d (%3$.*1$f%%)",
        digits,
        tab,
        tab / rep(totals, each = nrow(tab)) * 100
      )
      dim(output) <- dim(tab)
      output <- cbind(rownames(tab), output)
      if (!include_reference && is.null(reference_level)) {
        reference_level <- rownames(tab)[1]
      }
      if (!is.null(reference_level)) {
        output <- output[rownames(tab) != reference_level, , drop = FALSE]
      }
      list(
        row_output = output,
        p = if (ft_options$include_p) {
          if (all(dim(tab) > 1L)) {
            stats::fisher.test(tab, workspace = workspace)$p.value
          } else {
            NA_real_
          }
        } else {
          NULL
        }
      )
    }
  )
}

# chisq_row --------------------------------------------------------------

#' Row using chi squared test
#'
#' @inheritParams wilcox_row
#' @param na.rm whether to include NA in the denominator for percentages
#' @param reference_level a level of the variable to drop from display
#' @param include_reference whether to include the first level of the factor
#'        in the report
#'
#' @export
#'
#' @examples
#' first_table(
#'   mtcars,
#'   .column_variable = cyl,
#'   chisq_row(gear, row_digits = 2, include_reference = TRUE)
#' )

chisq_row <- function(data_item,
                      data = NULL,
                      data_filter = NULL,
                      row_digits = NULL,
                      na.rm = TRUE,
                      reference_level = NULL,
                      include_reference = TRUE) {
  list(
    data_item = enquo(data_item),
    data = data,
    data_filter = enquo(data_filter),
    data_function = function(row_item, col_item, ft_options) {
      digits <- row_digits %||% ft_options$digits
      tab <- table(row_item, col_item)
      totals <- colSums(tab, na.rm = na.rm)
      output <- sprintf(
        "%2$d (%3$.*1$f%%)",
        digits,
        tab,
        tab / rep(totals, each = nrow(tab)) * 100
      )
      dim(output) <- dim(tab)
      output <- cbind(rownames(tab), output)
      if (!include_reference && is.null(reference_level)) {
        reference_level <- rownames(tab)[1]
      }
      if (!is.null(reference_level)) {
        output <- output[rownames(tab) != reference_level, , drop = FALSE]
      }
      list(
        row_output = output,
        p = if (ft_options$include_p) {
          if (all(dim(tab) > 1L)) {
            stats::chisq.test(tab)$p.value
          } else {
            NA_real_
          }
        } else {
          NULL
        }
      )
    }
  )
}


#' Cox Proportional Hazards Row
#'
#' @inheritParams wilcox_row
#' @param row_digits Number of digits to include in the OR
#' @param include_reference whether to include a row for the reference level of
#'   a factor
#'
#' @return row for inclusion in `first_table`
#' @export
#'
#' @examples
#' library(survival)
#' first_table(lung,
#'   .column_variable = Surv(time, status),
#'    ECOG = coxph_row(factor(ph.ecog), row_digits = 2)
#'  )

#'
coxph_row <- function(data_item,
                      data = NULL,
                      data_filter = NULL,
                      row_digits = NULL,
                      include_reference = TRUE) {
  stopifnot(requireNamespace("survival"))
  list(
    data_item = enquo(data_item),
    data = data,
    data_filter = enquo(data_filter),
    data_function = function(row_item, col_item, ft_options) {
      digits <- row_digits %||% ft_options$digits
      model <- survival::coxph(col_item ~ row_item)
      hrs <- exp(stats::coef(model))
      cis <- exp(stats::confint(model))
      ps <- stats::pchisq(
        (summary(model)$coefficients[, "z", drop = TRUE]) ^ 2,
        df = 1,
        lower.tail = FALSE
      )
      if (names(hrs)[1L] == "row_item") {
        levs <- ""
        cis <- matrix(cis, ncol = 2)
      } else {
        levs <- sub("row_item", "", names(hrs))
      }
      output <- sprintf(
        "%2$.*1$f (%3$.*1$f - %4$.*1$f)",
        digits,
        hrs,
        cis[, 1, drop = TRUE],
        cis[, 2, drop = TRUE]
      )
      if (include_reference & !identical(levs, "") & !is.logical(row_item)) {
        output <- c("Reference", output)
        levs <- c(levels(as.factor(row_item))[1L], levs)
        ps <- c(NA, ps)
      }
      list(row_output = cbind(levs, output),
           p = if (ft_options$include_p) ps else NULL
      )
    }
  )

}

#' Row with type selected by firsttable

#' @inheritParams wilcox_row
#' @param include_reference whether to include a row for the reference level of
#'   a factor (only relevant for logical/factor/character variables)
#' @param reference_level a level of the variable to drop from display (only
#'   relevant for logical/factor/character variables)
#' @param workspace passed onto \code{\link[stats]{fisher.test}}
#' @param non_parametric whether to use non-parametric tests

#' @return row for inclusion in `first_table`
#'
#' @details This provides a generic row for \code{\link{first_table}} with
#' the type of row determined from the \code{class} of the data. This allows a
#' \code{list} of \code{\link[rlang]{quos}} to be created and then used for
#' both a standard \code{\link{first_table}} and one that uses a
#' \code{\link[survival]{Surv}} column.
#'
#' @import rlang
#' @export
#'
#' @examples
#' library(survival)
#' first_table(lung,
#'   .column_variable = Surv(time, status),
#'   .options = list(include_n = TRUE, include_n_per_col = TRUE),
#'    `Meal calories` = first_table_row(meal.cal, row_digits = 2)
#'  )


first_table_row <- function(data_item,
                            data = NULL,
                            data_filter = NULL,
                            row_digits = NULL,
                            na.rm = TRUE,
                            reference_level = NULL,
                            include_reference = NULL,
                            workspace = NULL,
                            non_parametric = NULL) {
  data_item <- enquo(data_item)
  data_filter <- enquo(data_filter)
  list(
    data_item = data_item,
    data = data,
    data_filter = data_filter,
    data_function = function(row_item, col_item, ft_options) {
      digits <- row_digits %||% ft_options$digits
      workspace <- workspace %||% ft_options$workspace
      non_parametric <- non_parametric %||% ft_options$default_non_parametric
      if (inherits(col_item, "Surv")) {
        row_function <- coxph_row(!!data_item, data = data, data_filter = !!data_filter,
                                  row_digits = row_digits,
                                  include_reference = if (is.null(include_reference)) TRUE else include_reference)
      } else if (is.numeric(row_item)) {
        if (non_parametric) {
          if (length(unique(col_item)) <= 2) {
            row_function <- wilcox_row(!!data_item, data = data, data_filter = !!data_filter,
                                       row_digits = row_digits, na.rm = na.rm)
          } else {
            row_function <- kruskal_row(!!data_item, data = data, data_filter = !!data_filter,
                                        row_digits = row_digits, na.rm = na.rm)
          }
        } else {
          row_function <- parametric_row(!!data_item, data = data, data_filter = !!data_filter,
                                         row_digits = row_digits, na.rm = na.rm)
        }
      } else if (is.logical(row_item)) {
        row_function <- fisher_row(!!data_item, data = data, data_filter = !!data_filter, row_digits = row_digits,
                                   na.rm = na.rm, reference_level = reference_level %||% "FALSE",
                                   include_reference = if (is.null(include_reference)) FALSE else include_reference,
                                   workspace = workspace)
      } else {
        row_function <- fisher_row(!!data_item, data = data, data_filter = !!data_filter, row_digits = row_digits,
                                   na.rm = na.rm, reference_level = reference_level,
                                   include_reference = if (is.null(include_reference)) TRUE else include_reference,
                                   workspace = workspace)
      }
      row_function$data_function(row_item, col_item, ft_options)
    }
  )
}
