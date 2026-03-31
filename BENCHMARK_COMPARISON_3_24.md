# PETSc / SLEPc 3.24 Benchmark Comparison

This file compares the quick benchmark profile before and after upgrading the
 numerical stack from the `3.21.x` line to the `3.24.3` line.

## Compared runs

- Baseline reference:
  - [BENCHMARK_BASELINE.md](/home/acil/github/emopt/BENCHMARK_BASELINE.md)
  - artifact: `.example-runs/benchmarks/baseline-3.21_quick_20260331_072341/results.tsv`
- Post-upgrade run:
  - command:

```bash
scripts/benchmark_solver_stack.sh --label after-3.24 --profile quick --runs 3
```

  - artifact: `.example-runs/benchmarks/after-3.24_quick_20260331_092758/results.tsv`

## Environment after upgrade

- PETSc `3.24.3`
- SLEPc `3.24.3`
- `petsc4py==3.24.3`
- `slepc4py==3.24.3`
- Python `3.13.12`

## Result summary

- All quick-profile runs passed before the upgrade: `9/9`
- All quick-profile runs passed after the upgrade: `9/9`
- No scalar-output drift was observed in the mode-solver benchmark cases
- Runtime was modestly better on the three tracked quick cases
- RSS moved slightly up on two lighter cases and down on the 3D mode case

## Median comparison

| Case | Baseline wall time (s) | After wall time (s) | Delta | Baseline RSS (kB) | After RSS (kB) | Delta | Scalar check |
|---|---:|---:|---:|---:|---:|---:|---|
| `examples/simple_waveguide/simple_waveguide.py` | 4.21 | 4.05 | -3.8% | 528432 | 540252 | +2.2% | — |
| `examples/waveguide_modes/wg_modes_2D.py` | 0.89 | 0.85 | -4.5% | 146944 | 153976 | +4.8% | unchanged: `neff_mode0 = 0 : 3.2140  +  -0.0000 i` |
| `examples/waveguide_modes/wg_modes_3D.py` | 6.31 | 5.77 | -8.6% | 708080 | 679796 | -4.0% | unchanged: `effective_index = 2.923` |

## Interpretation

- On this quick benchmark set, the `3.24.3` upgrade did not introduce an
  obvious regression.
- The main value of the upgrade is still supportability and freshness of the
  PETSc/SLEPc stack, but the measured quick-profile performance is at least as
  good as the previous baseline.
- Additional compatibility smoke checks were run on heavier or more
  feature-specific examples, summarized below.

## Compatibility smoke checks

The quick benchmark suite does not exercise the optimization drivers or the
experimental adjoint code paths. To cover those after the upgrade, the
following cheap compatibility runs were executed with `OMP_NUM_THREADS=1`,
`mpirun -n 2`, and the upgraded `.venv`.

| Case | Command tweak | Outcome | Wall time (s) | Max RSS (kB) | Notes |
|---|---|---|---:|---:|---|
| `examples/waveguide_bend/wg_bend.py` | `--smoke` | PASS | 6.47 | 266944 | Skips gradient check and runs a single optimizer step. |
| `examples/experimental/fast_taper_2D_AutoDiff/FastTaper_2D_AutoDiffPNF2D.py` | `--nmax 1` | PASS | 16.64 | 1410728 | Exercises the experimental AutoDiff FDFD path. |
| `examples/experimental/splitter_2D_Topology/splitter_TopologyPNF2D.py` | `--nmax 1` | PASS | 8.85 | 757232 | Exercises the experimental topology optimization path. |

These checks are not benchmark-quality performance measurements, but they do
show that the upgraded PETSc/SLEPc stack still works across the main 2D solver,
an optimization example, and two distinct experimental code paths.
