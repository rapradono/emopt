import py_compile
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
EXAMPLES_DIR = REPO_ROOT / "examples"


def _example_scripts():
    return sorted(EXAMPLES_DIR.rglob("*.py"))


def test_examples_exist():
    scripts = _example_scripts()
    assert scripts, "No example scripts found under examples/"


def test_example_scripts_are_syntax_valid():
    for script in _example_scripts():
        py_compile.compile(str(script), doraise=True)
