#!/usr/bin/env bash
# setup-system-deps.sh — Install system-level dependencies for emopt (uv edition)
#
# Installs build tools, OpenMPI, Eigen, and Boost via apt, then compiles
# PETSc and SLEPc from source with complex arithmetic support.
#
# Usage:
#   bash setup-system-deps.sh [OPTIONS]
#
# Options:
#   --prefix <dir>      Install prefix (default: $HOME/.emopt)
#   --petsc-version V   PETSc version (default: 3.24.3)
#   --slepc-version V   SLEPc version (default: 3.24.3)
#   --force             Rebuild even if already installed
#   --no-interactive    Non-interactive / CI mode (no prompts)
#
# After this script completes, run:
#   bash setup-python.sh

set -euo pipefail

# ── Defaults ──────────────────────────────────────────────────────────────────
INSTALL_PREFIX="${EMOPT_PREFIX:-$HOME/.emopt}"
PETSC_VERSION="${PETSC_VERSION:-3.24.3}"
SLEPC_VERSION="${SLEPC_VERSION:-3.24.3}"
FORCE=0
INTERACTIVE=1

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix)         INSTALL_PREFIX="$2"; shift 2 ;;
    --petsc-version)  PETSC_VERSION="$2";  shift 2 ;;
    --slepc-version)  SLEPC_VERSION="$2";  shift 2 ;;
    --force)          FORCE=1;             shift   ;;
    --no-interactive) INTERACTIVE=0;       shift   ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[emopt]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; exit 1; }

# ── Banner ────────────────────────────────────────────────────────────────────
echo
info "EMopt system dependency installer (uv edition)"
info "  Install prefix : $INSTALL_PREFIX"
info "  PETSc version  : $PETSC_VERSION"
info "  SLEPc version  : $SLEPC_VERSION"
echo

if [[ $INTERACTIVE -eq 1 ]]; then
  read -rp "This will install system packages and build PETSc/SLEPc (~30 min). Continue? [y/n] " _confirm
  [[ "$_confirm" == "y" ]] || { info "Aborted."; exit 0; }
fi

# ── System packages ───────────────────────────────────────────────────────────
info "Installing apt packages..."
sudo apt-get update -qq
sudo apt-get install -y \
  build-essential \
  g++ \
  gfortran \
  make \
  cmake \
  wget \
  curl \
  libopenmpi-dev \
  openmpi-bin \
  libeigen3-dev \
  libboost-dev \
  libopenblas-dev \
  liblapack-dev \
  libpoppler-cpp-dev \
  poppler-utils
info "Apt packages installed."

# ── Directories ───────────────────────────────────────────────────────────────
mkdir -p "$INSTALL_PREFIX"
BUILD_DIR="$(mktemp -d /tmp/emopt-build-XXXXXX)"
trap 'rm -rf "$BUILD_DIR"' EXIT
info "Build workspace: $BUILD_DIR"

# ── PETSc ─────────────────────────────────────────────────────────────────────
PETSC_MARKER="$INSTALL_PREFIX/include/petsc.h"

if [[ -f "$PETSC_MARKER" && $FORCE -eq 0 ]]; then
  info "PETSc already installed at $INSTALL_PREFIX. Use --force to rebuild."
else
  info "Building PETSc $PETSC_VERSION (this takes 20-40 minutes)..."
  cd "$BUILD_DIR"

  PETSC_TARBALL="petsc-${PETSC_VERSION}.tar.gz"
  PETSC_URL="https://web.cels.anl.gov/projects/petsc/download/release-snapshots/${PETSC_TARBALL}"

  info "  Downloading $PETSC_URL ..."
  wget -q --show-progress "$PETSC_URL" -O "$PETSC_TARBALL"
  tar xzf "$PETSC_TARBALL"
  cd "petsc-${PETSC_VERSION}"

  # Unset these — they break configure if inherited from the shell
  unset PETSC_DIR PETSC_ARCH SLEPC_DIR 2>/dev/null || true

  info "  Configuring PETSc (complex scalars, no debug, system BLAS)..."
  ./configure \
    --prefix="$INSTALL_PREFIX" \
    --with-scalar-type=complex \
    --with-mpi=1 \
    --with-debugging=0 \
    --COPTFLAGS='-O3' \
    --FOPTFLAGS='-O3' \
    --CXXOPTFLAGS='-O3' \
    --with-shared-libraries=1 \
    --with-blaslapack-lib="-lopenblas" \
    --download-scalapack \
    --download-mumps

  info "  Compiling PETSc..."
  make all

  info "  Installing PETSc to $INSTALL_PREFIX ..."
  make install

  info "PETSc $PETSC_VERSION installed."
fi

# ── SLEPc ─────────────────────────────────────────────────────────────────────
SLEPC_MARKER="$INSTALL_PREFIX/include/slepc.h"

if [[ -f "$SLEPC_MARKER" && $FORCE -eq 0 ]]; then
  info "SLEPc already installed at $INSTALL_PREFIX. Use --force to rebuild."
else
  info "Building SLEPc $SLEPC_VERSION ..."
  cd "$BUILD_DIR"

  SLEPC_TARBALL="slepc-${SLEPC_VERSION}.tar.gz"
  SLEPC_URL="https://slepc.upv.es/download/distrib/${SLEPC_TARBALL}"

  info "  Downloading $SLEPC_URL ..."
  wget -q --show-progress "$SLEPC_URL" -O "$SLEPC_TARBALL"
  tar xzf "$SLEPC_TARBALL"
  cd "slepc-${SLEPC_VERSION}"

  unset SLEPC_DIR 2>/dev/null || true
  export PETSC_DIR="$INSTALL_PREFIX"
  export PETSC_ARCH=""
  export SLEPC_DIR="$PWD"

  info "  Configuring SLEPc..."
  ./configure --prefix="$INSTALL_PREFIX"

  info "  Compiling SLEPc..."
  make all

  info "  Installing SLEPc to $INSTALL_PREFIX ..."
  make install

  info "SLEPc $SLEPC_VERSION installed."
fi

# ── Write ~/.emopt_deps ───────────────────────────────────────────────────────
info "Writing ~/.emopt_deps ..."
cat > "$HOME/.emopt_deps" <<EOF
# EMopt dependency environment variables — generated by setup-system-deps.sh
# Source this file before building or activating emopt:
#   source ~/.emopt_deps
export EIGEN_DIR=/usr/include/eigen3
export BOOST_DIR=/usr/include
export PETSC_DIR=${INSTALL_PREFIX}
export PETSC_ARCH=
export SLEPC_DIR=${INSTALL_PREFIX}
EOF

# ── OMP_NUM_THREADS ───────────────────────────────────────────────────────────
if [[ -f "$HOME/.bashrc" ]]; then
  if ! grep -qxF 'export OMP_NUM_THREADS=1' "$HOME/.bashrc"; then
    echo 'export OMP_NUM_THREADS=1' >> "$HOME/.bashrc"
    info "Added OMP_NUM_THREADS=1 to ~/.bashrc"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo
info "System dependencies installed successfully!"
echo
echo "  Environment variables written to: ~/.emopt_deps"
echo "  Next step: run 'bash setup-python.sh'"
echo
