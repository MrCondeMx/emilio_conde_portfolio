# Libraries
library(tidyverse)
library(gridExtra)
library(grid)
library(ggimage)
library(nbastatR)
library(stringi)
library(scales)

# Increase connection size
Sys.setenv(VROOM_CONNECTION_SIZE = "500000")

# Retrieve player headshots from nbastatR
players_data <- nba_players() %>% 
  select(namePlayer,urlPlayerHeadshot)

# Data manipulation was done with SQL.
# Source: https://www.kaggle.com/datasets/lukedip/nba-boxscore-dataset
# Minimum data manipulation done with R. Full SQL queries are on the github folder

nba_leaders <- read.csv("nba_leaders.csv") %>% 
  rename (fg_perc = metric_value,
          namePlayer = player,
          "PPG"=ppg,
          "3P%"=three_pointer_percentage,
          "Assists" = assists,
          "Rebounds" = rebounds) %>% 
  mutate(metric_rank = as.numeric(metric_rank),
         namePlayer = stri_trans_general(namePlayer, "Latin-ASCII"), # Mutate special characters
         namePlayer = recode(namePlayer,"J.J. Redick" = "JJ Redick",
                             "Marcus Morris"= "Marcus Morris Sr.",
                             "Robert Williams"= "Robert Williams III"), # Change player names to match headshot
         metric_name=recode(metric_name, "3PT Percentage" = "3P%")) %>% 
  left_join(players_data, by = "namePlayer") %>% 
  filter(metric_name %in% c("Points Per Game","3P%","Assists","Rebounds"))
  

nba_long <- gather(nba_leaders, key="measure", value="value", c("PPG","3P%","Assists","Rebounds")) %>% # Put df in large format
  filter(!is.na(value)) %>% 
  mutate(metric_rank = rank(value),#Rank each player
         measure = factor(measure, levels = c("3P%","PPG", "Assists", "Rebounds")))  # Specify order, useful for later plot
  


# Plot faceted chart

set.seed(123)
# Split the data by measure
nba_split <- split(nba_long, nba_long$measure)

# Create a list to store the plots
plot_list <- list()

p <- for(i in names(nba_split)){
  plot_list[[i]] <- ggplot(nba_split[[i]], aes(x= reorder(metric_rank, namePlayer), y=value)) +
    geom_image(aes(image = urlPlayerHeadshot), size =0.3, asp = 1)+
    ylab(i)+
    labs(x="")+ theme_minimal()+
    facet_grid(~season_id, scales = "free", space = "free_x")+
    theme(axis.text.x = element_blank(),
          axis.ticks = element_blank())
  # Add percentage format to y axis if measure is "3P%"
  if(i == "3P%") {
    plot_list[[i]] <- plot_list[[i]] + 
      scale_y_continuous(labels = percent_format(), limits = c(0.41,0.51), breaks = seq(0.40,0.5, by=0.02))
  }
  # Format axis limits manually
  if(i== "PPG"){
    plot_list[[i]] <- plot_list[[i]]+
      scale_y_continuous(limits = c(24,37), breaks = seq(24,36, by=3))
  }
  
  if(i== "Assists"){
    plot_list[[i]] <- plot_list[[i]]+
      scale_y_continuous(limits = c(7.3,12), breaks = seq(8,12, by=1))
  }
  
  if(i== "Rebounds"){
    plot_list[[i]] <- plot_list[[i]]+
      scale_y_continuous(limits = c(11,16.5), breaks = seq(11,16,by=1))
  }
}

# Use grid.arrange from the gridExtra package to arrange the plots
grid_arranged <- gridExtra::grid.arrange(grobs = plot_list, ncol = 1, 
                        top= grid::textGrob("NBA Season Leaders: Past 10 Years",
                                                                         gp= grid::gpar(fontsize=25, fontface = "bold")),
                        bottom = grid::textGrob("@MrCondeMx | Data from: NBA Stats and Basketball Reference | All statistical minimums to qualify for NBA league leaders",
                                                x=1, hjust = 1.02,
                                                gp = grid::gpar(fontsize = 7, fontface = "italic")))

# Twitter save
ggsave("NBA_SEASON_LEADERS.jpeg", grid_arranged, dpi = 700, width = 3500/300, height = 2500/300, units = "in")

# High res save
ggsave("nbaseasonleaders.jpeg", grid_arranged, dpi = 1500, width = 3500/300, height = 2500/300, units = "in")


