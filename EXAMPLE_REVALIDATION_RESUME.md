# Example Revalidation Resume

Updated: 2026-03-29 19:37 KST

## Current state

- Repository branch: `master`
- Existing local changes before this handoff:
  - modified: `setup.sh`
  - untracked: `config/`
- New artifacts from this revalidation session:
  - `.example-runs/reconfirm_20260329_181204_light/`
    - valid full-access rerun
    - contains `results.tsv` plus one log per example

## Confirmed so far

The full light batch passed under full-access WSL using the EMopt env directly with:

- `PYTHONPATH=/home/acil/github/emopt`
- `MPLBACKEND=Agg`
- `OMP_NUM_THREADS=1`
- direct `python ...` execution from each example directory
- no `mpirun` needed for this batch

Results file:

- `.example-runs/reconfirm_20260329_181204_light/results.tsv`

Confirmed passing light examples:

- `examples/simple_waveguide/simple_waveguide.py`
- `examples/simple_waveguide/simple_waveguide_mode.py`
- `examples/simple_waveguide/simple_waveguide_mode_symmetric.py`
- `examples/simple_waveguide/simple_waveguide_mode_TM_symmetric.py`
- `examples/simple_waveguide/simple_waveguide_symmetric_x.py`
- `examples/simple_waveguide/simple_waveguide_symmetric_y.py`
- `examples/waveguide_modes/wg_modes_2D.py`
- `examples/waveguide_modes/wg_modes_2D_symmetry.py`
- `examples/klayout_import/klayout_import.py`

Recorded runtimes from `results.tsv`:

- 21s `examples/simple_waveguide/simple_waveguide.py`
- 9s `examples/simple_waveguide/simple_waveguide_mode.py`
- 5s `examples/simple_waveguide/simple_waveguide_mode_symmetric.py`
- 7s `examples/simple_waveguide/simple_waveguide_mode_TM_symmetric.py`
- 7s `examples/simple_waveguide/simple_waveguide_symmetric_x.py`
- 8s `examples/simple_waveguide/simple_waveguide_symmetric_y.py`
- 1s `examples/waveguide_modes/wg_modes_2D.py`
- 2s `examples/waveguide_modes/wg_modes_2D_symmetry.py`
- 2s `examples/klayout_import/klayout_import.py`

## Important runtime note

Inside the restricted Codex sandbox, MPI/socket init failed with errors like:

- `socket() failed with errno=1`
- `No network interfaces were found for out-of-band communications`

That was an environment restriction artifact, not an example regression.

When resuming, use full-access commands in the actual WSL environment.

## Next recommended sequence

Continue from lighter non-smoke examples toward heavier optimization runs, one at a time, with logs saved under `.example-runs/`:

1. `examples/waveguide_bend/wg_bend.py`
2. `examples/waveguide_crossing/waveguide_crossing_TM.py`
3. `examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdfd.py`
4. `examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdtd.py`
5. `examples/Silicon_Grating_Coupler/gc_opt.py`
6. `examples/Silicon_Grating_Coupler/gc_opt_constrained.py`
7. `examples/Silicon_Grating_Coupler_2L/sg2l_opt.py`
8. experimental examples last

## Safe execution policy

To avoid WSL memory trouble:

- keep `OMP_NUM_THREADS=1`
- run examples sequentially
- start with `timeout 180s` to separate crash from long run
- only increase timeout after a script is shown to be stable
- avoid launching multiple heavy examples at once

## Resume command pattern

From repo root, for a single example:

```bash
cd /home/acil/github/emopt/<example-dir>
export PYTHONPATH=/home/acil/github/emopt
export MPLBACKEND=Agg
export OMP_NUM_THREADS=1
timeout 180s /home/acil/miniforge3/envs/emopt/bin/python <script.py> |& tee /home/acil/github/emopt/.example-runs/<run-name>/<script>.log
```

Example:

```bash
cd /home/acil/github/emopt/examples/waveguide_bend
export PYTHONPATH=/home/acil/github/emopt
export MPLBACKEND=Agg
export OMP_NUM_THREADS=1
timeout 180s /home/acil/miniforge3/envs/emopt/bin/python wg_bend.py |& tee /home/acil/github/emopt/.example-runs/reconfirm_next/wg_bend.log
```

## Report/doc files to check/update

- `EXAMPLE_RUN_REPORT.md`
- this file: `EXAMPLE_REVALIDATION_RESUME.md`

`EXAMPLE_RUN_REPORT.md` still reflects the earlier branch state and has not yet been updated with the newly reconfirmed light-batch rerun from `2026-03-29 18:12 KST`.

## Git note

Before making any new repo edits, re-check:

```bash
git status --short
```

There are pre-existing local changes in `setup.sh` and pre-existing untracked files/directories that should not be clobbered blindly.
