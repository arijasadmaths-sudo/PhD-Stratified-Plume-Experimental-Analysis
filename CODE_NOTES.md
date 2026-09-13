# Notes on the supplied code

The six uploaded MATLAB files were prepared as general supporting code. Local paths, image selections, crop dimensions, calibration values, frame intervals and fitted constants were removed from the implementations. Settings that affect the calculation are now supplied by the caller. Comments describe the calculation directly, and duplicate reconstruction routines are shared.

## Source files

| Uploaded file | Repository entry point |
| --- | --- |
| `densityheight_quiescent_cases.m` | `shared/densityheight.m` |
| `image_saver.m` | `shared/image_saver.m` |
| `Propanolweight(1).m` | `shared/Propanolweight.m` |
| `test_forward_ray_A(1).m` | `chapter-02-plif/test_forward_ray_A.m` |
| `validate_plif_reconstruction_checkpoint_v3(1).m` | `chapter-02-plif/validate_plif_reconstruction.m` |
| `auto_vorticity_length(1).m` | `chapter-03-rectangular-quiescent/auto_vorticity_length.m` |

`densityheight` was used in most situations with small changes for each configuration. The repository contains one general version of the supplied copy. It does not infer the processing settings of other copies from chapter names.

## Calculations retained

The profile routine retains column averaging, reference subtraction, inversion and scaling by the minimum over the retained sequence. Horizontal and vertical image inspection, power fitting, the linear/quadratic/exponential comparison and residual plots remain available. Section inspection reads the requested frames instead of assembling large duplicated image arrays.

The original quantity called `h` was a profile value selected beside the largest adjacent difference. Those values were then sorted across frames. That exact operation remains available as `legacyDiagnostic`, labelled as a dimensionless sorted signal. It is not reported as layer height. The separate optional spatial diagnostic returns the coordinate of the selected row without sorting and marks flat profiles as undefined. Selection uses adjacent differences, with no division by row spacing. Neither diagnostic implements the fixed-threshold layer-height method. No dimensional density conversion has been added.

The PLIF inversion retains the ray geometry, overlap fractions, attenuation, bounded Newton iteration and row marching from the supplied active code. Its output is a dimensionless field in the solver's range, not a density in kg m^-3. The calibration fit keeps the supplied row-index/per-row-ray-length coordinate. Changing that convention would be a separate scientific change.

The forward test previously used a fixed incident intensity for its diagnostic image. That value is now an explicit input. The validation entry point uses the same calibration-derived incident intensities for inversion and forward projection, as in the supplied validation file. This is an internal fluorescence-consistency check, not an independent density calibration.

The image-edge routine retains both selection modes, smoothing, manual review, skipped frames, exponential and power regressions, the prescribed power curve and plot editing. The model parameters are inputs. The name `auto_vorticity_length` is retained, but its outputs are image-edge separations. Failed detections keep their original time positions; plot edits do not alter the measurements or refit curves.

The propanol calculation retains the salt-selected pairing of interpolation segments and the original mass conversion. The calibration tables, densities and volume are required inputs. Internal salt-density knots now select the upper segment; the original two strict inequalities omitted the shared knot. The reported percentage is a mass ratio relative to the base fluid.

## Execution changes

- TIFF selection now copies by default; moving is an explicit option. It accepts a configurable range and includes both TIFF filename extensions, with checks against overwriting existing destination files.
- Image dimensions and selected coordinates are read from the inputs. Invalid settings and degenerate normalisations stop with an explanatory error.
- PLIF image values are converted to floating point before exposure scaling. Greyscale and indexed images are handled explicitly, and the existing RGB channel mean is retained.
- Standalone reconstructed-field PNGs remain available for image-profile processing in `reconstructed_fields/`. Comparison panels are saved separately. The MAT files also retain the full-precision fields; PNG export keeps the image quantisation of the original workflow.
- The attenuation fit accepts positive finite calibration samples. The old `real(log(...))` expression could retain the log-magnitude of negative values, including possible resizing undershoots; those values are now excluded.
- Profile figures are saved after labels are added. Fit coefficients use the documented time coordinates, and R² is undefined for a constant signal.

These changes make the supplied code configurable and its outputs interpretable. They are not a re-analysis of the experimental data.

## Auxiliary PLIF code

Reusable routines from the inactive parts of the PLIF files are retained in [chapter-02-plif/auxiliary](chapter-02-plif/auxiliary/README.md). They include column and ray incident-intensity estimates, a column forward calculation, overlap and area calculations, a trial synthetic fan, source estimates from measured lines and application of supplied lens maps. They do not run as part of the main reconstruction or forward-consistency check.

The duplicated reconstruction code, inactive fixed test scene, cache-index wrappers, no-op intensity remapping and experiment-specific lens-map construction were removed. The auxiliary notes map the retained routines to their original names. The supplied images, grid-point corrections and geometry would be needed to reproduce the omitted lens-calibration trials.

## Verification

All 20 MATLAB files passed the MISS_HIT syntax and lint checks. Source comparisons checked the active PLIF numerical routines, both image-edge detectors and fits, and the profile calculation. Separate arithmetic checks matched the original profile normalisation and sorted signal, the paired propanol interpolation and the prescribed length exponent.

MATLAB and Octave were unavailable in the preparation environment. These checks do not establish native MATLAB execution, interactive behaviour, convergence or agreement with the thesis figures. A run requires the appropriate images and completed calibration/configuration inputs.
