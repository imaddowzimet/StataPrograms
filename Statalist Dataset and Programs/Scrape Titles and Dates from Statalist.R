###################
# System set-up
##################
library(rvest)
library(broom)
library(dplyr)
library(tidytext)
library(ggplot2)
library(lubridate)
library(haven)
rm(list = ls())

##########################
# Scrape data from statalist
##########################
stataforum1 <- read_html("https://www.statalist.org/forums/forum/general-stata-discussion/general")

stataforum.title <- stataforum1 %>%
  html_nodes(".js-topic-title") %>%
  html_text()

stataforum.date <- stataforum1 %>%
  html_nodes(".date") %>%
  html_text()

statalist.title <- list()
statalist.date <- list()

statalist.title[[1]] <- stataforum.title
statalist.date[[1]] <- stataforum.date

# Note that the upper limit needs to be changed manually
for (i in 2:600) {
  print(i)
  stataforum <-
    read_html(
      paste("https://www.statalist.org/forums/forum/general-stata-discussion/general/page",
            i, sep=""))
  statalist.title[[i]] <- stataforum %>%
    html_nodes(".js-topic-title") %>%
    html_text()

  statalist.date[[i]] <- stataforum %>%
    html_nodes(".date") %>%
    html_text()

}

statalist.title.raw <- matrix(unlist(statalist.title), ncol = 1, byrow = TRUE)
statalist.date.raw <- matrix(unlist(statalist.date), ncol = 1, byrow = TRUE)

# Add date and year information
todayrows <- grep("Today", statalist.date.raw)
yesterdayrows <- grep("Yesterday", statalist.date.raw)
statalist.date.raw[todayrows] <- "08 Sep 2017"   # This should be modified to current date
statalist.date.raw[yesterdayrows] <- "07 Sep 2017"

statalist.date.formatted <- as.Date(statalist.date.raw, "%d %b %Y")

# Format and export to stata
statalist.for.stata <- data.frame(statalist.title.raw, statalist.date.formatted)
statalist.for.stata$Title <- statalist.for.stata$statalist.title.raw
statalist.for.stata$Date <- statalist.for.stata$statalist.date.formatted
statalist.for.stata$statalist.title.raw<- NULL
statalist.for.stata$statalist.date.formatted<- NULL

write_dta(statalist.for.stata, "StatalistPosts.dta") 

