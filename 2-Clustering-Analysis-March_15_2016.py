import pandas as pd
from scipy import stats
import numpy as np
from dit.divergences import jensen_shannon_divergence
import matplotlib.pyplot as plt
from scipy.spatial import distance
import seaborn as sns
import scipy.spatial.distance as ssd
import random
from pyclustering.cluster.kmedoids import kmedoids
from pyclustering.cluster import cluster_visualizer, cluster_visualizer_multidim
from pyclustering.cluster.kmedoids import kmedoids
from pyclustering.utils import read_sample
from pyclustering.utils import timedcall
from scipy.cluster.hierarchy import dendrogram, linkage
import scipy.spatial.distance as ssd

import spatialIUU.distanceMatrix as dm

def k_medoids(distMatrix, interval, init_medoids):
    distMatrix = np.array(distMatrix)

    # K-Medoids Clustering
    #initial_medoids = [30, 90, 140]

    initial_medoids = init_medoids
    # create K-Medoids algorithm for processing distance matrix instead of points
    kmedoids_instance = kmedoids(
        distMatrix, initial_medoids, data_type='distance_matrix', ccore=True)

    # run cluster analysis and obtain results
    kmedoids_instance.process()

    clusters = kmedoids_instance.get_clusters()
    medoids = kmedoids_instance.get_medoids()
    print(f"Clusters: {clusters}   Medoids: {medoids}")

    final_list = []
    for i, l in enumerate(clusters):
        for num in l:
            final_list.append({'value': num, 'group': i})

    df = pd.DataFrame(final_list)
    return(df)


# Puerto Madryn March 1-31 Region 1
# Import data
dat = pd.read_feather('~/Projects/Anomalous-IUU-Events-Argentina/data/Argentina_5NN_region1_2016-03-01_2016-03-31.feather')

# Day
# NN = 5
distMatrix, distArray = dm.d_matrix(dat, interval='day', NN=1)
pdat2 = k_medoids(distMatrix, interval='day', init_medoids=[2, 5, 8])

distMatrix = pd.DataFrame(distMatrix)
distMatrix.columns = distMatrix.columns.astype(str)

# h_cluster(distArray)
distMatrix.to_feather(
    '~/Projects/Anomalous-IUU-Events-Argentina/data/dmat_Puerto_Madryn_region1_NN5_day_2016-03-01_2016-04-01.feather')


# Day by hour
# NN = 5
distMatrix_dh, distArray_dh = dm.d_matrix(dat, interval='dayhour', NN=1)
pdat3 = k_medoids(distMatrix_dh, interval='dayhour',
                  init_medoids=[144, 360, 480])

# Convert matrix to data.frame
distMatrix_dh = pd.DataFrame(distMatrix_dh)
distMatrix_dh.columns = distMatrix_dh.columns.astype(str)

# Save distance matrix
distMatrix_dh.to_feather(
    '~/Projects/Anomalous-IUU-Events-Argentina/data/dmat_Puerto_Madryn_region1_NN5_day-hour_2016-03-01_2016-03-31.feather')


