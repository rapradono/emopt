"""EMopt: Simulate and optimize electromagnetic devices with an emphasis on waveguiding
devices.
"""
__author__ = "Andrew Michaels"
__license__ = "BSD-3-Clause"
__version__ = "0.5.0"
__maintainer__ = "Andrew Michaels"
__status__ = "development"

from . import dvio, opt_def, solvers, fomutils, grid, misc, optimizer, geometry

__all__ = ["opt_def", "solvers", "fomutils", "grid", "dvio", "misc",
          "optimizer", "geometry"]
