library(rvest)
library(ggplot2)
library(lubridate)
library(dplyr)
library(httr)

# tomorrow's date for the API query
today <- Sys.Date() + 1
cat("Running query for", as.character(today), "and 7 days prior.\n")


# url prefix and suffix
prefix <- "https://cdec.water.ca.gov/dynamicapp/QueryF?s=LIS&d="
suffix <- "+09:00&span=168hours"

# URL query to pass to CDEC
url <- paste(prefix, format(today, "%d-%b-%Y"), suffix, sep = "")

empty_df <- data.frame(t = as.POSIXct(character()), do = numeric())

f_find_data_table <- function(page) {
  tables <- page %>% html_nodes("table")
  if (length(tables) == 0) {
    return(NULL)
  }

  parsed_tables <- lapply(tables, function(x) {
    table <- html_table(x, fill = TRUE)
    if (inherits(table, "data.frame")) {
      return(table)
    }
    return(table[[1]])
  })

  for (raw in parsed_tables) {
    # Column name changes between PST and PDT depending on time of year.
    date_col <- grep("^DATE / TIME", names(raw), value = TRUE)[1]
    do_col <- grep("^DIS OXY\\s+MG/L$", names(raw), value = TRUE)[1]

    if (!is.na(date_col) && !is.na(do_col)) {
      return(list(raw = raw, date_col = date_col, do_col = do_col))
    }
  }

  return(NULL)
}

f_fetch_cdec_table <- function(url, attempts = 5) {
  for (attempt in seq_len(attempts)) {
    resp <- try(
      RETRY(
        "GET", url,
        times = 2, pause_base = 2, pause_cap = 30,
        timeout(60)
      ),
      silent = TRUE
    )

    if (inherits(resp, "try-error")) {
      cat("CDEC request failed on attempt", attempt, "of", attempts, "\n")
    } else if (http_error(resp)) {
      cat(
        "CDEC request returned HTTP", status_code(resp),
        "on attempt", attempt, "of", attempts, "\n"
      )
    } else {
      page <- try(
        read_html(content(resp, as = "text", encoding = "UTF-8")),
        silent = TRUE
      )

      if (inherits(page, "try-error")) {
        cat("CDEC returned unreadable HTML on attempt", attempt, "of", attempts, "\n")
      } else {
        data_table <- f_find_data_table(page)

        if (!is.null(data_table)) {
          return(data_table)
        }

        cat(
          "CDEC response did not include the expected DIS OXY table on attempt",
          attempt, "of", attempts, "\n"
        )
      }
    }

    if (attempt < attempts) {
      Sys.sleep(min(30, attempt * 5))
    }
  }

  warning("CDEC did not return a usable DIS OXY table; writing an empty data set.")
  return(NULL)
}

data_table <- f_fetch_cdec_table(url)

if (is.null(data_table)) {
  df <- empty_df
} else {
  df <- data_table$raw %>%
    select(all_of(c(data_table$date_col, data_table$do_col))) %>%
    setNames(c("t", "do")) %>%
    mutate(
      t  = mdy_hm(t),
      do = suppressWarnings(as.numeric(do))
    ) %>%
    filter(!is.na(t) & !is.na(do))
}

cat("Downloaded", nrow(df), "rows of data.\n")

# stash for later
path_out_csv <- paste0("csv/", Sys.Date(), ".csv")
write.csv(df, path_out_csv)
cat("Wrote csv to", path_out_csv, "\n")

# case when DO is all NA - ensure plot indicates problem with sensor
df_na <- data.frame(
  x = 1, y = 1,
  text = "Sensor reported missing data."
)

if (nrow(df) == 0) {
  caption <- paste(
    "Date range: no valid data returned",
    "\n", "Data obtained from CDEC API (http://cdec4gov.water.ca.gov/)"
  )

  p <- df_na %>%
    ggplot() +
    geom_text(aes(x, y, label = text), size = 10) +
    theme_void() +
    labs(caption = caption)
} else {
  caption <- paste(
    "Date range:", paste(range(df$t), collapse = " to "),
    "\n", "Data obtained from CDEC API (http://cdec4gov.water.ca.gov/)"
  )

  # TODO: filter to last 7 days
  # plot and save to GH path, then commit changes
  p <- ggplot() +
    geom_rect(
      data = data.frame(x1 = min(df$t), x2 = max(df$t),
                        y1 = 0, y2 = 4),
      aes(xmin = x1, xmax = x2, ymin = y1, ymax = y2),
      fill = "pink", alpha = 0.5
    ) +
    geom_rect(
      data = data.frame(x1 = min(df$t), x2 = max(df$t),
                        y1 = 4, y2 = 6.5),
      aes(xmin = x1, xmax = x2, ymin = y1, ymax = y2),
      fill = "#F1EB9C", alpha = 0.5
    ) +
    geom_rect(
      data = data.frame(x1 = min(df$t), x2 = max(df$t),
                        y1 = 6.5, y2 = max(df$do, na.rm = TRUE) + 0.5),
      aes(xmin = x1, xmax = x2, ymin = y1, ymax = y2),
      fill = "#90EE90", alpha = 0.5
    ) +
    geom_point(
      data = df, aes(t, do),
      alpha = 0.3, color = "blue"
    ) +
    geom_line(
      data = df, aes(t, do),
      alpha = 0.7
    ) +
    scale_x_datetime(date_breaks = "12 hours", date_labels = "%a %I%p") +
    labs(
      title    = "Dissolved Oxygen Content (mg/L)",
      # swap this a csv lookup key when more sites are added
      subtitle = "Yolo Bypass at Lisbon, last 7 days",
      caption  = caption,
      x = "", y = ""
    ) +
    coord_cartesian(expand = 0) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

path_out_png <- paste0("png/", Sys.Date(), ".png")
ggsave(path_out_png, p, height = 5, width = 7)
cat("Wrote plot to", path_out_png, "\n")

# remove csv/png files older than 30 days
date_cutoff <- today - 30

# files in repo
files_csv <- list.files("csv", full.names = TRUE)
files_png <- list.files("png", full.names = TRUE)

# remove files before the cutoff date
rm_csv <- as.Date(substr(files_csv, 5, 14)) < date_cutoff
rm_png <- as.Date(substr(files_png, 5, 14)) < date_cutoff
file.remove(c(files_csv[rm_csv], files_png[rm_png]))
cat("Removed csv and png files older than", as.character(date_cutoff), "\n")
