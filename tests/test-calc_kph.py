from datetime import datetime, timedelta
import pandas as pd
import numpy as np 
import spatialIUU.processGFW as siuu
import pytest

def test_calc_kph():
    # Distance from San Diego to San Francisco
    # San Diego: lat 32.7157 lon -117.1611
    # San Francisco: lat 37.7749 lon -122.4194
    data = pd.DataFrame({'timestamp': ['2019-01-01 00:00:00 UTC', '2019-01-01 01:00:00 UTC'], 'lat': [32.7157, 37.7749], 'lon': [-117.1611, -122.4194]})

    dist = siuu.calc_kph(data)
    kph = round(dist.kph.sum(),0)
    assert (kph == 738)