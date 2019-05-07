# Set folder parent directory to check modules
import sys
import spatialIUU.processGFW as siuu
import pytest

def test_spherical_dist_populate():
    
    # Paris to Amsterdam in km
    # Paris lat = 48.8566 lon = 2.3522
    # Amsterdam lat = 52.3680 lon = 4.9036
    # Distance 430km
    #gfwD = dataStep
    dist = round(siuu.spherical_dist_populate([48.8566, 52.3680], [2.3522, 4.9036])[1][0], 0)
    assert (dist == 430)