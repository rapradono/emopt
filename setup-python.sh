#!/usr/bin/env bash
# setup-python.sh — Create uv virtual environment and install emopt Python deps
#
# Run this after setup-system-deps.sh.
#
# Usage:
#   bash setup-python.sh [OPTIONS]
#
# Options:
#   --torch-gpu       Install PyTorch with CUDA support
#   --torch-cpu       Install PyTorch CPU-only
#   --no-torch        Skip PyTorch entirely
#   --no-interactive  Non-interactive / CI mode (implies --no-torch)

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
TORCH_MODE="ask"   # ask | gpu | cpu | no
INTERACTIVE=1

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --torch-gpu)      TORCH_MODE="gpu"; shift ;;
    --torch-cpu)      TORCH_MODE="cpu"; shift ;;
    --no-torch)       TORCH_MODE="no";  shift ;;
    --no-interactive) INTERACTIVE=0; TORCH_MODE="no"; shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[emopt]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

# ── Locate repo root (script lives in the repo) ───────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Check prerequisites ───────────────────────────────────────────────────────
if [[ ! -f "$HOME/.emopt_deps" ]]; then
  error "~/.emopt_deps not found. Run 'bash setup-system-deps.sh' first."
fi

source "$HOME/.emopt_deps"

for _var in PETSC_DIR SLEPC_DIR EIGEN_DIR BOOST_DIR; do
  if [[ -z "${!_var:-}" ]]; then
    error "$_var is not set. Check ~/.emopt_deps"
  fi
done

info "Environment:"
info "  PETSC_DIR  = $PETSC_DIR"
info "  SLEPC_DIR  = $SLEPC_DIR"
info "  EIGEN_DIR  = $EIGEN_DIR"
info "  BOOST_DIR  = $BOOST_DIR"

# ── Install uv (if missing) ───────────────────────────────────────────────────
if ! command -v uv &>/dev/null; then
  info "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
info "uv: $(uv --version)"

# ── Create virtual environment ────────────────────────────────────────────────
info "Creating .venv with Python 3.10..."
uv venv --python 3.10 --clear .venv
# shellcheck disable=SC1091
source .venv/bin/activate
info "Python: $(python --version)"

# ── Python build tooling ─────────────────────────────────────────────────────
# uv-created environments do not necessarily include setuptools, but petsc4py
# and slepc4py still expect the classic build backend stack to be available
# when installed with --no-build-isolation.
info "Installing Python build tooling..."
uv pip install "setuptools<70" wheel "Cython==3.0.10"

# ── Core Python dependencies needed before PETSc bindings build ─────────────
info "Installing core Python dependencies..."
uv pip install numpy scipy matplotlib h5py pyyaml pandas requests future pdftotext

# ── MPI / PETSc / SLEPc Python bindings ──────────────────────────────────────
# --no-build-isolation allows the build to find system OpenMPI and the
# custom-built PETSc/SLEPc via PETSC_DIR / SLEPC_DIR env vars.
info "Installing mpi4py..."
uv pip install mpi4py --no-build-isolation

info "Installing petsc4py (links against $PETSC_DIR)..."
uv pip install "petsc4py==3.21.5" --no-build-isolation --no-deps

info "Installing slepc4py (links against $SLEPC_DIR)..."
uv pip install "slepc4py==3.21.2" --no-build-isolation --no-deps

# ── PyTorch (optional) ────────────────────────────────────────────────────────
if [[ "$TORCH_MODE" == "ask" && $INTERACTIVE -eq 1 ]]; then
  echo
  info "PyTorch is required only for experimental features (AutoDiff, topology opt)."
  read -rp "Install PyTorch? [gpu/cpu/no] " _torch
  TORCH_MODE="${_torch:-no}"
fi

case "$TORCH_MODE" in
  gpu) info "Installing PyTorch (GPU/CUDA)..."
       uv pip install torch ;;
  cpu) info "Installing PyTorch (CPU-only)..."
       uv pip install torch --index-url https://download.pytorch.org/whl/cpu ;;
  no|*) info "Skipping PyTorch." ;;
esac

# ── Install emopt ─────────────────────────────────────────────────────────────
# Build the native libraries explicitly so editable install does not depend on
# setuptools install hook behavior.
info "Building emopt native libraries..."
make

# Two passes are required:
#   Pass 1: compiles Grid.so and FDTD.so via 'make', copies them into emopt/
#   Pass 2: force-reinstalls so the .so files are included in the installed pkg
info "Installing emopt (pass 1 — compiles C++ extensions)..."
uv pip install -e . --no-build-isolation

info "Installing emopt (pass 2 — packages compiled .so files)..."
uv pip install -e . --no-build-isolation --no-deps --force-reinstall

# ── OMP_NUM_THREADS in venv activate ─────────────────────────────────────────
if ! grep -q 'OMP_NUM_THREADS' .venv/bin/activate; then
  echo 'export OMP_NUM_THREADS=1' >> .venv/bin/activate
  info "Added OMP_NUM_THREADS=1 to .venv/bin/activate"
fi

# ── Smoke tests ───────────────────────────────────────────────────────────────
info "Running smoke tests..."
python - <<'PYCHECK'
import sys
import numpy as np

def check(label, fn):
    try:
        fn()
        print(f"  ✓ {label}")
    except Exception as e:
        print(f"  ✗ {label}: {e}", file=sys.stderr)
        sys.exit(1)

check("emopt import",    lambda: __import__("emopt"))
check("petsc4py (complex)", lambda: (
    __import__("petsc4py.PETSc", fromlist=["PETSc"]),
    __builtins__,  # noqa
    exec(
        "from petsc4py import PETSc\n"
        "assert np.issubdtype(PETSc.ScalarType, np.complexfloating), "
        "f'PETSc scalar type is {PETSc.ScalarType}, expected a complex type'",
        {"np": np}
    )
))
check("slepc4py",        lambda: __import__("slepc4py"))
check("mpi4py",          lambda: __import__("mpi4py"))
PYCHECK

# ── Done ─────────────────────────────────────────────────────────────────────
echo
info "EMopt installed successfully!"
echo
echo "  Activate:   source .venv/bin/activate"
echo "  Deactivate: deactivate"
echo
echo "  To recreate env (if .venv is deleted):"
echo "    source ~/.emopt_deps && bash setup-python.sh"
echo
