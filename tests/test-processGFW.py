from datetime import datetime, timedelta
import pandas as pd
import numpy as np 
import spatialIUU.processGFW as siuu
import sys
import pytest

def test_calc_kph():
    # Distance from San Diego to San Francisco
    # San Diego: lat 32.7157 lon -117.1611
    # San Francisco: lat 37.7749 lon -122.4194
    data = pd.DataFrame({'timestamp': ['2019-01-01 00:00:00 UTC', '2019-01-01 01:00:00 UTC'], 'lat': [32.7157, 37.7749], 'lon': [-117.1611, -122.4194]})

    dist = siuu.calc_kph(data)
    kph = round(dist.kph.sum(),0)
    assert (kph == 738)


def test_spherical_dist_populate():
    
    # Paris to Amsterdam in km
    # Paris lat = 48.8566 lon = 2.3522
    # Amsterdam lat = 52.3680 lon = 4.9036
    # Distance 430km
    #gfwD = dataStep
    dist = round(siuu.spherical_dist_populate([48.8566, 52.3680], [2.3522, 4.9036])[1][0], 0)
    assert (dist == 430)



def test_interp_hr():
    data = pd.DataFrame({'timestamp': pd.to_datetime(['2020-11-03 16:00:00', '2020-11-04 16:00:00']),
                     'lat': [38.9072, 55.7558],
                     'lon': [77.0369, 37.6173],
                     'mmsi': ['20-18-21-13-16', '20-18-21-13-16']})

    test_dat = siuu.interp_hr(data, data.timestamp[0], data.timestamp[1])
    time_diff = (test_dat.timestamp[24] - test_dat.timestamp[0]).total_seconds()
    assert (time_diff == (24*60*60))



