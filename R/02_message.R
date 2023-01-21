# after changes are committed, run a second job that sends the msg
library(twilio)

# load environmental vars
tw_sid            <- Sys.getenv("TWILIO_SID")
tw_tok            <- Sys.getenv("TWILIO_TOKEN")
tw_phone_number   <- Sys.getenv("TWILIO_PHONE_NUMBER")
tw_target_number  <- Sys.getenv("TARGET_PHONE_NUMBER")
tw_target_number2 <- Sys.getenv("TARGET_PHONE_NUMBER2")
tw_target_number3 <- Sys.getenv("TARGET_PHONE_NUMBER3")

nums <- c(tw_target_number, tw_target_number2, tw_target_number3)

url_img <- paste0(
  "https://raw.githubusercontent.com/richpauloo/twilio_dox/main/png/",
  Sys.Date(),
  ".png"
)

# text the plot to the phone number 
for(i in 1:length(nums)){
  tw_send_message(
    from      = tw_phone_number, 
    to        = nums[i],
    media_url = url_img
  )
}

cat("Sent plot via text message\n")
