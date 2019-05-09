import os, pathlib
import pytest


test = [f"{pathlib.Path.cwd()}/tests/internal-test-processGFW.py"]
pytest.main(test)


