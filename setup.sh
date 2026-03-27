#!/bin/bash

safe_exit() {
    local code="$1"
    if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
        return "$code"
    fi
    exit "$code"
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$script_dir" || safe_exit 1

mamba_exec_cmd=""
mamba_exec() {
    "$mamba_exec_cmd" "$@"
}

read -p "Do you have an existing installation of mamba (community made anaconda reimplementation)? [y/n] " existing_mamba

case $existing_mamba in
    y)
        mamba_exec_cmd="mamba"
        ;;
    n)
        read -p "mamba/conda are required for this installation script. Do you want to install mamba? If you already have conda, please choose 'n'. mamba is highly recommended, conda may not be able to resolve dependencies in a reasonable amount of time. See https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html if you'd like to install mamba into an existing conda install. [y/n] " install_mamba
        case $install_mamba in
            y)
                read -p "Are you using a Linux x86-64 system? [y/n] " linux_flag
                case $linux_flag in
                    y)
                        echo "Installing mamba. Please follow the prompts."
                        wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh
                        bash Miniforge3-Linux-x86_64.sh
                        mamba_exec_cmd="mamba"
                        ;;
                    n)
                        echo "Please navigate to https://mamba.readthedocs.io/en/latest/installation/mamba-installation.html and follow the instructions there to install mamba. Then rerun this setup script. Exiting."
                        safe_exit 0
                        ;;
                    *)
                        echo invalid response
                        safe_exit 1
                        ;;
                esac
                ;;
            n)
                echo "Not installing mamba. We will assume that you have conda installed. Note, this may result in dependency resolution issues."
                mamba_exec_cmd="conda"
                ;;
            *)
                echo invalid response
                safe_exit 1
                ;;
        esac
        ;;
    *)
        echo invalid response
        safe_exit 1
        ;;
esac

if [ -f "$HOME/.bashrc" ]; then
    # Needed for conda/mamba shell functions in non-interactive scripts.
    source "$HOME/.bashrc"
fi

if [ -z "$mamba_exec_cmd" ]; then
    echo "Could not determine package manager command (mamba/conda). Exiting."
    safe_exit 1
fi

if ! command -v "$mamba_exec_cmd" >/dev/null 2>&1; then
    echo "$mamba_exec_cmd is not available in PATH. Exiting."
    safe_exit 1
fi

echo "The remainder of this script will assume that you will want to install OpenMPI, Boost, Eigen, PETSc, and SLEPc in your local mamba/conda environment. If you have an existing installation of any of these packages, you may instead want to do a custom install described at: https://emopt.readthedocs.io/en/latest/installation.html."
read -p "Continue? [y/n] " continue_var

case $continue_var in
    y) ;;
    n) safe_exit 0;;
    *) echo invalid response; safe_exit 1;;
esac

read -p "Please provide a name for your EMopt environment, or hit enter for default name (emopt): " emopt_name
emopt_name=${emopt_name:=emopt}

read -p "Do you want to install PyTorch? This is needed for experimental EMopt features such as AutoDiff-accelerated feature-mapping and free-form topology optimization. It is not required for use with the base EMopt package. [y/n] " install_torch

case $install_torch in
    y)
        read -p "Do you have an NVIDIA GPU for PyTorch? [y/n] " have_gpu
        case $have_gpu in
             y)
                 mamba_exec create --name "$emopt_name" -c conda-forge -y python pip numpy scipy matplotlib requests h5py future eigen=3.3.7 boost=1.73.0 mpi4py openmpi petsc=*=*complex* petsc4py slepc slepc4py pytorch make cxx-compiler
                 ;;
             n)
                 mamba_exec create --name "$emopt_name" -c conda-forge -y python pip numpy scipy matplotlib requests h5py future eigen=3.3.7 boost=1.73.0 mpi4py openmpi petsc=*=*complex* petsc4py slepc slepc4py pytorch-cpu make cxx-compiler
                 ;;
             *) echo invalid response; safe_exit 1;;
        esac
        ;;
    n)
        mamba_exec create --name "$emopt_name" -c conda-forge -y python pip numpy scipy matplotlib requests h5py future eigen=3.3.7 boost=1.73.0 mpi4py openmpi petsc=*=*complex* petsc4py slepc slepc4py make cxx-compiler
        ;;
    *) echo invalid response; safe_exit 1;;
esac

if [ $? -ne 0 ]; then
    echo "Dependencies failed to install."
    safe_exit 1
fi

if command -v conda >/dev/null 2>&1; then
    eval "$(conda shell.bash hook)"
    conda activate "$emopt_name"
elif command -v mamba >/dev/null 2>&1; then
    eval "$(mamba shell hook --shell bash)"
    mamba activate "$emopt_name"
fi

if [ $? -eq 0 ]; then
    echo "Successfully installed dependencies! Installing EMopt..."
else
    echo "Could not activate environment '$emopt_name'."
    safe_exit 1
fi

echo export OMP_NUM_THREADS=1 >> "$HOME/.bashrc"
rm -f "$HOME/.emopt_deps"
cat > "$HOME/.emopt_deps" <<EOF
EIGEN_DIR=$CONDA_PREFIX/include/eigen3
BOOST_DIR=$CONDA_PREFIX/include/
PETSC_DIR=$CONDA_PREFIX/
PETSC_ARCH=
SLEPC_DIR=$CONDA_PREFIX/
EOF

source "$HOME/.emopt_deps"

pip install -vv --no-deps --force-reinstall .
# First install builds native .so files via setup.py/make; second pass ensures they are packaged.
pip install -vv --no-deps --force-reinstall .

if [ $? -eq 0 ]; then
    echo "Succesfully installed EMopt!. Exiting."
    safe_exit 0
else
    echo "There was a problem in pip install. Exiting."
    safe_exit 1
fi
