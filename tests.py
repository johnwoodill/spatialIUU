import os, pathlib
import pytest


test1 = [f"{pathlib.Path.cwd()}/tests/test-processGFW.py"]
test2 = [f"{pathlib.Path.cwd()}/tests/test-distanceMatrix.py"]
pytest.main(test1)
pytest.main(test2)



