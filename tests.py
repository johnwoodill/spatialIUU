import os, pathlib
import pytest


test = [f"{pathlib.Path.cwd()}/tests/test-processGFW.py"]
pytest.main(test)



