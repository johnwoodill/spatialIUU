# Set folder parent directory to check modules
import sys
import spatialIUU.processGFW as siuu
import pytest

def test_GFW_dir():
    # Test directory exists and has 3 years of data
    GFW_DIR = '/data2/GFW_point/'
    tdat = siuu.GFW_directories(GFW_DIR)
    assert (len(tdat) >= 3)
    
# (INCOMPLETE)
# Set global constants
# global DFW_DIR, GFW_OUT_DIR_CSV, GFW_OUT_DIR_FEATHER, PROC_DATA_LOC, MAX_SPEED, REGION, lon1, lon2, lat1, lat2

# GFW_DIR = '/data2/GFW_point/'
# GFW_OUT_DIR_CSV = '/home/server/pi/homes/woodilla/Data/GFW_point/Patagonia_Shelf/csv/'
# GFW_OUT_DIR_FEATHER = '/home/server/pi/homes/woodilla/Data/GFW_point/Patagonia_Shelf/feather/'
# PROC_DATA_LOC = '/home/server/pi/homes/woodilla/Projects/Puerto_Madryn_IUU_Fleet_Behavior/data/'
# REGION = 'TEST_Puerto_Madyrn'
# MAX_SPEED = 32
# region = 1
# lon1 = -68
# lon2 = -51
# lat1 = -48
# lat2 = -39

# # def compileData(beg_date, end_date, lon1, lon2, lat1, lat2, region, parallel=False, ncores=None):

# compileData('2016-03-01', '2016-04-01', 1, parallel=True, ncores=10)

# beg_date = '2016-03-14'
# end_date = '2016-03-16'
# region = 1
# parallel=True
# ncores=6
# compileData