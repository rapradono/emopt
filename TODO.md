# TODO

## Anisotropic Materials

Goal: bring anisotropic mode-solver support to `main` without carrying forward
the branch-specific shortcuts from `origin/anisotropic-eps`.

### Keep

- Extend `ModeFullVector` so it can solve waveguide modes with anisotropic
  permittivity.
- Preserve the useful LiNbO3 example as a validation target and user-facing
  demonstration.
- Keep input validation around anisotropic material inputs instead of silently
  accepting unsupported shapes.

### Drop

- Do not keep the ad hoc `eps = [eps_x, eps_y, eps_z]` API as the long-term
  public interface.
- Do not merge the old example unchanged. It skips mode `0`, prints
  `modes.neff[0]` for both plotted modes, and is too narrowly tied to the
  original prototype.
- Do not revive the old installer or other branch-era compatibility edits just
  because they happened to live on the same feature branch.

### Preferred Direction

- Introduce a general tensor-material representation for the mode solver,
  preferably explicit enough to support:
  - isotropic materials as a trivial case
  - diagonal anisotropy
  - off-diagonal tensor terms when the formulation supports them
- Define the tensor API around physical components, not positional list
  conventions.
- Make domain-orientation handling explicit so tensor components are mapped
  correctly for `x`, `y`, and `z` propagation slices.

### Implementation Plan

- Design the anisotropic material API and decide whether it lives in
  `emopt.grid`, `emopt.modes`, or a small dedicated tensor helper module.
- Port the useful parts of the `origin/anisotropic-eps` `ModeFullVector`
  changes onto `main` in a form that matches the chosen tensor API.
- Add a corrected LiNbO3 example based on the old prototype.
- Add tests covering:
  - isotropic backward compatibility
  - diagonal anisotropy
  - invalid tensor/input shapes
  - at least one known-reference effective index or mode-field smoke test
- Document the supported tensor forms and any solver limitations.

### Open Questions

- Does the current full-vector formulation on this code path support a fully
  general permittivity tensor, or should the first version intentionally scope
  to diagonal tensors while keeping the API tensor-shaped?
- Should anisotropic support also be exposed to other solvers later, or remain
  mode-solver-only for now?
