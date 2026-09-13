# Chapter 2 — PLIF and experimental processing

[Back to the coverage checklist](../SCRIPT_CHECKLIST.md)

If P1–P4 are combined in one program, list that same filename against each covered item. The profile routine must retain the narrow-window exception for circular crossflow when it is used. Where an intensity-derived pipeline is used, identify its outputs accordingly rather than calling them calibrated density.

## Workflows to include

These are workflow groups, not a required number of separate files. Suggested names can be replaced by your actual filenames.

## P1 — Optical and spatial calibration

**Suggested or known candidate name:** `plif_calibration.m`.

Establish the image-to-physical mapping, ray paths and calibration response used by the reconstruction. Include any helper that fits attenuation or evaluates incident ray intensity.

| Item | Description |
| --- | --- |
| Inputs | Calibration images, known grid geometry and optical/attenuation inputs. |
| Outputs | Calibration maps, coefficients and incident ray intensities. |
| Settings to explain | Exposure ratio, coordinate orientation, optical geometry and calibration units. |

## P2 — PLIF reconstruction

**Suggested or known candidate name:** `plif_reconstruct.m`.

Convert calibration intensities to floating point, apply the half-exposure correction before the common scaling, and perform the attenuation/inverse reconstruction. State how imported colour planes are handled.

| Item | Description |
| --- | --- |
| Inputs | Experimental TIFFs and the calibration outputs from P1. |
| Outputs | Reconstructed source-fluid-fraction proxy chi and dimensional density rho, with any convergence flags the implementation provides. |
| Settings to explain | Operation order, reference densities, solver settings and common camera scale. |

## P3 — Forward reconstruction-consistency check

**Suggested or known candidate name:** `plif_forward_check.m`.

Forward-predict fluorescence and compare it with the measurement over the same retained region. This covers the four-frame check and processed-versus-measured comparison figure.

| Item | Description |
| --- | --- |
| Inputs | Measured fluorescence, reconstructed chi and the same optical calibration used for inversion. |
| Outputs | Synthetic fluorescence, residual maps, comparison panels and residual/RMSE/NRMSE summaries. |
| Settings to explain | Exposure-corrected inputs, bottom-200-row exclusion and residual normalisation; this is an internal consistency check. |

## P4 — Vertical profiles and stratification heights

**Suggested or known candidate name:** `extract_profiles_and_height.m`.

Average over the appropriate columns, smooth as required, retain dimensional profiles and extrema, calculate phi_m, and detect h_epsilon(t). A common implementation can serve Chapters 3–5.

| Item | Description |
| --- | --- |
| Inputs | Ordered reconstructed fields, timestamps and a selected measurement window. |
| Outputs | Vertical coordinates, dimensional profiles, normalised profiles, density extrema and dimensional height histories. |
| Settings to explain | Pixel scale, crop/window, time origin, actual retained spacing, smoothing order/width and fixed per-record epsilon. For the supplied thesis comparisons, Run 1 is displayed. |

## When adding the code

Replace the candidate filename with the actual entry point, give a run command and list the required software/helpers. State the version or test status only when known. Record coverage in [SCRIPT_CHECKLIST.md](../SCRIPT_CHECKLIST.md); the same script can cover more than one entry.
