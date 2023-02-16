# after changes are committed, run a second job that sends the msg
library(twilio)

# load environmental vars
tw_sid            <- Sys.getenv("TWILIO_SID")
tw_tok            <- Sys.getenv("TWILIO_TOKEN")
tw_phone_number   <- Sys.getenv("TWILIO_PHONE_NUMBER")

# capture numbers which follow the env var convention
# PHONE_NUMBER_{initials}, input as Github secrets
env_vars <- names(Sys.getenv())
num_ids  <- env_vars[grep("PHONE_NUMBER_", env_vars)]
nums     <- unlist(lapply(num_ids, Sys.getenv))
cat(length(nums), "phone numbers found.\n")

# PNG plot img url from github (does this work with private repo?)
url_img <- paste0(
  "https://raw.githubusercontent.com/richpauloo/twilio_dox/main/png/",
  Sys.Date(),
  ".png"
)

# read stashed df
df <- read.csv(paste0("csv/", Sys.Date(), ".csv"))

# minimum dissovled oxygen (mg/L)
min_do <- min(df$do, na.rm = TRUE)

# determine high/med/low message and construct text 
msg_high <- paste(
  "\U0001F7E2 \U0001F41F HIGH minimum dissolved oxygen:",
  min_do, "mg/L."
)

msg_medium <- paste(
  "\U0001F7E1 \U0001F41F MEDIUM minimum dissolved oxygen:",
  min_do, "mg/L."
)

msg_low <- paste(
  "\U0001F534 \U0001F41F LOW minimum dissolved oxygen:",
  min_do, "mg/L."
)

if(min_do >= 6.5) {
  msg = msg_high
} 
if(min_do < 6.5 & min_do >= 4) {
  msg = msg_medium
} 
if(min_do < 4) {
  msg = msg_low
} 

# text the plot to the phone number, and report initials 
# of who the text is sent to. All env vars start the same, so 
# extract initials by removing "PHONE_NUMBER_"
initials <- substr(env_vars, 14, 100)

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
