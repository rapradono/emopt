# Example Run Report

This repository was checked by running the examples from their own example
directories with `PYTHONPATH` pointed at the local checkout and `MPLBACKEND=Agg`
for headless execution.

## Fixed in this branch

- `emopt/fdfd.py`
  - Updated 3D FDFD transpose handling to work with the current PETSc behavior.
  - This unblocked `examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdfd.py`,
    which previously failed during `sim.build()` and later during transpose
    updates in `solve_forward()`.
- `emopt/fdtd.py`
  - Guarded convergence metric normalization to avoid divide-by-zero warnings
    in 3D FDTD examples.
- `emopt/adjoint_method.py`
  - Updated gradient-check plotting for current Matplotlib.
  - Removed the deprecated `nonposy` usage.
  - Added an `Agg` backend guard to avoid `plt.show()` warnings in headless runs.
- Plotting examples
  - Added `Agg`-safe `plt.show()` guards to the light plotting examples.
- `examples/waveguide_modes/wg_modes_3D_sym_E0.py`
  - Updated material constants to match the other 3D mode examples.
  - This unblocked the SLEPc/MUMPS factorization failure in that example.
- Output path assumptions
  - Added `data/` directory creation to:
    - `examples/Silicon_Grating_Coupler/gc_opt.py`
    - `examples/Silicon_Grating_Coupler/gc_opt_constrained.py`
    - `examples/Silicon_Grating_Coupler_2L/sg2l_opt.py`
    - `examples/waveguide_bend/wg_bend.py`
- `examples/Silicon_Grating_Coupler/gc_opt_constrained.py`
  - Added fallback initialization when `data/gc_opt_results.h5` is absent, so
    the example can cold-start instead of requiring a prior `gc_opt.py` run.

## Current status

### Passes

- Light examples checked earlier in this branch now pass cleanly or with the
  expected solver output only.
- `examples/waveguide_bend/wg_bend.py`

### Runs but exceeds smoke-test timeout

These examples no longer showed immediate crashes in the current environment,
but did not finish within the smoke-test budget used here:

- `examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdfd.py`
- `examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdtd.py`
- `examples/Silicon_Grating_Coupler/gc_opt.py`
- `examples/Silicon_Grating_Coupler/gc_opt_constrained.py`
- `examples/Silicon_Grating_Coupler_2L/sg2l_opt.py`
- `examples/waveguide_crossing/waveguide_crossing_TM.py`
- `examples/experimental/MMI_splitter_3D_AutoDiff/mmi_1x2_splitter_3D_fdtd_AutoDiffPNF3D.py`
- `examples/experimental/blazed_grating_coupler_2D_AutoDiff/gc_opt_2D_AutoDiffPNF2D_BlazedGrating.py`
- `examples/experimental/fast_taper_2D_AutoDiff/FastTaper_2D_AutoDiffPNF2D.py`
- `examples/experimental/grating_coupler_2D_AutoDiff_FourierSeries/gc_opt_AutoDiffPNF2D_FourierSeries.py`
- `examples/experimental/splitter_2D_Topology/splitter_TopologyPNF2D.py`
- `examples/experimental/splitter_3D_Topology/splitter_TopologyPNF3D.py`

### No remaining hard failures reproduced

After the fixes above, no example that was rerun still failed immediately with a
deterministic crash in this environment.

## What should be checked on a stronger machine

The next useful run is not another smoke test. It should be a longer validation
pass on the heavy optimization examples.

Recommended order:

1. `examples/waveguide_crossing/waveguide_crossing_TM.py`
2. `examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdfd.py`
3. `examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdtd.py`
4. `examples/Silicon_Grating_Coupler/gc_opt.py`
5. `examples/Silicon_Grating_Coupler/gc_opt_constrained.py`
6. `examples/Silicon_Grating_Coupler_2L/sg2l_opt.py`
7. The experimental examples

## Suggested stronger-machine plan

- Use the same local checkout with `PYTHONPATH` pointed at the repository.
- Run from each example's own directory so relative `data/` paths work.
- Keep `MPLBACKEND=Agg` unless interactive plots are needed.
- Prefer MPI runs that match the example comments.
- Increase timeout significantly; many of these are optimization examples, not
  quick solver demos.
- If the stronger machine has an NVIDIA GPU, note that these examples are still
  primarily PETSc/SLEPc/MPI CPU workflows unless a specific experimental script
  uses PyTorch in a GPU-enabled environment.
- For the PyTorch/AutoDiff experimental examples, confirm:
  - CUDA-enabled PyTorch is installed
  - the script actually selects CUDA
  - GPU memory is sufficient for the chosen discretization

## Likely next engineering improvement

Add a lightweight `--smoke` or reduced-iteration mode for the heavy examples so
CI or local validation can distinguish "crash" from "long optimization" without
requiring multi-minute runs.
