
import spatialIUU.processGFW as siuu


# Set global constants
global GFW_DIR, GFW_OUT_DIR_CSV, GFW_OUT_DIR_FEATHER, PROC_DATA_LOC, MAX_SPEED, REGION, lon1, lon2, lat1, lat2

siuu.GFW_DIR = '/data2/GFW_point/'
siuu.GFW_OUT_DIR_CSV = '/home/server/pi/homes/woodilla/Data/GFW_point/Patagonia_Shelf/csv/'
siuu.GFW_OUT_DIR_FEATHER = '/home/server/pi/homes/woodilla/Data/GFW_point/Patagonia_Shelf/feather/'
siuu.PROC_DATA_LOC = '/home/server/pi/homes/woodilla/Projects/Anomalous-IUU-Events-Argentina/data/'
siuu.REGION = 'Argentina'
siuu.MAX_SPEED = 40

siuu.region = 1
siuu.lon1 = -68
siuu.lon2 = -51
siuu.lat1 = -48
siuu.lat2 = -39


# First event: 
# https://www.cnn.com/2016/03/15/americas/argentina-chinese-fishing-vessel/index.html
siuu.compileData('2016-03-01', '2016-03-31', 1, parallel=True, ncores=20)


# Second event: Feb 2, 2018
# http://www.laht.com/article.asp?CategoryId=14093&ArticleId=2450374
siuu.compileData('2018-01-15', '2018-02-15', 1, parallel=True, ncores=10)


# Third event: Feb 21, 2018
# https://www.reuters.com/article/us-argentina-china-fishing/argentina-calls-for-capture-of-five-chinese-fishing-boats-idUSKCN1GK35T
siuu.compileData('2018-02-01', '2018-03-10', 1, parallel=True, ncores=10)

# beg_date = '2016-03-14'
# end_date = '2016-03-16'
# region = 1
# parallel=True
# ncores=6