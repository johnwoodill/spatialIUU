library(tidyverse)
library(lubridate)
library(ggmap)
library(cowplot)
library(gridExtra)
library(ggthemes)
library(feather)
library(RColorBrewer)
library(MASS)
library(plotly)
library(gg3D)


#------------------------------------------
# Figure 3
{
  dat <- as.data.frame(read_feather('~/Projects/Anomalous-IUU-Events-Argentina/data/Argentina_5NN_region1_2016-03-01_2016-03-31.feather'))
  fig3 <- filter(dat, distance != 0)
  fig3 <- filter(fig3, NN <= 1)
  fig3$ln_distance <- log(1 + fig3$distance)
  fig3$month <- month(fig3$timestamp)
  fig3$day <- day(fig3$timestamp)
  fig3$hour <- hour(fig3$timestamp)
  
  fig3 <- filter(fig3, month == 3)
  
  jsd_dat <- data.frame()
  for (i in unique(fig3$timestamp)){
    p <- filter(fig3, timestamp == i )
    q <- filter(fig3, timestamp == i + 60*60) # Plus 1 hour (60 seconds * 60 minutes)
    date = p$timestamp[1]
    p <- p$distance
    q <- q$distance
    qmin <- length(q)
    pmin <- length(p)
    minobs <- min(qmin, pmin)
    lst <- data.frame()
    for (j in 1:10){
      pp <- sample(p, minobs, replace = TRUE)
      qq <- sample(q, minobs, replace = TRUE)
      js <- JSD(qq, pp)
      indat <- data.frame(js = sqrt(js))
      lst <- rbind(lst, indat)
    }
    outdat <- data.frame(t = date, jsd_mean = mean(lst$js), jsd_sd = sd(lst$js))
    jsd_dat <- rbind(jsd_dat, outdat)
  }
  
  jsd_dat$day <- day(jsd_dat$t)
  jsd_dat$hour <- hour(jsd_dat$t)
  jsd_dat2 <- jsd_dat %>% 
    group_by(t) %>% 
    summarise(jsd_mean = mean(jsd_mean))
  
jsd_dat2$day <- seq(1, nrow(jsd_dat2), 1)

ggplot(jsd_dat2, aes(x=day, y=jsd_mean)) + 
  theme_tufte(13) +
  geom_point() +
  labs(x="Day in March", y="JS-Distance (t, t+1)") +
  theme(panel.border = element_rect(colour = "grey", fill=NA, size=1)) +
  scale_x_continuous(breaks = c(1, 5*24, 10*24, 15*24, 20*24, 25*24, 31*24), labels = c(1, 5, 10, 15, 20, 25, 31)) +
  NULL

ggsave("~/Projects/Anomalous-IUU-Events-Argentina/supp_figures/leading_JS.png", width=6, height=4)
ggsave("~/Projects/Anomalous-IUU-Events-Argentina/supp_figures/leading_JS.pdf", width=6, height=4)
  