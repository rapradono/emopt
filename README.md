# EMopt
A toolkit for shape (and topology) optimization of 2D and 3D electromagnetic
structures. 

EMopt offers a suite of tools for simulating and optimizing electromagnetic
structures. It includes 2D and 3D finite difference frequency domain solvers,
1D and 2D mode solvers, a flexible and *easily extensible* adjoint method
implementation, and a simple wrapper around scipy.minimize. Out of the box, it
provides just about everything needed to apply cutting-edge inverse design
techniques to your electromagnetic devices.

A key emphasis of EMopt's is shape optimization. Using boundary smoothing
techniques, EMopt allows you to compute sensitivities (i.e. gradient of a
figure of merit with respect to design variables which define an
electromagnetic device's shape) with very high accuracy. This allows you to
easily take adavantage of powerful minimization techniques in order to optimize
your electromagnetic device.

## Documentation

Details on how to install and use EMopt can be found
[on readthedocs](https://emopt.readthedocs.io/en/latest/). Check this link
periodically as the documentation is constantly being improved and examples
added.

## Installation

**Requirements:** Ubuntu 22.04 / WSL2 Linux, `sudo` access, ~5 GB disk, ~30 min first run.

### 1. System dependencies + PETSc/SLEPc (run once)

```bash
bash setup-system-deps.sh
```

This installs `g++`, `gfortran`, OpenMPI, Eigen, Boost, and Poppler via `apt`,
then builds PETSc (with complex arithmetic) and SLEPc from source into
`~/.emopt`.

### 2. Python environment (uv)

```bash
bash setup-python.sh
```

Creates `.venv/` (Python 3.13), installs `mpi4py`, `petsc4py`, `slepc4py`,
`pandas`, `pyyaml`, `pdftotext`, and emopt itself, then builds the native
C++ extensions.

Validated working combination on this branch:

- Python `3.13`
- PETSc `3.21.5`
- SLEPc `3.21.2`
- `petsc4py==3.21.5`
- `slepc4py==3.21.2`
- `setuptools<70`
- `Cython==3.0.10`

### 3. Activate

```bash
source .venv/bin/activate
```

To recreate the Python environment later (without rebuilding PETSc):

```bash
source ~/.emopt_deps && bash setup-python.sh
```

## Using EMopt From Another Repo

If you want to use `emopt` from a separate `uv`-managed project, treat this
repo as the system-dependency provider and install `emopt` into the other
project's virtual environment.

### 1. On a fresh machine, prepare EMopt system dependencies once

```bash
git clone <your-emopt-fork-url>
cd emopt
bash setup-system-deps.sh
```

This installs PETSc and SLEPc into `~/.emopt` and writes the environment file
`~/.emopt_deps`.

### 2. In your other repo, create a `uv` environment

```bash
cd /path/to/your-other-repo
uv venv --python 3.13
source .venv/bin/activate
source ~/.emopt_deps
```

### 3. Install the PETSc Python bindings into that environment

```bash
uv pip install "setuptools<70" wheel "Cython==3.0.10"
uv pip install numpy scipy matplotlib h5py pyyaml pandas requests future pdftotext
uv pip install mpi4py --no-build-isolation
uv pip install "petsc4py==3.21.5" --no-build-isolation --no-deps
uv pip install "slepc4py==3.21.2" --no-build-isolation --no-deps
```

### 4. Install `emopt` from your cloned checkout

```bash
uv pip install -e /path/to/emopt --no-build-isolation
```

Or, from the active environment in the other repo, run the helper shipped in
this repo:

```bash
/path/to/emopt/scripts/install-into-active-venv.sh
```

If you change native code in `emopt/src`, rebuild from the `emopt` checkout:

```bash
cd /path/to/emopt
source ~/.emopt_deps
make
```

### 5. Verify from the other repo

```bash
python - <<'PY'
import emopt
from petsc4py import PETSc
print("emopt ok")
print("PETSc scalar type:", PETSc.ScalarType)
PY
```

Notes:

- `source ~/.emopt_deps` must be active whenever you build or reinstall
  `petsc4py`, `slepc4py`, or `emopt`.
- The other repo does not need to vendor PETSc or SLEPc itself; it can reuse
  the shared `~/.emopt` installation created by `setup-system-deps.sh`.
- Experimental `emopt.experimental` workflows additionally require PyTorch.

## Free-Form Topology and AutoDiff-Enhanced Feature-Mapping Approaches

New optional experimental modules for topology optimization and automatic 
differentiation enhanced feature-mapping approaches are implemented in 
emopt/experimental, with corresponding examples in examples/experimental. 
The AutoDiff methods can result in large improvements in optimization speed for 
designs with variables that parameterize global geometric features. Please see 
our preprint below and examples for correct usage. Note: Requires PyTorch 
installation. These features are still in development.

## Authors
Andrew Michaels 

Sean Hooten (Topology and AutoDiff methods)

## License
EMOpt is currently released under the BSD-3 license (see LICENSE.md for details)

## References
The methods employed by EMopt are described in:

Andrew Michaels and Eli Yablonovitch, "Leveraging continuous material averaging for inverse electromagnetic design," Opt. Express 26, 31717-31737 (2018)

An example of applying these methods to real design problems can be found in:

Andrew Michaels and Eli Yablonovitch, "Inverse design of near unity efficiency perfectly vertical grating couplers," Opt. Express 26, 4766-4779 (2018)

Shape optimization feature-mapping methods accelerated by automatic differentiation:

S. Hooten, P. Sun, L. Gantz, M. Fiorentino, R. Beausoleil, T. Van Vaerenbergh, "Automatic Differentiation Accelerated Shape Optimization Approaches to Photonic Inverse Design on Rectilinear Simulation Grids." arXiv [cs.CE], 2311.05646 (2023). Link [here](https://arxiv.org/abs/2311.05646).
