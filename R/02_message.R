# after changes are committed, run a second job that sends the msg
library(twilio)

# load environmental vars
tw_sid            <- Sys.getenv("TWILIO_SID")
tw_tok            <- Sys.getenv("TWILIO_TOKEN")
tw_phone_number   <- Sys.getenv("TWILIO_PHONE_NUMBER")
tw_target_number  <- Sys.getenv("TARGET_PHONE_NUMBER")
# tw_target_number2 <- Sys.getenv("TARGET_PHONE_NUMBER2")
# tw_target_number3 <- Sys.getenv("TARGET_PHONE_NUMBER3")
# tw_target_number4 <- Sys.getenv("TARGET_PHONE_NUMBER4")

nums <- c(tw_target_number)#), tw_target_number2, tw_target_number3, tw_target_number4)

# PNG plot img url from github (does this work with private repo?)
url_img <- paste0(
  "https://raw.githubusercontent.com/richpauloo/twilio_dox/main/png/",
  Sys.Date(),
  ".png"
)

# read stashed df
df <- read.csv(paste0("/png/", Sys.Date(), ".csv"))

# minimum dissovled oxygen (mg/L)
min_do <- min(df$do, na.rm = TRUE)

# determine high/med/low message and construct text 
msg_high <- paste(
  "U+1F7E2 U+1F41F HIGH minimum dissolved oxygen:",
  min_do, "mg/L."
)

msg_medium <- paste(
  "U+1F7E1 U+1F41F MEDIUM minimum dissolved oxygen:",
  min_do, "mg/L."
)

msg_low <- paste(
  "U+1F534 U+1F41F LOW minimum dissolved oxygen:",
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

# text the plot to the phone number 
for(i in 1:length(nums)){
  tw_send_message(
    from      = tw_phone_number, 
    to        = nums[i],
    body      = msg,
    media_url = url_img
  )
}

cat("Sent plot via text message\n")
