# Anticipating and Detection Illegal Maritime Activities from Anomalous Multiscale Fleet Behavior

### Watson and Woodill or Woodill and Watson

#### College of Earth, Ocean and Atmospheric Sciences, Oregon State University

-------------

The following repo provides reproducible results for the paper, "Anticipating and Detection Illegal Maritime Activities from Anomalous Multiscale Fleet Behavior". We utilize a novel  K-medoids classification algorithm to disentangle a specific pre, peri, and post specific IUU event in the Puerto Madryn Argentina region. Our main findings show multiscale spatial anomalies reveal a specific IUU event (cluster 2) in Puerto Madryn, Argentina. We also show the behavior of vessels is most similar during IUU events and less so outside the event window.

**Events:** 

March 15, 2016
https://www.cnn.com/2016/03/15/americas/argentina-chinese-fishing-vessel/index.html


Feb 2, 2018
http://www.laht.com/article.asp?CategoryId=14093&ArticleId=2450374



Feb 21, 2018
https://www.reuters.com/article/us-argentina-china-fishing/argentina-calls-for-capture-of-five-chinese-fishing-boats-idUSKCN1GK35T


--------------

**File Descriptions**

* `data/` - data available for release

* `figures/` - main figures

* `spatialIUU/` - custom classes and methods. See [spatialIUU repo](https://github.com/johnwoodill/spatialIUU) for additional information and build tests.

* `supp_figures/` - supplemental main figures

* `1-Data-step.py` - process pre-processed Global Fishing Watch (GFW) AIS data (not available).

* `2-Cluster-Analysis-March_15_2016.py` - K-medoids clustering analysis for March 15, 2016 event.

* `3-Cluster-Analysis-Robustness.py` - spatial and temporal checks

* `4-Figures.R` - main figures from the analysis.

* `5-Supp_figures.R` - supplement figures for additional events.


-------------



### **Figures**

**Figure 1: A) Map of the region with AIS points. B) NN distances for one vessel. C) Average NN distance distribution for a fleet.**

<p align="center">

<img align="center" width="500" src="https://github.com/johnwoodill/Anomalous-IUU-Events-Argentina/raw/master/figures/figure1.png?raw=true">

Figure 2: A) Heatmap time series of average NN distance distributions. B) Heatmap of JS divergence between hourly average NN distance distributions (row/cols ordered by clusters)

<p align="center">

<img align="center" width="500" src="https://github.com/johnwoodill/Anomalous-IUU-Events-Argentina/raw/master/figures/figure2_log.png?raw=true">


Figure 4: nMDS of JS-Divergence (2-dimensions)

<p align="center">

<img align="center" width="800" src="https://github.com/johnwoodill/Anomalous-IUU-Events-Argentina/raw/master/figures/figure3.png?raw=true">

Figure 5: nMDS of JS-Divergence (3-dimensions)

<p align="center">

<img align="center" width="800" src="https://github.com/johnwoodill/Anomalous-IUU-Events-Argentina/raw/master/figures/figure4.png?raw=true">

-------------

### *Supporting Figures*

Leading JS-Divergence (`t`, `t+1`)

<p align="center">

<img align="center" width="500" src="https://github.com/johnwoodill/Puerto_Madryn_IUU_Fleet_Behavior/raw/master/figures/supporting/leading_JS.png?raw=true">

