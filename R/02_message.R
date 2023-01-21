# after changes are committed, run a second job that sends the msg
library(twilio)

# load environmental vars
tw_sid           <- Sys.getenv("TWILIO_SID")
tw_tok           <- Sys.getenv("TWILIO_TOKEN")
tw_phone_number  <- Sys.getenv("TWILIO_PHONE_NUMBER")
tw_target_number <- Sys.getenv("TARGET_PHONE_NUMBER")

url_img <- paste0(
  "https://github.com/richpauloo/twilio_dox/raw/main/png/",
  Sys.Date(),
  ".png"
)

# text the plot to the phone number 
tw_send_message(
  from      = tw_phone_number, 
  to        = tw_target_number,
  media_url = url_img
)
cat("Sent plot via text message\n")
