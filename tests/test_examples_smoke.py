import os
import subprocess
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parents[1]

# Keep default smoke coverage focused on examples that generally finish quickly.
SMOKE_EXAMPLES = [
    "examples/simple_waveguide/simple_waveguide.py",
    "examples/simple_waveguide/simple_waveguide_mode.py",
    "examples/simple_waveguide/simple_waveguide_mode_symmetric.py",
    "examples/simple_waveguide/simple_waveguide_mode_TM_symmetric.py",
    "examples/simple_waveguide/simple_waveguide_symmetric_x.py",
    "examples/simple_waveguide/simple_waveguide_symmetric_y.py",
    "examples/waveguide_modes/wg_modes_2D.py",
    "examples/waveguide_modes/wg_modes_2D_symmetry.py",
    "examples/klayout_import/klayout_import.py",
]


@pytest.mark.parametrize("rel_script", SMOKE_EXAMPLES)
def test_example_smoke(rel_script):
    script = REPO_ROOT / rel_script
    assert script.exists(), f"Missing example: {rel_script}"

    env = os.environ.copy()
    env.setdefault("MPLBACKEND", "Agg")
    env.setdefault("OMP_NUM_THREADS", "1")

    nproc = env.get("EMOPT_EXAMPLE_NPROC", "2")
    timeout_s = int(env.get("EMOPT_EXAMPLE_TIMEOUT", "180"))

    cmd = ["mpirun", "-n", nproc, "python", script.name]
    proc = subprocess.run(
        cmd,
        cwd=script.parent,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        timeout=timeout_s,
    )

    if proc.returncode != 0:
        pytest.fail(
            f"{rel_script} failed with rc={proc.returncode}\n"
            f"--- output ---\n{proc.stdout[-4000:]}"
        )
