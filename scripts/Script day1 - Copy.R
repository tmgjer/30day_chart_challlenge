### CHART CHALLENGE

# DAY 1 - Part-to-whole

rm(list = ls())

# Load libraries
library(openxlsx)
library(dplyr)
library(stringr)
library(ggplot2)
library(tidyr)

# setting working directory
setwd("C:/Users/u955140/surfdrive/Plots/#30daychartchallenge/Day 1")

# Load data
elections <- read.xlsx("Gemeente uitslagen tweede kamer verkiezing 2021.xlsx")
covid<- read.csv("COVID-19_aantallen_gemeente_per_dag.csv", sep=";")
popsize <- read.xlsx("Regionale_kerncijfers_Nederland_01042022_140107.xlsx")


# Create percentage SGP voters for each municipality
elections <- elections %>% select(RegioCode, GeldigeStemmen, "Staatkundig.Gereformeerde.Partij.(SGP)") %>% 
  rename(SGP="Staatkundig.Gereformeerde.Partij.(SGP)") %>%
  mutate(perc_sgp=SGP/GeldigeStemmen*100)


# Create monthly COVID incidents for each municipality
# I need: Municipality_code, Total_reported, Data_of_publication
covid <- covid %>% mutate(monthyear=str_sub(Date_of_publication, start=1, end=7)) %>%
  group_by(monthyear, Municipality_code) %>%
  summarise(n_inf=sum(Total_reported))

# remove first months due to lack of testing capacity
covid <- covid %>% filter(monthyear!="2020-02", monthyear!="2020-03",
                          monthyear!="2020-04", monthyear!="2020-05",
                          monthyear!="2020-06")

# Now I can make percentages of Covid infections on the total population
covid <- covid %>% left_join(popsize, by=c("Municipality_code"="code")) %>%
  filter(!is.na(aantal)) %>%
  mutate(perc_inf=n_inf/aantal*100)


# Now I only need to merge elections and covid together
covid <- covid %>% mutate(id=str_sub(Municipality_code, start=3, end=6)) %>% select(id, perc_inf, monthyear)
elections <- elections %>% mutate(id=str_sub(RegioCode, start=2, end=5)) %>% select(id, perc_sgp)

# create final data
chart_data <- covid %>% left_join(elections)


## Create gem percentage of infections over all municipalities 
chart_data2 <- chart_data %>% group_by(monthyear) %>% summarise(covid_per_mean=mean(perc_inf),
                                                                covid_per_25=quantile(perc_inf, 0.25),
                                                                covid_per_75=quantile(perc_inf, 0.75)) 

chart_data2$id <- "overall"

chart_data4 <- chart_data2 %>% pivot_longer(covid_per_mean:covid_per_75,names_to="value", values_to="percentage")

# And I want to make this graph for the municipality with the highest percentage of SGP voters
#chart_data3 <- chart_data %>% group_by(id) %>% summarise(SGP=first(perc_sgp))
#max(chart_data3$perc_sgp)
# municipalities: 0184 (Urk), 0703 (Reimerswaal), 0180 (Staphorst)
chart_data3 <- chart_data %>% mutate(id=as.character(id)) %>% filter(id=="0184"|id=="0703"|id=="0180")


### Create first chart for chart_data2
chart_data2 %>% ggplot(aes(x=monthyear, y="percentage"))+
  geom_line()

head(chart_data2)

  
