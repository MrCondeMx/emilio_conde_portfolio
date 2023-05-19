# Install NBASTATR
# devtools::install_github("abresler/nbastatR")

# Libraries
library("nbastatR")
library("tidyverse")
library(ggalt)
library(lubridate)
library(ggthemes)
library(stringr)
library(gganimate)

# Increase connection size for correct data import
Sys.setenv(VROOM_CONNECTION_SIZE = "500000")

# Retrieve Shot Data for Dallas Mavericks
shots <- teams_shots(teams = "Dallas Mavericks",
                     seasons = 2023,
                     season_types = "Regular Season") 

# Filter for Luka Doncic and game id corresponding to NYK @ DAL DEC 27, 2022
nykvsdalshots <- shots %>% 
  filter(namePlayer== "Luka Doncic",
         idGame == 22200512)

# Mutate columns for chronological order
nykvsdalshots <- nykvsdalshots %>% 
  mutate(gmtime = ms(as.character(paste(minutesRemaining, secondsRemaining, sep = ":")))) %>% 
  mutate(time_chron=case_when(
    numberPeriod==1~ms("12:00")-gmtime,
    numberPeriod==2~ms("24:00")-gmtime,
    numberPeriod==3~ms("36:00")-gmtime,
    numberPeriod==4~ms("48:00")-gmtime,
    numberPeriod==5~ms("52:00")-gmtime)) %>% 
  # Make close shots visible
  mutate(distTrans=if_else(distanceShot==0,0.8,distanceShot))

# Plot half court
source("https://raw.githubusercontent.com/toddwschneider/ballr/master/plot_court.R")
source("https://raw.githubusercontent.com/toddwschneider/ballr/master/court_themes.R")

plot_court() # created the court_points object we need
court_points <- court_points %>% mutate_if(is.numeric,~.*10)

# Plot Shots with court by the BallR package
luka <- ggplot(nykvsdalshots, aes(x=locationX, y=locationY + 45)) + 
  geom_path(data = court_points,
            aes(x = x, y = y, group = desc),
            color = "white")+
  coord_equal()+
  geom_point(aes(fill=isShotMade), pch = 21,size=5,color="#272822") +
  scale_fill_manual(values = c("#a8ee90","#ff0040"),guide=FALSE)+
  scale_shape_discrete(guide = "legend") +
  xlim(-260, 260)+
  labs(title = "Luka Doncic vs New York Knicks", x= "",y="", subtitle = "60 points, December 27 2022",
       caption = "Emilio Conde | Data from: nbaStatR ")+
  theme(plot.title = element_text(face="bold", 
                                  size = 12, 
                                  hjust=0.7,
                                  color = "white"),
        plot.subtitle = element_text(face="italic",
                                     size = 8,
                                     hjust = 0.5,
                                     color = "white"),
        plot.background = element_rect(color ="#272822", fill = NA),
        panel.background  = element_rect(fill = "#272822"),
        axis.line = element_blank(),
        axis.ticks  = element_blank(),
        panel.grid = element_blank(),
        axis.text = element_blank(),
        plot.caption = element_text(color="white",
                                    size = 4))+
  transition_states(idEvent, transition_length = 1, state_length = 4)+shadow_mark()

# Specify animation output, high resolution and background color  
DBcourtanim <- animate(luka, res= 300,height=1000,width=1000,bg="#272822")

# Save file
anim_save("lukashotchart.gif", DBcourtanim)
