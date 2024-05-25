# Takes an input html, encrypts it with a password, writes to an output
# html, and uses a template
f_encrypt_dashboard <- function(path_in, dir_out, password, html_template){
  
  # Create the staticrypt system command.
  cmd = paste(
    "staticrypt", path_in, 
    "-d", dir_out,
    "-p", password,
    "-t", html_template,
    "--remember",
    "--short",
    "--template-title '  '",
    "--template-button 'Log In'",
    "--template-color-primary '#0c78ff'",
    "--template-color-secondary '#FFFFFF'",
    "--template-error 'Password entered does not match the one on file. Please try again, or email info@convolve.coop for help.'"
  )
  
  # Print inputs for debugging.
  cat(
    "\n  Path in: ",  path_in,  "\n",
    " Path out:",     dir_out, "\n",
    " Password:",     password, "\n",
    " Encrypting..."
  )
  
  # Run the command.
  system(cmd)
  cat("done.\n\n")
  
}

# If the function fails, return NULL and move on. Thus, an error here will not
# take down the pipeline.
f_encrypt_dashboard <- possibly(f_encrypt_dashboard, otherwise = NULL)
