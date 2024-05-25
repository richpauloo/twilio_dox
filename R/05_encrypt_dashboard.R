library(tidyverse)
library(fs)

source("R/functions/f_encrypt_dashboard.R")

# Paths to un-encrypted dashboards and dashboard IDs.
path_in  <- dir_ls("0001")
dash_ids <- path_in %>% basename() %>% str_remove_all(".html")

# Directory to write encrypted dashboards.
dir_out <- "0001"

# HTML template to use when encrypting dashboards.
html_template <- "etc/encryption_template.html"

# Passwords from gwdata.xlsx "Dashboard Site Key" 
# (de-duplicated to 1st occurrence).
password <- "pass"

# Encrypt.
f_encrypt_dashboard(path_in, dir_out, password, html_template)


# TODO: in case multiple dashboards per client ID

# Encrypt dashboards and write them to staging output path. ---------------


# for(i in seq_along(path_in)){
#   
#   cat("[", i, "/", length(path_in), "]: encrypting", dash_ids[i])
#   
#   # Password for the ith dashboard ID.
#   password_site = filter(password, dashboard_id == dash_ids[i])$password
#   
#   # Run the encryption.
#   f_encrypt_dashboard(path_in[i], dir_out, password_site, html_template)
#   
# }
