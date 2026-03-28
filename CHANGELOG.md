# Changelog

## Backports from emopt-develop (2026-03-28)

The upstream maintainer's `develop` branch has diverged significantly (~2 years
of commits) from the `main` branch this repo is forked from. The changes below
were cherry-picked and adapted for compatibility.

### Bug fixes

- **`modes.py` — field interpolation typo** (`ModeFullVector.get_field_interp`):
  `fraw` was used instead of `f_raw` in the `Ex` branch, causing a `NameError`
  at runtime.

- **`modes.py` — `Hy` field returned with padding** (`ModeFullVector.get_field_interp`):
  The `Hy` branch returned the full zero-padded array instead of
  `f_raw[1:-1, 1:-1]`, causing an off-by-one shape mismatch downstream.

- **`modes.py` — 2D mode power normalization** (`ModeFullVector.get_source`):
  Only the z-component of the Poynting vector was used for normalization
  (`S = 0.5*dx*dy*(Ex*Hy* - Ey*Hx*)`). Replaced with the full 3D vector
  magnitude so that x- and y-propagating modes are normalized correctly.

- **`adjoint_method.py` — matplotlib deprecation**:
  `set_yscale('log', nonposy='clip')` → `set_yscale('log')` (kwarg removed in
  matplotlib ≥ 3.3).

- **`fdfd.py` — PETSc transpose API compatibility**:
  Replaced the reuse-mode `.duplicate(copy=True)` / `.transpose()` path with
  `A.transpose()` for cross-version PETSc compatibility in `FDFD_3D`.

### Memory leak fixes

- **`adjoint_method.py`** (`AdjointMethodFM2D.compute_gradient`): `dAdp` and
  `dAdp_full` PETSc distributed vectors were not freed between gradient loop
  iterations. Added `.destroy()` calls per iteration, and `Af.destroy()` /
  `Ai.destroy()` after the loop.

- **`modes.py`** (`ModeTE.__del__`, `ModeFullVector.__del__`): Added destructor
  methods that explicitly call `.destroy()` on PETSc matrices (`_A`, `_B`),
  eigenvectors (`_x`), and the SLEPc solver (`_solver`). Without these,
  PETSc/SLEPc objects accumulate whenever mode solvers go out of scope.

### Stability improvements

- **`modes.py`** (`ModeFullVector.__init__`): Set MUMPS ordering options
  `mat_mumps_icntl_28 = 2` and `mat_mumps_icntl_29 = 1` to improve numerical
  stability of the direct solver for difficult 2D full-vector eigenproblems.

### New features

- **`modes.py`** (`ModeFullVector.get_source`): Added deterministic phase
  constraining. Eigenmode solvers do not guarantee an absolute phase; the
  dominant source component is now rotated so its average phase is zero. This
  matters for S-parameter calculations and other phase-sensitive applications.

- **`emopt/dvio.py`** (new module): Backported visualization and I/O utilities:
  - `plot_iteration(field, structure, W, H, foms, ...)` — plots field, geometry,
    and FOM history with auto layout and optional dark theme.
  - `save_results(fname, data)` — saves simulation/optimization state to HDF5.
  - `load_results(fname)` — loads and MPI-broadcasts saved HDF5 data.
  - Usage: `import emopt.dvio`

---

## Skipped upstream changes (breaking API — incompatible with twig)

The following changes exist in `emopt-develop` but were **intentionally not
backported** because they break the API that `twig` depends on.

| Upstream change | Current API (emopt-main) | New API (emopt-develop) | twig files affected |
|---|---|---|---|
| `FDFD_TE` renamed | `emopt.fdfd.FDFD_TE` | `emopt.solvers.Maxwell2DTE` | `emopt_forward.py:334`, `emopt_adjoint.py:328`, `scattering.py:230` |
| `FDFD_TM` renamed | `emopt.fdfd.FDFD_TM` | `emopt.solvers.Maxwell2DTM` | (same files) |
| `FDFD_3D` renamed | `emopt.fdfd.FDFD_3D` | `emopt.solvers.Maxwell3D` | — |
| `ModeTE` renamed | `emopt.modes.ModeTE` | `emopt.solvers.Mode1DTE` | `emopt_forward.py:499,531`, `emopt_adjoint.py:466`, `scattering.py:290,314` |
| `ModeTM` renamed | `emopt.modes.ModeTM` | `emopt.solvers.Mode1DTM` | — |
| `ModeFullVector` renamed | `emopt.modes.ModeFullVector` | `emopt.solvers.Mode2D` | — |
| `AdjointMethodPNF2D` renamed | `emopt.adjoint_method.AdjointMethodPNF2D` | `emopt.opt_def.OptDefPNF2D` | `emopt_adjoint.py:40,296` (base class of `TWIGProxyAdjoint`) |
| `AdjointMethodMO` renamed | `emopt.adjoint_method.AdjointMethodMO` | `emopt.opt_def.OptDefMO` | `emopt_adjoint.py:39,681` (base class of `TWIGMultiWavelengthAdjoint`) |
| `set_sources()` signature | `set_sources(src, src_domain, mindex)` | `set_sources({domain: src})` | `emopt_forward.py:510`, `emopt_adjoint.py:477`, `scattering.py:301` |
| Module reorganization | flat `emopt/` layout | `emopt/solvers/` subdirectory | all import sites |

If twig is ever updated to target `emopt-develop` directly, all of the above
call sites will need to be migrated simultaneously.
