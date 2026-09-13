# Script coverage checklist

Use this page to track the general workflows accompanying *Mixing behaviour of plumes*. These entries are based on the methods in the current thesis, not a requirement to recover an exact script for every experimental record.

One master script may cover several entries. Reuse its filename wherever appropriate; helper functions, notebooks, worksheets and documented external repositories can also provide coverage. Suggested filenames below are labels to help locate the code, not claims that those files exist. Keep your own filenames.

Tick an entry when its code and short description are included, and replace the dash with the actual path or external link. For an item handled inside another script, write that script's path. If an ancillary item was not used or is not being supplied, record that briefly instead of creating new code. An unticked entry means upload coverage has not yet been recorded; it does not mean the analysis was never performed.

To update the checklist on GitHub, edit this file, change `- [ ]` to `- [x]` for an included item, add its filename, and commit the change.

**Upload status:** no analysis scripts have yet been added to this scaffold. Checking an item records inclusion, not a claim that it has been runtime-tested.

## Chapter 2 — PLIF and experimental processing

[Descriptions, inputs and outputs](chapter-02-plif/README.md)

- [ ] **P1 — Optical and spatial calibration.** Code/location: —
- [ ] **P2 — PLIF reconstruction.** Code/location: —
- [ ] **P3 — Forward reconstruction-consistency check.** Code/location: —
- [ ] **P4 — Vertical profiles and stratification heights.** Code/location: —

## Chapter 3 — Rectangular enclosure without crossflow

[Descriptions, inputs and outputs](chapter-03-rectangular-quiescent/README.md)

- [ ] **R1 — Height-history analysis.** Code/location: —
- [ ] **R2 — Normalised density-profile comparison.** Code/location: —
- [ ] **R3 — Apparent dye-feature length extraction.** Code/location: —
- [ ] **R4 — Early- and late-time length fits.** Code/location: —

## Chapter 4 — Rectangular crossflow

[Descriptions, inputs and outputs](chapter-04-rectangular-crossflow/README.md)

- [ ] **X1 — Density translation and amplitude analysis.** Code/location: —
- [ ] **X2 — Translating-profile model and parameter reporting.** Code/location: —
- [ ] **X3 — Approximation checks and summary exports.** Code/location: —

## Chapter 5 — Circular enclosure

[Descriptions, inputs and outputs](chapter-05-circular-enclosure/README.md)

- [ ] **C1 — Circular geometry and stratification-height comparison.** Code/location: —
- [ ] **C2 — Quiescent circular density profiles.** Code/location: —
- [ ] **C3 — Circular-crossflow mean-profile fit.** Code/location: —
- [ ] **C4 — Circular-crossflow density-evolution checks.** Code/location: —

## Chapter 6 — Numerical models

[Descriptions, inputs and outputs](chapter-06-numerical-models/README.md)

- [ ] **N1 — Two-dimensional Cartesian model.** Code/location: —
- [ ] **N2 — Axisymmetric model.** Code/location: —
- [ ] **N3 — Three-dimensional model.** Code/location: —
- [ ] **N4 — Numerical post-processing and existing verification.** Code/location: —

## Shared code

[Descriptions, inputs and outputs](shared/README.md)

- [ ] **S1 — Shared processing, plotting and export helpers.** Code/location: —
- [ ] **S2 — Source and experimental parameter calculations.** Code/location: —

## Example inputs and a short run-through

[Descriptions, inputs and outputs](examples/README.md)

- [ ] **E1 — Small worked example.** Code/location: —

## Other supporting code, if used or available

- [ ] **Acquisition/controller software:** camera streaming, storage requests and control programs; include a maintained repository link if supplied elsewhere. Location or decision: —
- [ ] **Additional calibration utilities:** separate spatial-distortion or refractive-index interpolation scripts, if not already covered by P1. Location or decision: —
- [ ] **Intake-design/appendix utilities:** conformal-map, Laplace/streamfunction or CAD-generation code, if used for the documented design exploration. Location or decision: —
- [ ] **Solver support files:** separate mesh builders, boundary markers, environment instructions and scheduler launch files needed by N1–N3. Location or decision: —

These ancillary entries are reminders of existing supporting material, not requests for new research or new software.
