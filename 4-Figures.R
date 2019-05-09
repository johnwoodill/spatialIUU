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
library(marmap)

GAPI_Key <- file("~/Projects/Anomalous-IUU-Events-Argentina/Google_api_key.txt", "r")
GAPI_Key <- readLines(GAPI_Key)
register_google(key=GAPI_Key)






#------------------------------------------
# Figure 1: Map, NN, and distr
{
dat <- as.data.frame(read_feather('~/Projects/Anomalous-IUU-Events-Argentina/data/Argentina_5NN_region1_2016-03-01_2016-03-31.feather'))
dat$month <- month(dat$timestamp)
dat$day <- day(dat$timestamp)
dat$hour <- hour(dat$timestamp)
dat$year <- year(dat$timestamp)
dat$min <- minute(dat$timestamp)

dat$month <- stringr::str_pad(dat$month, 2, side = "left", pad = 0)
dat$day <- stringr::str_pad(dat$day, 2, side = "left", pad = 0)
dat$hour <- stringr::str_pad(dat$hour, 2, side = "left", pad = 0)
dat$min <- stringr::str_pad(dat$min, 2, side = "left", pad = 0)

dat$ln_distance <- log(1 + dat$distance)

fig1_dat <- filter(dat, month == "03" & day == "15" & hour == "12" & NN <= 1)

# Puerto Madryn
#-42.7694° S, -65.0317° W

# Correct 4/24/2019
bat <- getNOAA.bathy(-68, -51, -48, -39, res = 1, keep = TRUE)


date_ <- paste0(fig1_dat$year[1], "-", fig1_dat$month[1], "-", fig1_dat$day[1], " ", fig1_dat$hour[1], ":", fig1_dat$min[1], ":00")
date_

map2 <- 
  # ggplot(bat, aes(x, y, z)) +
  autoplot(bat, geom = c("raster", "contour")) +
  geom_raster(aes(fill=z)) +
  geom_contour(aes(z = z), colour = "white", alpha = 0.05) +
  scale_fill_gradientn(values = scales::rescale(c(-6600, 0, 1, 1500)),
                       colors = c("lightsteelblue4", "lightsteelblue2", "#C6E0FC", 
                                  "grey50", "grey70", "grey85")) +
  labs(x=NULL, y=NULL, color="km") +
  geom_segment(data=fig1_dat, aes(x=vessel_A_lon, xend=vessel_B_lon, y=vessel_A_lat, yend=vessel_B_lat, color=distance), size = 0.1) +
  geom_segment(data=fig1_dat, aes(x=vessel_B_lon, xend=vessel_A_lon, y=vessel_B_lat, yend=vessel_A_lat, color=distance), size = 0.1) +
  geom_point(data=fig1_dat, aes(x=vessel_B_lon, y=vessel_B_lat), size = 0, color='blue') +
  geom_point(data=fig1_dat, aes(x=vessel_A_lon, y=vessel_A_lat), size = 0, color='red') +
  annotate("text", x=-53.75, y = -39.25, label=date_, size = 4, color='black', fontface=2) +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        legend.direction = 'vertical',
        legend.justification = 'center',
        legend.position = c(.95, 0.24),
        legend.margin=margin(l = 0, unit='cm'),
        legend.text = element_text(size=10),
        legend.title = element_text(size=12),
        panel.grid = element_blank()) +
  scale_color_gradientn(colours=brewer.pal(9, "OrRd"), limits=c(0, 100)) +
  
  # Legend up top
  guides(fill = FALSE,
         color = guide_colorbar(title.hjust = unit(1.1, 'cm'),
                                title.position = "top",
                                frame.colour = "black",
                                barwidth = .5,
                                barheight = 7,
                                label.position = 'left')) +
  annotate("segment", x=-Inf, xend=Inf, y=-Inf, yend=-Inf, color = "black", size=1) + #Bottom
  annotate("segment", x=-Inf, xend=-Inf, y=-Inf, yend=Inf, color = "black", size=1) + # Left
  annotate("segment", x=Inf, xend=Inf, y=-Inf, yend=Inf, color = "black", size=1) + # Right
  annotate("segment", x=-Inf, xend=Inf, y=Inf, yend=Inf, color = "black", size=1) + # Top
  # scale_y_continuous(expand=c(0,0)) +
  # scale_x_continuous(expand=c(0,0)) +
  NULL

map2


# Figure 1b
fig1b <- ggplot(filter(fig1_dat, distance != 0), aes(log(1 + distance))) + 
  geom_histogram(aes(y=..density..), position = "dodge") +
  annotate("segment", x=-Inf, xend=Inf, y=-Inf, yend=-Inf, color = "black") +
  annotate("segment", x=-Inf, xend=-Inf, y=-Inf, yend=Inf, color = "black") +
  annotate("segment", x=Inf, xend=Inf, y=-Inf, yend=Inf, color = "black") +
  annotate("segment", x=Inf, xend=-Inf, y=Inf, yend=Inf, color = "black") +
  theme_tufte(13) +
  labs(y="Probability", x="Distance (log km)")
fig1b


# Panel plot
ggdraw() + draw_plot(map2, 0, .175, height = 1, width = 1) +
  draw_plot(map1, .65, .368, height = .26, width = .25) +
  draw_plot(fig1b, 0, 0, height = .385, width = 1)

ggsave(filename = "~/Projects/Anomalous-IUU-Events-Argentina/figures/figure1.pdf", width = 6, height = 7)
ggsave(filename = "~/Projects/Anomalous-IUU-Events-Argentina/figures/figure1.png", width = 6, height = 8)

#--------------------------------------------------------------
# Animated Plot
dat <- as.data.frame(read_feather('~/Projects/Anomalous-IUU-Events-Argentina/data/Puerto_Madryn_5NN_region1_2016-3-1_2016-4-1.feather'))
dat$month <- month(dat$timestamp)
dat$day <- day(dat$timestamp)
dat$hour <- hour(dat$timestamp)
dat$year <- year(dat$timestamp)
dat$min <- minute(dat$timestamp)
dat$ln_distance <- log(1 + dat$distance)

dat$month <- stringr::str_pad(dat$month, 2, side = "left", pad = 0)
dat$day <- stringr::str_pad(dat$day, 2, side = "left", pad = 0)
dat$hour <- stringr::str_pad(dat$hour, 2, side = "left", pad = 0)
dat$min <- stringr::str_pad(dat$min, 2, side = "left", pad = 0)

movdat <- dat

# movdat <- filter(movdat, vessel_A_lon >= -64 & vessel_A_lon <= -51)
# movdat <- filter(movdat, vessel_A_lat >= -48 & vessel_A_lat <= -39)
# 
# movdat <- filter(movdat, vessel_B_lon >= -64 & vessel_B_lon <= -51)
# movdat <- filter(movdat, vessel_B_lat >= -48 & vessel_B_lat <= -39)

NN_max <- 3

movdat <- filter(movdat, NN <= NN_max)
movdat <- filter(movdat, month == "03")

#i = movdat$timestamp[100000]
i = "2016-03-15 12:00:00"
i = "2016-03-15 19:00:00"
i = "2016-03-29 00:00:00"

for (i in unique(movdat$timestamp)){
  
  subdat <- filter(movdat, timestamp == i)
  
  # REMOVE !!!!
  
  # bat <- getNOAA.bathy(-68, -51, -48, -39, res = 1, keep = TRUE)
  
  # Subsets out region but need to fix code to subset out vessels on land
  
  # Southern Zone
  # subdat1 <- filter(subdat, vessel_A_lon >= -62.965677 & vessel_A_lon <= -51)
  # subdat1 <- filter(subdat1, vessel_B_lon >= -62.965677 & vessel_B_lon <= -51)
  # 
  # subdat1 <- filter(subdat1, vessel_A_lat <= -41.320881 & vessel_A_lat >=-48)
  # subdat1 <- filter(subdat1, vessel_B_lat <= -41.320881 & vessel_B_lat >= -48)
  # 
  # # Northern Zone
  # subdat2 <- filter(subdat, vessel_A_lon >= -61.506078 & vessel_A_lon <= -51)
  # subdat2 <- filter(subdat2, vessel_B_lon >= -61.506078 & vessel_B_lon <= -51)
  # 
  # subdat2 <- filter(subdat2, vessel_A_lat <= -39.334430 & vessel_A_lat >= -41.320881)
  # subdat2 <- filter(subdat2, vessel_B_lat <= -39.334430 & vessel_B_lat >= -41.320881)
  # 
  # subdat <- rbind(subdat1, subdat2)
  # 
  # subdat <- subdat2
  # 
  # nv_2 <- subdat %>% 
  #   group_by(month, day, hour, vessel_A) %>% 
  #   summarise(nn = n()) %>% 
  #   filter(nn == NN_max + 1) %>% 
  #   ungroup()
  # 
  # nv_3 <- subdat %>% 
  #   group_by(month, day, hour, vessel_B) %>% 
  #   summarise(nn = n()) %>% 
  #   filter(nn == NN_max + 1) %>% 
  #   ungroup()
    
  
  # subdat <- filter(subdat, (vessel_A %in% unique(nv_2$vessel_A)) |  (vessel_B %in% unique(nv_3$vessel_B)))
  
  #-----------------------------------------------
  #-----------------------------------------------
  
  date_ <- paste0(subdat$year[1], "-", subdat$month[1], "-", subdat$day[1], " ", subdat$hour[1], ":", subdat$min[1], ":00")
  date_
  
  #  #C6E0FC
  
  movmap <- 
    # ggplot(bat, aes(x, y, z)) +
    autoplot(bat, geom = c("raster", "contour")) +
    geom_raster(aes(fill=z)) +
    geom_contour(aes(z = z), colour = "white", alpha = 0.05) +
    scale_fill_gradientn(values = scales::rescale(c(-6600, 0, 1, 1500)),
                         colors = c("lightsteelblue4", "lightsteelblue2", "#C6E0FC", 
                                    "grey50", "grey70", "grey85")) +
    labs(x=NULL, y=NULL, color="km") +
    geom_segment(data=subdat, aes(x=vessel_A_lon, xend=vessel_B_lon, y=vessel_A_lat, yend=vessel_B_lat, color=distance), size = 0.1) +
    geom_segment(data=subdat, aes(x=vessel_B_lon, xend=vessel_A_lon, y=vessel_B_lat, yend=vessel_A_lat, color=distance), size = 0.1) +
    geom_point(data=subdat, aes(x=vessel_B_lon, y=vessel_B_lat), size = 0, color='blue') +
    geom_point(data=subdat, aes(x=vessel_A_lon, y=vessel_A_lat), size = 0, color='red') +
    annotate("text", x=-53.75, y = -39.25, label=date_, size = 4, color='black', fontface=2) +
    theme(axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          axis.title.y=element_blank(),
          axis.text.y=element_blank(),
          axis.ticks.y=element_blank(),
          legend.direction = 'vertical',
          legend.justification = 'center',
          legend.position = c(.95, 0.24),
          legend.margin=margin(l = 0, unit='cm'),
          legend.text = element_text(size=10),
          legend.title = element_text(size=12),
          panel.grid = element_blank()) +
    scale_color_gradientn(colours=brewer.pal(9, "YlOrRd"), limits=c(0, 200)) +
    
    # Legend up top
    guides(fill = FALSE,
           color = guide_colorbar(title.hjust = unit(1.1, 'cm'),
                                  title.position = "top",
                                  frame.colour = "black",
                                  barwidth = .5,
                                  barheight = 7,
                                  label.position = 'left')) +
    annotate("segment", x=-Inf, xend=Inf, y=-Inf, yend=-Inf, color = "black", size=1) + #Bottom
    annotate("segment", x=-Inf, xend=-Inf, y=-Inf, yend=Inf, color = "black", size=1) + # Left
    annotate("segment", x=Inf, xend=Inf, y=-Inf, yend=Inf, color = "black", size=1) + # Right
    annotate("segment", x=-Inf, xend=Inf, y=Inf, yend=Inf, color = "black", size=1) + # Top
    # scale_y_continuous(expand=c(0,0)) +
    # scale_x_continuous(expand=c(0,0)) +
    NULL
  # movmap
  
  # ggsave(filename="~/Projects/test.pdf", movmap, width=6, height=4)

  ggsave(filename = paste0("~/Projects/Anomalous-IUU-Events-Argentina/figures/animation/hourly_figures/NN3/", date_, ".png"), width = 6, height = 4, plot = movmap)
}

#------------------------------------------
# Figure 2: Distance (log transformation))

# (A)
{
  dat <- as.data.frame(read_feather('~/Projects/Anomalous-IUU-Events-Argentina/data/Argentina_5NN_region1_2016-03-01_2016-03-31.feather'))
  dat <- dat %>% 
    mutate(day = day(timestamp),
           hour = hour(timestamp),
           month = month(timestamp)) %>% 
    filter(month == 3) %>%
    filter(day >= 10 & day <= 20) %>% 
    filter(distance != 0) %>% 
    group_by(timestamp, vessel_A) %>% 
    summarise(distance = mean(distance),
              ln_distance = mean(log(1 + distance)))
  
  dat2$date <- paste0(year(dat2$timestamp), "-", month(dat2$timestamp), "-", day(dat2$timestamp), "-", hour(dat2$timestamp))
  
  cdat <- cut(dat$ln_distance, breaks = 50)
  
  dat$breaks <- cdat 
  dat$bin <- as.numeric(dat$breaks)
  
  
  char <- unique(cdat)
  retdat <- data.frame()
  for (j in char){
    ldat <- data.frame(a = as.numeric(strsplit(gsub("\\[|\\]|\\(|\\)", "", j), ",")[[1]][1]),
                       b = as.numeric(strsplit(gsub("\\[|\\]|\\(|\\)", "", j), ",")[[1]][2]))
    retdat <- rbind(retdat, ldat)
  }
  
  outdat <- dat %>% 
    group_by(timestamp) %>% 
    mutate(nvessels = n()) %>% 
    group_by(timestamp, bin, nvessels) %>% 
    summarise(nbin_vessels = n()) %>% 
    mutate(prob = nbin_vessels/nvessels) %>% 
    ungroup()
  
  outdat %>% 
    group_by(timestamp) %>% 
    summarise(sum = sum(prob))
  
  # savedat <- outdat %>% 
  #   mutate(day = day(timestamp)) %>% 
  #   filter(day >= 10 & day <= 20) %>% 
  #   dplyr::select(timestamp, bin, prob) %>% 
  #   spread(key=timestamp, value=prob)
  # write_feather(savedat, "~/Projects/Anomalous-IUU-Events-Argentina/data/heatmap_ln_distance_matrix_March10-20.feather")
  # 
  outdat$day <- day(outdat$timestamp)
  
  
  outdat$timestamp
  as.Date.POSIXct(outdat$timestamp, c("%Y-%m-%d %h:00:00 PST"))
  outdat$timestamp <- as.POSIXct(outdat$timestamp)
  
  sb <- c(seq(5, 45, 5))
  # Get log feet to dispaly on left side
  ddat <- dat %>% 
    group_by(bin) %>% 
    summarise(m_dist = mean(ln_distance)) %>% 
    filter(bin %in% sb)
  ddat
  ddat$x <- as.POSIXct("2016-03-09 23:00:00")
  
  outdat <- filter(outdat, bin >= 5 & bin <= 45)
  outdat$day <- day(outdat$timestamp)
  a <- ifelse(outdat$day != 15, "black", "blue")

  
  
  fig2a <- ggplot(outdat, aes(x=timestamp, y=factor(bin))) + 
    geom_tile(aes(fill = prob)) +
    theme_tufte(14) +
    annotate("text", x=as.POSIXct("2016-03-20 6:00:00"), y = 43, label='(a)', size = 5, color  = "white") +
    labs(x="Day in March", y="Binned Distance (log km)", fill="P(d)") +
    geom_vline(xintercept = 14) +
    scale_x_datetime(date_breaks = "1 day",
                     date_labels = "%d",
                     labels = c(seq(10, 21, 1)),
                     breaks = seq(10, 21, 1),
                     expand = expand_scale(mult = c(0, 0))) +
    scale_y_discrete(breaks = c(5, 10, 15, 20, 25, 30, 35, 40, 45), 
                     labels = round(ddat$m_dist, 1), 
                     expand = c(0, 0)) +
    scale_fill_gradientn(colours=rev(brewer.pal(11, "Spectral")), na.value = 'salmon') +
    annotate("rect", xmin = as.POSIXct("2016-03-13 01:00:00"), 
             xmax = as.POSIXct("2016-03-17 01:00:00"),  
             ymin = 0, 
             ymax = 45, 
             colour="white", alpha=0.1) +
    # annotate(geom = "text", x = as.POSIXct("2016-03-15 00:00:00"), y = -3.5, label = c("asdf"), size = 5) +
    # coord_cartesian(ylim = c(0, 50), expand = FALSE, clip = "off") +
    annotate("text", x = as.POSIXct("2016-03-15 00:00:00"), y=43, label="Event Window", color='white') +
    theme(legend.position = 'right',
          legend.margin=margin(l = 0, unit='cm'),
          panel.border = element_rect(colour = "grey", fill=NA, size=1),
          panel.grid = element_blank(),
          panel.background=element_rect(fill="#5E4FA2", colour="#5E4FA2")) +
    guides(fill = guide_colorbar(label.hjust = unit(0, 'cm'),
                                 frame.colour = "black",
                                 barwidth = .5,
                                 barheight = 10)) +
    NULL
  
  fig2a
  
  #ggsave("~/Projects/Anomalous-IUU-Events-Argentina/figures/figure2a.pdf", width = 6, height = 4)
  



# (B)

# Figure 2 (B) 

  dat <- as.data.frame(read_feather("~/Projects/Anomalous-IUU-Events-Argentina/data/dmat_Puerto_Madryn_region1_NN5_day_2016-03-01_2016-04-01.feather"))
  
  dat$day <- seq(1, nrow(dat), 1)
  pdat <- gather(dat, key = day, value = value)
  
  pdat$day <- as.numeric(pdat$day) + 1
  pdat$day2 <- seq(1, length(unique(pdat$day)))
  
  fig2b <- ggplot(pdat, aes(x=day, y=day2)) + 
    theme_tufte(14) + 
    geom_tile(aes(fill=value)) +
    labs(y="Day in March", x="Day in March", fill="JSD \nMetric") +
    # scale_fill_gradient(low='white', high='red') +
    scale_fill_gradientn(colours=rev(brewer.pal(11, "Spectral"))) +
    scale_y_continuous(trans = "reverse", 
                       breaks = c(1, 5, 10, 15, 20, 25, 31),
                       labels = c(1, 5, 10, 15, 20, 25, 31), 
                       expand=expand_scale(mult = c(0, 0))) +
    scale_x_continuous(breaks = c(1, 5, 10, 15, 20, 25, 31), labels = c(1, 5, 10, 15, 20, 25, 31), expand=expand_scale(mult = c(0, 0))) +
    annotate("segment", x=-Inf, xend=Inf, y=-Inf, yend=-Inf, color = "black") +
    annotate("segment", x=-Inf, xend=-Inf, y=-Inf, yend=Inf, color = "black") +
    annotate("segment", x=Inf, xend=Inf, y=-Inf, yend=Inf, color = "black") +
    annotate("segment", x=Inf, xend=-Inf, y=Inf, yend=Inf, color = "black") +
    
    # Cluster 1
    annotate("segment", x=7, xend=7, y=0.5, yend=7, color = "black") +
    annotate("segment", x=0.5, xend=7, y=7, yend=7, color = "black") +
    # 
    # # Cluster 2
    annotate("segment", x=7, xend=22, y=7, yend=7, color = "black") +
    annotate("segment", x=7, xend=7, y=7, yend=22, color = "black") +
    annotate("segment", x=22, xend=22, y=7, yend=22, color = "black") +
    annotate("segment", x=7, xend=22, y=22, yend=22, color = "black") +
    # #
    # # Cluster 3
    annotate("segment", x=22, xend=22, y=22, yend=31.5, color = "black") +
    annotate("segment", x=22, xend=31.5, y=22, yend=22, color = "black") +
    # 
    annotate("text", x=4, y = 1, label='Cluster 1', size = 3) +
    annotate("text", x=19, y = 8, label='Cluster 2', size = 3) +
    annotate("text", x=29, y = 23, label='Cluster 3', size = 3) +
    annotate("text", x=30, y = 1.5, label='(b)', size = 5, color="white") +
    guides(fill = guide_colorbar(label.hjust = unit(0, 'cm'),
                                 frame.colour = "black",
                                 barwidth = .5,
                                 barheight = 12)) +
    coord_equal() +
    NULL
  fig2b
  
ggdraw() + draw_plot(fig2a, 0, .50, height = .50, width = 1) +
  draw_plot(fig2b, 0.01, -.25, height=1, width = 1)

ggsave("~/Projects/Anomalous-IUU-Events-Argentina/figures/figure2_log.png", width = 5, height = 8)
ggsave("~/Projects/Anomalous-IUU-Events-Argentina/figures/figure2_log.pdf", width = 5, height = 8)




#------------------------------------------
# Figure 3 - time-series of the trailing rate of change in JS divergence as an index of behavioral change
{
dat <- as.data.frame(read_feather("~/Projects/Anomalous-IUU-Events-Argentina/data/dmat_Puerto_Madryn_region1_NN5_day-hour_2016-03-01_2016-03-31.feather"))

d <- as.matrix(dat)
fit <- isoMDS(d, k=2)
stress <- fit$stress
isoMDS_dat <- data.frame(x = fit$points[, 1], y = fit$points[, 2])

# Hourly cluster
#Clusters: 

cluster1 <- c(190, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 313, 314, 315, 316, 317, 318)
cluster2 <- c(431, 319, 320, 321, 322, 323, 324, 325, 326, 327, 328, 329, 330, 331, 332, 333, 334, 335, 336, 337, 338, 339, 340, 341, 342, 343, 344, 345, 346, 347, 348, 349, 350, 351, 352, 353, 354, 355, 356, 357, 358, 359, 360, 361, 362, 363, 364, 365, 366, 367, 368, 369, 370, 371, 372, 373, 374, 375, 376, 377, 378, 379, 380, 381, 382, 383, 384, 385, 386, 387, 388, 389, 390, 391, 392, 393, 394, 395, 396, 397, 398, 399, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424, 425, 426, 427, 428, 429, 430, 432, 433, 434, 435, 436, 437, 438, 439, 440, 441, 442, 443, 444, 445, 446, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 491, 492, 493, 494, 495, 496, 497, 498, 499, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 512, 513, 514, 515, 516, 517, 518, 519, 520, 521, 522, 523, 527, 534)
cluster3 <- c(651, 524, 525, 526, 528, 529, 530, 531, 532, 533, 535, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 556, 557, 558, 559, 560, 561, 562, 563, 564, 565, 566, 567, 568, 569, 570, 571, 572, 573, 574, 575, 576, 577, 578, 579, 580, 581, 582, 583, 584, 585, 586, 587, 588, 589, 590, 591, 592, 593, 594, 595, 596, 597, 598, 599, 600, 601, 602, 603, 604, 605, 606, 607, 608, 609, 610, 611, 612, 613, 614, 615, 616, 617, 618, 619, 620, 621, 622, 623, 624, 625, 626, 627, 628, 629, 630, 631, 632, 633, 634, 635, 636, 637, 638, 639, 640, 641, 642, 643, 644, 645, 646, 647, 648, 649, 650, 652, 653, 654, 655, 656, 657, 658, 659, 660, 661, 662, 663, 664, 665, 666, 667, 668, 669, 670, 671, 672, 673, 674, 675, 676, 677, 678, 679, 680, 681, 682, 683, 684, 685, 686, 687, 688, 689, 690, 691, 692, 693, 694, 695, 696, 697, 698, 699, 700, 701, 702, 703, 704, 705, 706, 707, 708, 709, 710, 711, 712, 713, 714, 715, 716, 717, 718, 719, 720, 721, 722, 723, 724, 725, 726, 727, 728, 729, 730, 731, 732, 733, 734, 735, 736, 737, 738, 739, 740, 741, 742, 743)

# Medoids: [190, 431, 651]                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     


# Hours
isoMDS_dat$row <- seq(1, nrow(isoMDS_dat))

# Merge data for cluster factors
clustdat <- data.frame(cluster = c(rep(1, length(cluster1)),
                                   rep(2, length(cluster2)),
                                   rep(3, length(cluster3))),
                       row = c(cluster1, cluster2, cluster3))

# Merge data
isoMDS_dat <- left_join(isoMDS_dat, clustdat, by = 'row')

# Calc distance t and t+1
# 2-axis
isoMDS_dat$dist <- sqrt(((isoMDS_dat$x - isoMDS_dat$y)^2 + (lead(isoMDS_dat$x) - lead(isoMDS_dat$y)))^2)

# Remove last obs
isoMDS_dat <- filter(isoMDS_dat, !is.na(cluster) | !is.na(dist))
isoMDS_dat$dist

event_day <- filter(isoMDS_dat, row >= 12*24 & row <= 17*24)

ggplot(isoMDS_dat, aes(x, y, color = dist, shape = factor(cluster))) + 
  geom_point() +
  # geom_point(data=event_day, aes(x, y), color='red') +
  theme_tufte(13) +
  scale_color_gradientn(colours=brewer.pal(7,"YlGnBu")) +
  annotate("segment", x=-Inf, xend=Inf, y=-Inf, yend=-Inf, color = "grey") +
  annotate("segment", x=-Inf, xend=-Inf, y=-Inf, yend=Inf, color = "grey") +
  annotate("segment", x=Inf, xend=Inf, y=-Inf, yend=Inf, color = "grey") +
  annotate("segment", x=Inf, xend=-Inf, y=Inf, yend=Inf, color = "grey") +
  labs(x = "Dimension 1", 
       y= "Dimension 2", 
       color = "Distance", 
       shape = "Cluster",
       title = "Non-metric Multidimensional Scaling of JS-Distance \n March 1 - 31 2016 (Clustered by hour using k-medoids)") +
  theme(aspect.ratio=1,
        legend.position = c(.5, .80),
        legend.direction = 'horizontal',
        legend.justification = 'center',
        legend.title=element_text(size=8),
        legend.text = element_text(size=8),
        plot.title = element_text(hjust = 0.5)) +
  guides(color = guide_colorbar(order = 0, title.position = 'top', title.hjust = 0.5, barheight = .5),
        shape = guide_legend(order = 0, title.position = 'top', title.hjust = 0.5, barheight = .5)) +
  annotate("text", x = -0.11, y = -0.071, label = "k=2", size=2.5) +
  annotate("text", x = -0.11, y = -0.075, label = paste0("stress=", round(stress/100, 3)), size=2.5) +
  NULL

isoMDS_dat$speed <- isoMDS_dat$dist/1
  

# Color by speed (distance from day to lead(day))
fig3a <- ggplot(isoMDS_dat, aes(x, y, color = speed, shape = factor(cluster))) + geom_point() +
  theme_tufte(13) +
  # ylim(-0.12, .12) +
  # xlim(-0.12, 0.12) +
  scale_color_gradientn(colours=brewer.pal(7,"YlGnBu")) +
  annotate("segment", x=-Inf, xend=Inf, y=-Inf, yend=-Inf, color = "grey") +
  annotate("segment", x=-Inf, xend=-Inf, y=-Inf, yend=Inf, color = "grey") +
  annotate("segment", x=Inf, xend=Inf, y=-Inf, yend=Inf, color = "grey") +
  annotate("segment", x=Inf, xend=-Inf, y=Inf, yend=Inf, color = "grey") +
  labs(x = "Dimension 1", 
       y= "Dimension 2", 
       color = "Speed", 
       # title = "Non-metric Multidimensional Scaling of JS-Distance \n March 1 - 31 2016 (Clustered by hour using k-medoids)",
       shape = "Cluster") +
  theme(#aspect.ratio=1,
         legend.position = c(.5, .9),
        legend.box = "horizontal",
        legend.direction = 'horizontal',
        legend.justification = 'center',
        legend.title=element_text(size=8),
        legend.text = element_text(size=8),
        plot.title = element_text(hjust = 0.5)) +
  guides(color = guide_colorbar(order = 0, title.position = 'top', title.hjust = 0.5, barheight = .5),
         shape = guide_legend(order = 0, title.position = 'top', title.hjust = 0.5, barheight = .5)) +
  annotate("text", x = -0.08, y = -0.068, label = "k=2", size=2.5) +
  annotate("text", x = -0.08, y = -0.075, label = "stress=6.91", size=2.5) +
  # coord_equal() +
  NULL

fig3b <- ggplot(isoMDS_dat, aes(x=row, y=speed, color = factor(cluster))) + 
  geom_point(size=.8) +
  labs(x="Day of March", y="Speed of JS-Distance Divergence", color = "Cluster") +
  theme_tufte(13) +
  theme(legend.position = c(.5, .95),
        legend.box = "horizontal",
        legend.direction = 'horizontal',
        legend.justification = 'center',
        legend.title=element_text(size=8),
        legend.text = element_text(size=8),
        plot.title = element_text(hjust = 0.5)) +
  scale_x_continuous(breaks = c(1, 5*24, 10*24, 15*24, 20*24, 25*24, 31*24), labels = c(1, 5, 10, 15, 20, 25, 31)) +
  annotate("segment", x=-Inf, xend=Inf, y=-Inf, yend=-Inf, color = "grey") +
  annotate("segment", x=-Inf, xend=-Inf, y=-Inf, yend=Inf, color = "grey") +
  annotate("segment", x=Inf, xend=Inf, y=-Inf, yend=Inf, color = "grey") +
  annotate("segment", x=Inf, xend=-Inf, y=Inf, yend=Inf, color = "grey")

fig3b


ggdraw() + draw_plot(fig3a, 0, 0, height = 1, width = .5) +
  draw_plot(fig3b, .50, 0, height= 1, width = .5)

ggsave("~/Projects/Anomalous-IUU-Events-Argentina/figures/figure3.png", width = 10, height = 4)
ggsave("~/Projects/Anomalous-IUU-Events-Argentina/figures/figure3.pdf", width = 10, height = 4)


#------------------------------------------------------------------------
# 3-D plot
dat <- as.data.frame(read_feather("~/Projects/Anomalous-IUU-Events-Argentina/data/dmat_Puerto_Madryn_region1_NN5_day-hour_2016-03-01_2016-03-31.feather"))

d <- as.matrix(dat)
fit <- isoMDS(d, k=3)
stress <- fit$stress
isoMDS_dat <- data.frame(x = fit$points[, 1], y = fit$points[, 2], z = fit$points[, 3])

# Hours
isoMDS_dat$row <- seq(1, nrow(isoMDS_dat))

isoMDS_dat <- left_join(isoMDS_dat, clustdat, by = 'row')


# 3-axis
isoMDS_dat$dist <- sqrt(((isoMDS_dat$x - isoMDS_dat$y - isoMDS_dat$z)^2 + (lead(isoMDS_dat$x) - lead(isoMDS_dat$y) - lead(isoMDS_dat$z))^2))
isoMDS_dat$speed <- isoMDS_dat$dist/1

# Remove last obs
isoMDS_dat <- filter(isoMDS_dat, !is.na(cluster) | !is.na(dist))
isoMDS_dat$dist

# isoMDS_dat$event <- ifelse(isoMDS_dat$row >= 336, ifelse(isoMDS_dat$row <= 360, 1, 0), 0)
fig4a <- ggplot(isoMDS_dat, aes(x=x, y=y, z=z, color=speed, shape = factor(cluster))) + 
  scale_color_gradientn(colours=brewer.pal(7,"YlGnBu")) +
  labs(x = "Dimension 1", y= "Dimension 2", 
       color = "Speed", 
       # title = "Non-metric Multidimensional Scaling of JS-Distance \n March 1 - 31 2016 (Clustered by hour using k-medoids)",
       shape = "Cluster") +
  theme_void() +
  theme_tufte(13) +
  axes_3D() +
  stat_3D() +
  theme(#aspect.ratio=1,
        legend.position = c(.5, .9),
        legend.box = "horizontal",
        legend.direction = 'horizontal',
        legend.justification = 'center',
        legend.title=element_text(size=8),
        legend.text = element_text(size=8),
        plot.title = element_text(hjust = 0.5)) +
  guides(color = guide_colorbar(order = 0, title.position = 'top', title.hjust = 0.5, barheight = .5),
         shape = guide_legend(order = 0, title.position = 'top', title.hjust = 0.5, barheight = .5)) +
  annotate("segment", x=-Inf, xend=Inf, y=-Inf, yend=-Inf, color = "grey") +
  annotate("segment", x=-Inf, xend=-Inf, y=-Inf, yend=Inf, color = "grey") +
  annotate("segment", x=Inf, xend=Inf, y=-Inf, yend=Inf, color = "grey") +
  annotate("segment", x=Inf, xend=-Inf, y=Inf, yend=Inf, color = "grey") +
  annotate("text", x = -.25, y = -0.32, label = paste0("stress=", round(stress/100, 3)), size=2.5) +
  annotate("text", x = -.25, y = -0.29, label = "k=3", size=2.5) +
  # coord_equal(ratio = 2) +
  NULL
fig4a

fig4b <- ggplot(isoMDS_dat, aes(x=row, y=speed, color = factor(cluster))) + 
  geom_point(size=.8) +
  labs(x="Day of March", y="Speed of JS-Distance Divergence", color = "Cluster") +
  theme_tufte(13) +
  theme(legend.position = c(.5, .95),
        legend.box = "horizontal",
        legend.direction = 'horizontal',
        legend.justification = 'center',
        legend.title=element_text(size=8),
        legend.text = element_text(size=8),
        plot.title = element_text(hjust = 0.5)) +
  # scale_x_continuous(breaks = seq(1, length(isoMDS_dat$x), 24), labels = seq(1, 31, 1)) +
  scale_x_continuous(breaks = c(1, 5*24, 10*24, 15*24, 20*24, 25*24, 31*24), labels = c(1, 5, 10, 15, 20, 25, 31)) +
  annotate("segment", x=-Inf, xend=Inf, y=-Inf, yend=-Inf, color = "grey") +
  annotate("segment", x=-Inf, xend=-Inf, y=-Inf, yend=Inf, color = "grey") +
  annotate("segment", x=Inf, xend=Inf, y=-Inf, yend=Inf, color = "grey") +
  annotate("segment", x=Inf, xend=-Inf, y=Inf, yend=Inf, color = "grey") +
  NULL

fig5b

ggdraw() + draw_plot(fig4a, 0, 0, height = 1, width = .5) +
  draw_plot(fig4b, .50, 0, height= 1, width = .5)

ggsave("~/Projects/Anomalous-IUU-Events-Argentina/figures/figure4.pdf", width = 10, height = 4)
ggsave("~/Projects/Anomalous-IUU-Events-Argentina/figures/figure4.png", width = 10, height = 4)

