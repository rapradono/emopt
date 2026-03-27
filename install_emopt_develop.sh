#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="${1:-emopt}"
PYTHON_VERSION="${PYTHON_VERSION:-3.8}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v mamba >/dev/null 2>&1 && ! command -v conda >/dev/null 2>&1; then
  echo "Error: neither mamba nor conda is available in PATH."
  exit 1
fi

if [ -f "$HOME/miniforge3/etc/profile.d/conda.sh" ]; then
  # shellcheck source=/dev/null
  source "$HOME/miniforge3/etc/profile.d/conda.sh"
else
  CONDA_BASE="$(conda info --base)"
  # shellcheck source=/dev/null
  source "$CONDA_BASE/etc/profile.d/conda.sh"
fi

PKG_MGR="conda"
if command -v mamba >/dev/null 2>&1; then
  PKG_MGR="mamba"
fi

echo "Creating/updating environment '$ENV_NAME'..."
"$PKG_MGR" create -n "$ENV_NAME" -c conda-forge -y \
  "python=${PYTHON_VERSION}" pip numpy scipy matplotlib requests h5py future \
  eigen=3.3.7 boost=1.73.0 mpi4py openmpi petsc=*=*complex* petsc4py slepc slepc4py \
  make cxx-compiler

conda activate "$ENV_NAME"

echo "Building native libraries (CPU path)..."
pushd "$REPO_DIR/src" >/dev/null
g++ -c -fPIC Grid.cpp -Wall -fopenmp -O3 -march=native -DNDEBUG -std=c++14 \
  -I"$CONDA_PREFIX/include/eigen3" -I"$CONDA_PREFIX/include"
g++ -c -fPIC Grid_ctypes.cpp -Wall -fopenmp -O3 -march=native -DNDEBUG -std=c++14 \
  -I"$CONDA_PREFIX/include/eigen3" -I"$CONDA_PREFIX/include"
g++ -c -fPIC fdtd.cpp -Wall -fopenmp -O3 -march=native -DNDEBUG -std=c++14
g++ -shared -fopenmp -fPIC -o ../emopt/Grid.so Grid.o Grid_ctypes.o -lpthread
g++ -shared -fopenmp -fPIC -o ../emopt/solvers/FDTD.so fdtd.o -lpthread
popd >/dev/null

echo "Installing emopt-develop into '$ENV_NAME'..."
pushd "$REPO_DIR" >/dev/null
pip install --no-deps --force-reinstall .
popd >/dev/null

echo "Verifying installation..."
python - <<'PY'
import os
import emopt
pkg = os.path.dirname(emopt.__file__)
print(f"emopt version: {emopt.__version__}")
print(f"emopt path: {pkg}")
print(f"Grid.so: {os.path.exists(os.path.join(pkg, 'Grid.so'))}")
print(f"FDTD.so: {os.path.exists(os.path.join(pkg, 'solvers', 'FDTD.so'))}")
PY

cat <<EOF

Done.
Use it with:
  source ~/miniforge3/etc/profile.d/conda.sh
  conda activate $ENV_NAME

Then from any folder (e.g. twig):
  python -c "import emopt; print(emopt.__version__)"
EOF
