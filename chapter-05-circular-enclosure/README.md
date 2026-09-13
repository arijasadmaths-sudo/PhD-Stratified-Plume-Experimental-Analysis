# Chapter 5 — Circular enclosure

[Back to the coverage checklist](../SCRIPT_CHECKLIST.md)

Known candidate names are circular_crossflow_crop_v5.m and circular_crossflow_validity.m. Keep your actual filenames if different. One script may cover both fitting and evolution checks if it retains the inputs required for each.

## Workflows to include

These are workflow groups, not a required number of separate files. Suggested names can be replaced by your actual filenames.

## C1 — Circular geometry and stratification-height comparison

**Suggested or known candidate name:** `circular_geometry_height.m`.

Evaluate exact slice areas and upper-layer volumes, compare the exact height integrals with the near-ceiling power laws, and plot the measured height records.

| Item | Description |
| --- | --- |
| Inputs | Radius, enclosure length, height/time records and the model closure. |
| Outputs | Geometry functions, height comparisons and numerical quadrature/separation summaries. |
| Settings to explain | Post-impact time origin, h(T)/R, integration limits/tolerances and prescribed-versus-fitted exponents. |

## C2 — Quiescent circular density profiles

**Suggested or known candidate name:** `circular_quiescent_profiles.m`.

Produce the normalised profile comparisons with the chosen coordinate mapping and comparison function. Reuse the rectangular profile code where appropriate.

| Item | Description |
| --- | --- |
| Inputs | Circular quiescent profiles from the shared processing routine. |
| Outputs | Profile panels and the applicable model/guide parameters. |
| Settings to explain | The displayed quiescent cases use Q=20 and 50 cm^3/min. Document the mapping actually implemented; the height and shape comparisons remain separate analyses. |

## C3 — Circular-crossflow mean-profile fit

**Suggested or known candidate name:** `circular_crossflow_crop_v5.m`.

Form the mean of the processed experimental profiles and fit the endpoint-normalised error-function comparison used in Figure 5.11.

| Item | Description |
| --- | --- |
| Inputs | Retained profiles or images from the narrow window, plus normalisation and fitting inputs. |
| Outputs | Mean-profile/fit plots; mu_hat, delta_hat and the available fit statistics; dimensional position/width and conditional K when those outputs are calculated. |
| Settings to explain | Use the actual processing order and fit target. Identify H, the measurement window and the development-distance assumption. Mean-fit parameters are distinct from temporal-rate outputs. |

## C4 — Circular-crossflow density-evolution checks

**Suggested or known candidate name:** `circular_crossflow_validity.m or a helper`.

Export density-range, shape or translation-rate checks used to assess the approximation over the downstream travel time. The Chapter 5 freshening/translation comparison can be included here when the corresponding results are supplied.

| Item | Description |
| --- | --- |
| Inputs | Time-resolved profiles, their timestamps and the density/flow/volume inputs needed by the implemented check. |
| Outputs | Per-flow summaries and any validity_intervals.csv, validity_summary.txt or equivalent saved outputs. |
| Settings to explain | State which checks are implemented. Independently normalised profiles support shape checks; dimensional freshening needs a common density scale. Do not copy Chapter 4 timing into Chapter 5. |

## When adding the code

Replace the candidate filename with the actual entry point, give a run command and list the required software/helpers. State the version or test status only when known. Record coverage in [SCRIPT_CHECKLIST.md](../SCRIPT_CHECKLIST.md); the same script can cover more than one entry.
