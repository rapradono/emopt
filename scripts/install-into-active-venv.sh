#!/usr/bin/env bash
# Install EMopt into an already-activated Python environment.
#
# This is intended for a separate uv-managed project that wants to depend on a
# local EMopt checkout while reusing the shared PETSc/SLEPc installation set up
# by setup-system-deps.sh.

set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[emopt]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -z "${VIRTUAL_ENV:-}" ]]; then
  error "Activate the target virtual environment first."
fi

if [[ ! -f "$HOME/.emopt_deps" ]]; then
  error "~/.emopt_deps not found. Run 'bash setup-system-deps.sh' from the EMopt repo first."
fi

if ! command -v uv >/dev/null 2>&1; then
  error "uv is required in PATH."
fi

source "$HOME/.emopt_deps"

for _var in PETSC_DIR SLEPC_DIR EIGEN_DIR BOOST_DIR; do
  if [[ -z "${!_var:-}" ]]; then
    error "$_var is not set. Check ~/.emopt_deps"
  fi
done

info "Using active virtual environment: $VIRTUAL_ENV"
info "Installing build tooling and runtime dependencies..."
uv pip install "setuptools<70" wheel "Cython==3.0.10"
uv pip install numpy scipy matplotlib h5py pyyaml pandas requests future pdftotext

info "Installing MPI / PETSc / SLEPc Python bindings..."
uv pip install mpi4py --no-build-isolation
uv pip install "petsc4py==3.21.5" --no-build-isolation --no-deps
uv pip install "slepc4py==3.21.2" --no-build-isolation --no-deps

info "Building EMopt native libraries from $REPO_ROOT..."
(
  cd "$REPO_ROOT"
  make
)

info "Installing EMopt into the active environment..."
uv pip install -e "$REPO_ROOT" --no-build-isolation
uv pip install -e "$REPO_ROOT" --no-build-isolation --no-deps --force-reinstall

info "Verifying imports..."
python - <<'PY'
import numpy as np
import emopt
from petsc4py import PETSc
import slepc4py
import mpi4py

assert np.issubdtype(PETSc.ScalarType, np.complexfloating), (
    f"PETSc scalar type is {PETSc.ScalarType}, expected a complex type"
)
print("emopt ok")
print("PETSc scalar type:", PETSc.ScalarType)
PY

info "EMopt is ready in the active environment."
