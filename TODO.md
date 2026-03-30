# TODO

## Roadmap

This roadmap is intended to keep `main` focused on the highest-leverage work:
improve the simulation stack where it is clearly limited, make optimization
workflows more robust, and raise the engineering baseline around testing,
packaging, and examples.

## Next

### PETSc / SLEPc 3.24 upgrade

- Upgrade the numerical stack as a coordinated set, not piecemeal:
  PETSc, SLEPc, `petsc4py`, and `slepc4py` should move together to a `3.24.x`
  line.
- Treat this as a compatibility and supportability upgrade first, not a
  guaranteed solver-performance project.
- Preserve current solver behavior where possible:
  MUMPS-backed direct solves,
  current PETSc option usage,
  `GNHEP` mode-solver paths,
  existing example semantics.
- Keep the public API stable unless a break is clearly justified.

Planned execution order:

- Update install/build pins in `setup-system-deps.sh` and `setup-python.sh`.
- Rebuild PETSc/SLEPc and relink the Python bindings in a fresh `.venv`.
- Capture a `3.21.x` baseline before changing solver versions:
  wall-clock runtime,
  peak RSS if practical,
  solver success/failure,
  selected numerical outputs.
- Run focused solver checks first:
  import smoke,
  `petsc4py` scalar type check,
  `slepc4py` import,
  one 2D FDFD example,
  one 3D mode-solver example.
- Then run heavier validation:
  `examples/waveguide_bend/wg_bend.py`,
  `examples/MMI_splitter_3D/mmi_1x2_splitter_3D_fdfd.py`,
  selected tests under `tests/`.
- Compare behavior against the current `3.21.x` baseline:
  solve success,
  factorization failures,
  obvious memory regressions,
  major runtime deltas,
  effective-index consistency for mode solves.

Benchmark plan:

- Use a small fixed benchmark set that reflects the main solver modes used here:
  - one 2D FDFD example
  - one 3D full-vector mode solve
  - one heavier direct-solver case such as `examples/waveguide_bend/wg_bend.py`
  - one 3D FDFD example if runtime is still practical
- Run each benchmark from a clean shell with:
  `OMP_NUM_THREADS=1`,
  fixed MPI process count,
  fixed working directory,
  fixed input parameters.
- Record for each case:
  - success/failure
  - wall time
  - if easy to capture, peak RSS
  - key numerical outputs:
    effective index,
    a representative objective value,
    or another stable scalar result
- Prefer at least 3 runs for the smaller benchmarks and compare median runtime,
  not a single noisy timing.
- Treat performance as acceptable if:
  - no benchmark becomes numerically unstable
  - no benchmark regresses badly without a clear reason
  - runtime changes stay within a reasonable band unless stability improves
- If results are noisy, bias toward solver stability and reproducibility over a
  small runtime delta.

Code areas most likely to need attention:

- PETSc factor-solver compatibility shims in `emopt/fdfd.py` and `emopt/modes.py`
- transpose and matrix-copy paths in `emopt/fdfd.py`
- SLEPc eigenvalue handling in `emopt/modes.py`
- setup and smoke-test scripts

Decision rule:

- If `3.24.x` is stable with modest patching, keep it.
- If the upgrade creates repeated solver regressions or much higher build
  complexity, stop and document the blocker rather than forcing the bump.

### Anisotropic materials

- Add anisotropic permittivity support to the mode-solver path on `main`.
- Prefer a tensor-shaped API with explicit physical components over positional
  list conventions.
- Keep isotropic materials as a trivial compatible case.
- Scope the first implementation deliberately if needed:
  diagonal tensors first is acceptable if the public API does not block
  off-diagonal support later.
- Preserve a useful anisotropic example as both documentation and validation.
- Add tests for isotropic backward compatibility, diagonal anisotropy, and
  invalid tensor/input shapes.

### Reliability and tests

- Expand coverage beyond example smoke tests.
- Add focused tests for geometry helpers, material-grid behavior, mode-solver
  invariants, and adjoint gradient checks.
- Add at least one compact MPI test path in CI so solver regressions are caught
  before example-level failures.

### Packaging and build cleanup

- Reduce overlap and ambiguity between `pyproject.toml` and `setup.py`.
- Make the supported installation path explicit and keep the native-extension
  build prerequisites easy to diagnose.
- Remove or stop tracking generated build artifacts where possible.
- Standardize local run artifacts so they do not pollute the worktree by
  default.

### Documentation and quickstart

- Add a concise quickstart covering:
  forward simulation,
  mode solving plus source excitation,
  adjoint optimization.
- Document the current solver limitations more explicitly, especially around
  anisotropy, 3D constraints, and FDTD material support.
- Keep examples aligned with current install instructions and tested workflows.

## Later

### Broader solver capabilities

- Extend anisotropic material support beyond the mode solver where the
  formulation supports it.
- Improve 3D FDFD material handling beyond the current planar restrictions.
- Add cleaner support for additional boundary-condition and source workflows.
- Improve field extraction and interpolation consistency across solver types.

### Optimization workflow improvements

- Add source-derivative support in the adjoint stack.
- Reduce gradient-computation cost through better update-box handling and
  matrix-update reuse.
- Add more structured helpers for constrained optimization workflows.
- Improve parity between the classic adjoint path and the experimental
  autodiff-enhanced path.

### User experience

- Refactor common example setup into reusable helpers instead of duplicating
  boilerplate across scripts.
- Improve error messages around missing PETSc, SLEPc, MPI, and native build
  dependencies.
- Add a cleaner results/logging story for longer optimization runs, including
  saved snapshots and restart-friendly outputs.

## Research

### Material models

- Investigate dispersive and more general lossy material support in FDTD.
- Evaluate whether full tensor permittivity support is practical in the
  full-vector formulations currently used here.

### Parallel and performance work

- Revisit whether parts of the optimization loop should move off the current
  `scipy.optimize.minimize` orchestration model.
- Identify hotspots in matrix assembly, field extraction, and grid smoothing
  that would benefit from native or parallel refactors.

### Experimental workflows

- Clarify which pieces of `emopt.experimental` are ready to stabilize into the
  main API.
- Define a migration path for experimental autodiff geometry and optimization
  features if they become first-class.

## Open questions

- Does PETSc/SLEPc `3.24.x` materially improve robustness on the difficult
  MUMPS-backed problems used here, or is the real value mainly supportability
  and Python/toolchain freshness?
- Which validation set is the minimum credible gate for numerical-stack
  upgrades on this repo?
- Which examples are the best long-term benchmark fixtures for solver upgrades,
  and do any need reduced-size benchmark variants for repeatable timing?
- Should anisotropic support remain mode-solver-first for a while, or should
  the API be designed immediately for cross-solver reuse?
- What is the smallest CI matrix that still gives confidence for MPI, PETSc,
  SLEPc, and native-extension changes?
- Which examples are the canonical validation targets that should never regress
  on `main`?
