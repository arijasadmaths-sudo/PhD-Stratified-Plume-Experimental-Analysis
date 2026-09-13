# Chapter 3 — Rectangular enclosure without crossflow

[Back to the coverage checklist](../SCRIPT_CHECKLIST.md)

Known filenames to look for in the working material are densityheight.m, master_densityheight.m and auto_vorticity_length.m. They are candidates for these tasks, not files already uploaded here. One master can cover R1 and R2 across all configurations; do not duplicate it for each repeat.

## Workflows to include

These are workflow groups, not a required number of separate files. Suggested names can be replaced by your actual filenames.

## R1 — Height-history analysis

**Suggested or known candidate name:** `height_growth_analysis.m`.

Select the analysed interval and compare growth histories with the appropriate prescribed or fitted curves. Reuse this workflow for full-height, reduced-height and two-source records.

| Item | Description |
| --- | --- |
| Inputs | Height histories and timestamps from P4, plus the configuration and source flow rate. |
| Outputs | Dimensional and normalised height plots, T and h(T), and any fitted coefficients/residuals. |
| Settings to explain | Time origin, regime, height, Q or total/per-nozzle Q, and whether each exponent is prescribed or fitted. |

## R2 — Normalised density-profile comparison

**Suggested or known candidate name:** `density_profile_comparison.m`.

Plot the measured normalised profiles and the comparison functions actually used. Separate the reduced unit-interval fifth-order forms from any historical adjustable plotting guide.

| Item | Description |
| --- | --- |
| Inputs | Processed profiles, height information and the chosen coordinate mapping. |
| Outputs | Profile panels, model curves and available parameter/residual tables. |
| Settings to explain | Coordinate direction, normalisation, measured-versus-model variables and any adjustable guide parameters. |

## R3 — Apparent dye-feature length extraction

**Suggested or known candidate name:** `auto_vorticity_length.m`.

Extract the apparent length of vortex-like structures from the dye field, including smoothing, edge selection and manual review/omission.

| Item | Description |
| --- | --- |
| Inputs | Selected image sequence, crop, timestamps and physical pixel calibration. |
| Outputs | Accepted lengths in physical units, times, selected-frame identifiers and review plots. |
| Settings to explain | The supplied calibration is 0.21 mm per pixel. Identify reconstructed/default thresholds. These are scalar-image lengths, not measured vorticity or velocity. |

## R4 — Early- and late-time length fits

**Suggested or known candidate name:** `fit_dye_feature_lengths.m`.

Apply the early exponential and late algebraic fitting forms used in the thesis and determine their comparison/intersection quantities.

| Item | Description |
| --- | --- |
| Inputs | Accepted length-versus-time data from R3. |
| Outputs | Fit coefficients, selected intervals, characteristic times and fit overlays. |
| Settings to explain | Units, time origin, length normalisation, fitting convention and the chosen intersection when more than one exists. |

## When adding the code

Replace the candidate filename with the actual entry point, give a run command and list the required software/helpers. State the version or test status only when known. Record coverage in [SCRIPT_CHECKLIST.md](../SCRIPT_CHECKLIST.md); the same script can cover more than one entry.
