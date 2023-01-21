# twilio-message

This repo builds a Docker image that uses the `{twilio}` R package to send a daily text message to a target phone number. 

## Setup

Clone this repo.  

In the root directory, add a `.Renviron` file with the following environmental variables:

```
TWILIO_SID          = "<your twilio SID>"
TWILIO_AUTH_TOKEN   = "<your twilio auth token>"
TWILIO_PHONE_NUMBER = "<your twilio phone number>"
TARGET_PHONE_NUMBER = "<the target phone number to receive texts>"

```


## Docker

Build the Docker image:

```
cd docker
bash build_docker.sh
```

This results in a Docker image called `tdox`.  

Test the docker image in RStudio Server:  

```
docker run --rm -ti -p 8787:8787 -e DISABLE_AUTH=true rocker/richpauloo/tdox:prod.0.0.01
```

Use the manual GH Action to test.
