# after changes are committed, run a second job that sends the msg
library(twilio)
library(dplyr)
library(lubridate)

# function that takes a minimum DO and returns the text msg body
f_generate_message <- function(min_do, interval = 1) {
  if (min_do >= 6.5) {
    msg = paste("\U0001F7E2 \U0001F41F HIGH minimum dissolved oxygen:",
                min_do, "mg/L")
  }
  if (min_do < 6.5 & min_do >= 4) {
    msg = paste("\U0001F7E1 \U0001F41F MEDIUM minimum dissolved oxygen:",
                min_do, "mg/L")
  }
  if (min_do < 4) {
    msg = paste("\U0001F534 \U0001F41F LOW minimum dissolved oxygen:",
                min_do, "mg/L")
  }
  # we remove NA DO before passing to this function. if all DO is NA,
  # the plot will say there is no sensor data -- make msg reflect this
  if (is.infinite(min_do)) {
    msg = "\U000274C Sensor reported missing data."
  }
  # variations for 1 and 7 day messages
  if(interval == 1){
    msg =paste(
      substr(msg, 1, 3),
      " [Daily report]",
      substr(msg, 5, 1e6),
      "on", as.character(Sys.Date())
    )
  }
  if(interval == 7){
    msg = paste(
      substr(msg, 1, 3),
      "[Weekly report]",
      substr(msg, 5, 1e6),
      "for the previous 7-day period from", 
      as.character(Sys.Date() - 7), "to", 
      as.character(Sys.Date())
    )
  }
  return(msg)
}

# function to send a text message - expects namd vars: nums, initials, 
# tw_phone_number, url_img
f_send_message <- function(msg) {
  # text plot to the phone number, and report initials per number 
  for(i in seq_along(nums)){
    cat("Preparing to text phone number", initials[i], "...")
    tw_send_message(
      from      = tw_phone_number, 
      to        = nums[i],
      body      = msg,
      media_url = url_img
    )
    cat(" sent.\n")
  }
}

# load environmental vars
tw_sid            <- Sys.getenv("TWILIO_SID")
tw_tok            <- Sys.getenv("TWILIO_TOKEN")
tw_phone_number   <- Sys.getenv("TWILIO_PHONE_NUMBER")

# capture numbers which follow the env var convention
# PHONE_NUMBER_{initials}, input as Github secrets.
# capture initials for informative logs
env_vars <- names(Sys.getenv())
num_ids  <- env_vars[grep("PHONE_NUMBER_", env_vars)]
nums     <- unlist(lapply(num_ids, Sys.getenv))
initials <- substr(num_ids, 14, 100)
cat(length(nums), "phone numbers found.\n")

# PNG plot img url from github (does this work with private repo?)
url_img <- paste0(
  "https://raw.githubusercontent.com/richpauloo/twilio_dox/main/png/",
  Sys.Date(),
  ".png"
)

# read stashed df
df <- read.csv(paste0("csv/", Sys.Date(), ".csv"))

# minimum dissolved oxygen (mg/L) in the last 1 and 7 days
cutoff_1_day <- ymd_hms(max(df$t, na.rm = TRUE)) - 86400
df_1_day     <- filter(df, t >= cutoff_1_day)
min_do_1_day <- min(df_1_day$do, na.rm = TRUE)
min_do_7_day <- min(df$do, na.rm = TRUE)

# determine high/med/low message and construct text 
msg_1_day <- f_generate_message(min_do_1_day, interval = 1)
msg_7_day <- f_generate_message(min_do_7_day, interval = 7)

# trigger 1-day alert if the 1 day min DO is below 4 mg/L
if (min_do_1_day < 4) {
  f_send_message(msg_1_day)
}

# trigger 7-day alert every Monday
day_of_week <- as.character(wday(Sys.Date(), label = TRUE))

# If the 1 day DO is < 4, the message is already sent, so avoid dupe msg.
if (day_of_week == "Mon" & min_do_1_day >= 4) {
  f_send_message(msg_7_day)
}

# If no message was sent, alert the GH Action log.
if (day_of_week != "Mon" & min_do_1_day >= 4) {
  cat("Today is not a Monday, and DO >= 4, so no message was sent.\n")
}

cat("Day of week detected:", day_of_week, "\n")
cat("Completed at", as.character(Sys.time()), "\n")
