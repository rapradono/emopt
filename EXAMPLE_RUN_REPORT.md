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

This snapshot reflects the preserved artifacts from two validation batches on
March 29, 2026:

- `.example-runs/reconfirm_20260329_181204_light/results.tsv`
- `.example-runs/reconfirm_20260329_2032_all_30m/{results.tsv,status.txt,monitor.log,logs/}`

### Confirmed passes

The following examples are confirmed passing from the preserved rerun artifacts:

- `examples/simple_waveguide/simple_waveguide.py`
- `examples/simple_waveguide/simple_waveguide_mode.py`
- `examples/simple_waveguide/simple_waveguide_mode_symmetric.py`
- `examples/simple_waveguide/simple_waveguide_mode_TM_symmetric.py`
- `examples/simple_waveguide/simple_waveguide_symmetric_x.py`
- `examples/simple_waveguide/simple_waveguide_symmetric_y.py`
- `examples/waveguide_modes/wg_modes_2D.py`
- `examples/waveguide_modes/wg_modes_2D_symmetry.py`
- `examples/klayout_import/klayout_import.py`
- `examples/waveguide_crossing/waveguide_crossing_TM.py`

`examples/waveguide_crossing/waveguide_crossing_TM.py` completed successfully in
233 seconds in the heavier sequential batch.

### Reaches the 30 minute smoke timeout

These examples ran for the full 1800 second smoke budget and should be treated
as "long-running" rather than immediate regressions:

- `examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdfd.py`
- `examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdtd.py`

### Interrupted before completion

The sequential overnight batch then started:

- `examples/Silicon_Grating_Coupler/gc_opt.py`

That run was active and making progress, but it has no trailing `RESULT|...`
entry and no `completed` entry in `.example-runs/reconfirm_20260329_2032_all_30m/status.txt`.
The preserved log shows it reached iteration 2 before the WSL session was lost.
This should be treated as an interrupted run, not as a clean timeout or a clean
pass/fail result.

### Not yet revalidated in the recovered heavy batch

Because the batch stopped during `gc_opt.py`, the following examples were not
reached in the recovered overnight sequence:

- `examples/Silicon_Grating_Coupler/gc_opt_constrained.py`
- `examples/Silicon_Grating_Coupler_2L/sg2l_opt.py`
- `examples/experimental/MMI_splitter_3D_AutoDiff/mmi_1x2_splitter_3D_fdtd_AutoDiffPNF3D.py`
- `examples/experimental/blazed_grating_coupler_2D_AutoDiff/gc_opt_2D_AutoDiffPNF2D_BlazedGrating.py`
- `examples/experimental/fast_taper_2D_AutoDiff/FastTaper_2D_AutoDiffPNF2D.py`
- `examples/experimental/grating_coupler_2D_AutoDiff_FourierSeries/gc_opt_AutoDiffPNF2D_FourierSeries.py`
- `examples/experimental/splitter_2D_Topology/splitter_TopologyPNF2D.py`
- `examples/experimental/splitter_3D_Topology/splitter_TopologyPNF3D.py`

### Memory/OOM note

The preserved monitor log shows that
`examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdtd.py` grew to roughly 9.1 GiB
RSS during the 30 minute smoke run. On a WSL instance capped at 10 GiB RAM,
this class of example should be treated as an OOM risk unless run with tighter
monitoring or on a roomier machine.

### No remaining hard failures reproduced

After the fixes above, none of the rerun examples in the recovered artifacts
showed an immediate deterministic crash. The remaining issues are now
distinguished as:

- long-running examples that exceeded a smoke timeout
- a heavy run interrupted by WSL OOM
- examples not yet revalidated after that interruption

## What should be checked on a stronger machine

The next useful pass is a controlled continuation from the interrupted heavy
batch, not another broad smoke test.

Recommended order:

1. `examples/Silicon_Grating_Coupler/gc_opt.py`
2. `examples/Silicon_Grating_Coupler/gc_opt_constrained.py`
3. `examples/Silicon_Grating_Coupler_2L/sg2l_opt.py`
4. `examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdfd.py` with a longer timeout
5. `examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdtd.py` with strict memory monitoring
6. The experimental examples

## Suggested stronger-machine plan

- Use the same local checkout with `PYTHONPATH` pointed at the repository.
- Run from each example's own directory so relative `data/` paths work.
- Keep `MPLBACKEND=Agg` unless interactive plots are needed.
- Keep `OMP_NUM_THREADS=1` and similarly cap BLAS/OpenMP thread counts.
- Prefer sequential execution for the heavy examples.
- Prefer MPI runs that match the example comments when the host environment is stable.
- Increase timeout significantly; many of these are optimization examples, not
  quick solver demos.
- If using WSL again, allocate more than 10 GiB RAM before retrying the 3D FDTD
  and grating-coupler optimization examples.
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
