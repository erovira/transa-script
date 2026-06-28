# tests/conftest.py

import pytest
import ipdb
import logging
from pathlib import Path
import shutil

logger = logging.getLogger("__name__")


def pytest_addoption(parser):
    parser.addoption(
        "--exe",
        action="store",
        required=True,
        help="Executable to test",
    )


def resolve_exec_path(input_exe: str) -> Path:
    exec_path = Path(input_exe)

    if exec_path.is_dir():
        raise ValueError(f"Path '{exec_path}' is not an executable; is a directory.")

    if not exec_path.is_absolute():
        # Subprocess downstream needs an absolute path.
        exec_path = exec_path.resolve()

    # Final confirmation that we're working with an executable
    if shutil.which(exec_path) is None:
        raise ValueError(f"Path '{exec_path}' is not an executable; not an executable.")

    return exec_path


@pytest.fixture
def executable_path(request):

    exec_path = resolve_exec_path(input_exe=request.config.getoption("--exe"))

    return exec_path
