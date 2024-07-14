library(rvest)
library(ggplot2)
library(lubridate)
library(dplyr)

# tomorrow's date for the API query
today <- Sys.Date() + 1
cat("Running query for", as.character(today), "and 7 days prior.\n")

<<<<<<< Updated upstream
# https://cdec.water.ca.gov/dynamicapp/staMeta?station_id=LIS
# url prefix and suffix - works for this simple, single endpoint use case
# hard codes the sensor number (61) and duration (96 hrs)
# prefix <- "http://cdec4gov.water.ca.gov/dynamicapp/selectQuery?Stations=LIS&SensorNums=61&dur_code=E&End="
prefix <- "http://cdec4gov.water.ca.gov/dynamicapp/selectQuery?Stations=LIS&SensorNums=1,21,25,28,61,221&dur_code=E&End="
# suffix <- "&span=48hours"
suffix <- "&span=8760hours"
=======
  # url prefix and suffix
  prefix <- "https://cdec.water.ca.gov/dynamicapp/QueryF?s=LIS&d="
suffix <- "+09:00&span=168hours"
>>>>>>> Stashed changes

# URL query to pass to CDEC
url <- paste(prefix, format(today, "%d-%b-%Y"), suffix, sep = "")

# read the query, unlist the output and clean:
# rename cols, convert t to datetime, filter blank (future) DO
page <- read_html(url)
tables <- page %>% html_nodes("table")

df <- tables[3] %>% 
  html_table(fill = TRUE) %>% 
  .[[1]] %>% 
  <<<<<<< Updated upstream
select(1, seq(2, ncol(.), 2)) %>% 
  setNames(
    c("t",       # time
      "h_ft",    # 1:   stage (ft)
      "v_ft_s",  # 21:  velocity (ft/s)
      "cp_ug_l", # 28:  chlorophyll (ug/L)
      "t_f",     # 25:  temp (F)
      "trb_fnu", # 221: turbidity (FNU)
      "do_mg_l"  # 61:  dissolved oxygen (mg/L)
    )
  ) %>% 
  mutate(
    across(-t, ~ifelse(.x == "--", NA, .x)),
    across(-t, ~as.numeric(.x)),
    t = mdy_hm(t) 
  )

rownames(df) <- NULL
=======
  select(`DATE / TIMEPDT`, `DIS OXY  MG/L`) %>% 
  setNames(c("t", "do")) %>% 
  mutate(
    t  = mdy_hm(t),
    do = as.numeric(do)
  ) %>% 
  filter(!is.na(t) & !is.na(do))
>>>>>>> Stashed changes
cat("Downloaded", nrow(df), "rows of data.\n")

# stash for later
path_out_csv <- paste0("csv/", Sys.Date(), ".csv")
write.csv(df, path_out_csv)
cat("Wrote csv to", path_out_csv, "\n")

# caption for ggplot
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

# case when DO is all NA - ensure plot indicates problem with sensor
df_na <- data.frame(
  x = 0:2, y = 0:2, 
  text = c(NA, "Sensor reported missing data.", NA)
)

if (nrow(df) == 0) {
  p <- df_na %>% 
    ggplot() +
    geom_text(aes(x, y, label = text), size = 10) +
    theme_void() +
    labs(caption = caption)
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
