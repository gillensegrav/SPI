# Test script that sends emails to SPI data providers

# Clear workspace
rm(list=ls(all=TRUE))

library(Microsoft365R)

my_outlook <- get_business_outlook()
my_email <- my_outlook$create_email(content_type = "html")$
  set_body("<p>This is my email body <strong>with bold text</strong>.</p>")$
  set_subject("My 2nd email subject")$
  set_recipients(to = c("recipient1@mail.com", "recipient2@mail.com"))