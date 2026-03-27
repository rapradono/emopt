from setuptools import setup, find_packages
from setuptools.command.install import install as SetuptoolsInstall
import subprocess, os, sys

class MakeInstall(SetuptoolsInstall):
    def run(self):
        home_dir = os.path.expanduser('~')
        deps_file = home_dir + '/.emopt_deps'
        if(os.path.exists(deps_file)):
            with open(deps_file, 'r') as fdeps:
                for line in fdeps:
                    line = line.strip()
                    if (not line) or line.startswith('#'):
                        continue
                    if line.startswith('export '):
                        line = line[len('export '):]
                    toks = line.split('=', 1)
                    if len(toks) == 2:
                        key, value = toks
                        os.environ[key] = value
        else:
            pass # install dependencies as needed
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
