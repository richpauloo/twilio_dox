library(rvest)
library(ggplot2)
library(lubridate)
library(dplyr)

# tomorrow's date for the API query
today <- Sys.Date() + 1
cat("Running query for", today, "and 72 hrs prior.\n")

# url prefix and suffix - works for this simple, single endpoint use case
# hard codes the sensor number (61) and duration (96 hrs)
prefix <- "http://cdec4gov.water.ca.gov/dynamicapp/selectQuery?Stations=LIS&SensorNums=61&dur_code=E&End="
suffix <- "&span=96hours"

# URL query to pass to CDEC
url <- paste(prefix, today, suffix, sep = "")

# read the query, unlist the output and clean:
# rename cols, convert t to datetime, filter blank (future) DO
df <- read_html(url) %>% 
  html_elements("tbody") %>% 
  html_table() %>% 
  .[[1]] %>% 
  select(1:2) %>% 
  setNames(c("t", "do")) %>% 
  filter(do != "--") %>% 
  mutate(t = mdy_hm(t), do = as.numeric(do)) 
cat("Downloaded", nrow(df), "rows of data.\n")


# caption for ggplot
caption <- paste(
  "Date range:", paste(range(df$t), collapse = " to "), 
  "\n", "Data obtained from CDEC API (http://cdec4gov.water.ca.gov/)"
)

# plot and save to GH path, then commit changes
p <- ggplot(df, aes(t, do)) +
  geom_point(alpha = 0.2, color = "blue") + 
  geom_line(alpha = 0.7) +
  scale_x_datetime(date_breaks = "4 hours", date_labels = "%a %I%p") +
  labs(
    title    = "Dissolved Oxygen Content (mg/L)",
    subtitle = "Yolo Bypass at Lisbon",
    caption  = caption,
    x = "", y = ""
  ) +
  # theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) 

path_out <- paste0("png/", Sys.Date(), ".png")
ggsave(path_out, p, height = 5, width = 7)
cat("Saved plot to", path_out, "\n")
