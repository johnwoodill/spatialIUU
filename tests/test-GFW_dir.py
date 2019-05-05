# Set folder parent directory to check modules
import sys
sys.path.insert(0,'..')
import spatialIUU.processGFW as siuu
import pytest

def test_GFW_dir():
    # Test directory exists and has 3 years of data
    tdat = siuu.dataStep.GFW_directories()
    assert (len(tdat) >= 3)
    