from setuptools import setup, find_packages
from setuptools.command.install import install as SetuptoolsInstall
import subprocess, os, sys

class MakeInstall(SetuptoolsInstall):
    def run(self):
        required = ['EIGEN_DIR', 'BOOST_DIR', 'PETSC_DIR', 'SLEPC_DIR']
        missing = [v for v in required if not os.environ.get(v)]
        if missing:
            print(
                "ERROR: The following environment variables must be set before "
                "installing emopt:\n"
                f"  {', '.join(missing)}\n"
                "Run 'source ~/.emopt_deps' or 'bash setup-python.sh' first.",
                file=sys.stderr,
            )
            sys.exit(1)
        subprocess.check_call(['make'])
        SetuptoolsInstall.run(self)

setup(name='emopt',
      version='2023.01.16',
      description='A suite of tools for optimizing the shape and topology of ' \
      'electromagnetic structures.',
      url='https://github.com/anstmichaels/emopt',
      author='Andrew Michaels',
      author_email='amichaels@berkeley.edu',
      license='BSD-3',
      packages=find_packages(),
      package_data={'':['*.so', '*.csv', 'data/*']},
      cmdclass={'install':MakeInstall},
      install_requires=['numpy', 'scipy', 'mpi4py', 'petsc4py', 'slepc4py'],
      extras_require={"experimental": ['torch',]},
      zip_safe=False)
