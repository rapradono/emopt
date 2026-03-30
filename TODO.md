# TODO

## Roadmap

This roadmap is intended to keep `main` focused on the highest-leverage work:
improve the simulation stack where it is clearly limited, make optimization
workflows more robust, and raise the engineering baseline around testing,
packaging, and examples.

## Next

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

- Should anisotropic support remain mode-solver-first for a while, or should
  the API be designed immediately for cross-solver reuse?
- What is the smallest CI matrix that still gives confidence for MPI, PETSc,
  SLEPc, and native-extension changes?
- Which examples are the canonical validation targets that should never regress
  on `main`?
