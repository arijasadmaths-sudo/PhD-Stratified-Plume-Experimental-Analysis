# Chapter 4 — Rectangular crossflow

[Back to the coverage checklist](../SCRIPT_CHECKLIST.md)

The known crossflow_fixed_eta.m workflow may cover all three entries. Record the same filename three times if so. The agreed model keeps d(rho)/dt approximately equal to S; a normalised profile alone does not preserve the dimensional translation.

## Workflows to include

These are workflow groups, not a required number of separate files. Suggested names can be replaced by your actual filenames.

## X1 — Density translation and amplitude analysis

**Suggested or known candidate name:** `crossflow_fixed_eta.m`.

Measure the profile range and endpoint density trends; compare the evolution with the prescribed freshening rate S and assess the residual after removing the predicted translation.

| Item | Description |
| --- | --- |
| Inputs | A time-ordered sequence retaining a common density scale, plus Q, densities, volume and timestamps. |
| Outputs | Mean amplitude, amplitude variation, top/bottom slopes, slope-to-S ratios and translation residual summaries. |
| Settings to explain | Fixed height coordinates, retained window, reference/crop, actual time gaps and normalisation. The confirmed base spacing for these Chapter 4 PNG sequences is 600 s; preserve gaps caused by selection. |

## X2 — Translating-profile model and parameter reporting

**Suggested or known candidate name:** `crossflow_fixed_eta.m`.

Evaluate the translating profile with nonzero alpha, compare its spatial shape with measurements, and report gamma, the adopted Up/Tp and conditional K.

| Item | Description |
| --- | --- |
| Inputs | Established-profile selections, measured amplitudes and the model inputs. |
| Outputs | Profile comparisons, parameter tables and available shape-error summaries. |
| Settings to explain | Preserve the nonzero density translation. Distinguish selected/fitted quantities from model estimates and record the adopted volume and density values. |

## X3 — Approximation checks and summary exports

**Suggested or known candidate name:** `crossflow_fixed_eta.m or a helper`.

Export the agreed translation checks and compare exact versus linear inventory freshening. Include transport-scaled derivative diagnostics if the program already calculates them.

| Item | Description |
| --- | --- |
| Inputs | The X1/X2 selections and available dimensional time-series outputs. |
| Outputs | Per-flow summaries; any interval tables; inventory-comparison results. |
| Settings to explain | The extra derivative ratios are additional diagnostics. Do not create new analysis solely to fill this checklist; state which checks are implemented. |

## When adding the code

Replace the candidate filename with the actual entry point, give a run command and list the required software/helpers. State the version or test status only when known. Record coverage in [SCRIPT_CHECKLIST.md](../SCRIPT_CHECKLIST.md); the same script can cover more than one entry.
