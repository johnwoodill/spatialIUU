import os, pathlib
import pytest


test1 = [f"{pathlib.Path.cwd()}/tests/test-calc_kph.py"]
test2 = [f"{pathlib.Path.cwd()}/tests/test-spherical_dist.py"]
pytest.main(test1)
pytest.main(test2)


