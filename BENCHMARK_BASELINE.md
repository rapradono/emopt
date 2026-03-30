# Benchmark Baseline

This file records the pre-upgrade baseline for the `petsc-slepc-3.24-plan`
branch before changing PETSc, SLEPc, `petsc4py`, or `slepc4py`.

## Baseline run

- Branch: `petsc-slepc-3.24-plan`
- Baseline commit: `560732b`
- Python: `3.13.12`
- Benchmark script: `scripts/benchmark_solver_stack.sh`
- Command:

```bash
scripts/benchmark_solver_stack.sh --label baseline-3.21 --profile quick --runs 3
```

- MPI processes: `2`
- Per-case timeout: `300s`
- Result artifact:

```text
.example-runs/benchmarks/baseline-3.21_quick_20260331_072341/results.tsv
```

## Median results

| Case | Runs | Median wall time (s) | Median max RSS (kB) | Scalar check |
|---|---:|---:|---:|---|
| `examples/simple_waveguide/simple_waveguide.py` | 3 | 4.21 | 528432 | — |
| `examples/waveguide_modes/wg_modes_2D.py` | 3 | 0.89 | 146944 | `neff_mode0 = 0 : 3.2140  +  -0.0000 i` |
| `examples/waveguide_modes/wg_modes_3D.py` | 3 | 6.31 | 708080 | `effective_index = 2.923` |

## Notes

- All 9/9 quick-profile runs passed.
- This baseline should be re-used when comparing the same benchmark profile
  after the PETSc/SLEPc `3.24.x` upgrade work.
- If the benchmark script changes materially, record a fresh baseline before
  making numerical comparisons.
