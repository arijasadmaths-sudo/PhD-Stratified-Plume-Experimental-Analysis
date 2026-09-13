# Auxiliary PLIF functions

These functions retain reusable calculations found in the supplied PLIF scripts. They are separate from the main reconstruction path: neither `test_forward_ray_A` nor `validate_plif_reconstruction` calls them. Add this folder to the MATLAB path to use them.

| Original helper | Retained function or treatment |
| --- | --- |
| `calcbfracs2a` | `plif_overlap`: analytical light-tube/pixel overlap. The main reconstruction also keeps its local version. |
| `calcbfracs2` | `plif_overlap_polygon`: comparison using polygon intersections on a grid with `m.dy = 1`. The upper index is bounded by the last pixel. |
| `precomputeArea` | `plif_precompute_area`: sparse light-tube-to-image map. Geometry-dependent MAT-file caching has been removed. Calls `plif_overlap`. |
| `calcI0` | `plif_ray_incident_estimates`: alternative incident-intensity estimate. Input fluorescence must have one column per ray. Calls `plif_overlap`. |
| `analyse_image` | `plif_column_incident_estimates`: parallel-column intensity estimate with attenuation supplied as an argument. |
| `makeNewImage` | `plif_column_forward`: parallel-column forward calculation, with both attenuation coefficients supplied as arguments. |
| `create_angled_image` | `plif_trial_fan_image`: trial fan calculation using the dimensions of the supplied field. This is separate from the light-tube forward model. |
| `find_laser_coordinates_from_lines` | `plif_source_from_lines`: mean of finite pairwise line intersections. Measured line coordinates are supplied as an argument; the recorded image coordinates have been removed. |
| `correct_lensref_dist` | `plif_apply_lens_maps`: application of supplied lens/refraction maps, optional area compensation, crop and resize. The map-building section depended on a particular light-panel image, system dimensions and local calibration files; those have been removed. Maps must be obtained from a separate optical calibration. |
| `correct_image_colour_lens` | Channel averaging is retained in the main image-intensity calculation, with an explicit divisor. Its unused optional `rgb2lin` preprocessing is not applied by the drivers. |
| `remapnl_light` | Omitted. The original function returned the input unchanged; its calculated nonlinear lookup table was not used. |
| `unpackArea`, `precomputeAreaIndices` | Omitted cache-access helpers. The main reconstruction calculates overlaps directly and the auxiliary sparse map does not use their persistent index cache. |

For light-tube functions, `m` contains `nx`, `ny`, `dx` and `dy`. `wf.brays` and `brays0` contain source cells whose `.r` cells hold `y_l`, `y_r`, `dy_l`, `dy_r` and `inten`. The image-grid convention has unit spacing. The ray-based intensity estimate also requires `rig.sigma(field)` and `rig.dsigma()` function handles.

The alternative incident-intensity recurrences include the current row in their cumulative attenuation. They are retained as separate calculations, not replacements for the main `reCalcI0` recurrence, which uses attenuation from preceding rows. Zero attenuation or zero calibration field can leave an incident intensity undefined; check for non-finite results when using these helpers.

`plif_apply_lens_maps` expects a greyscale image, a mapping structure with `G_hori` and `G_vert` arrays, and `refractX`/`refractZ` coordinate arrays. Interpolation outside the maps can produce `NaN`; choose the output crop accordingly. Its crop uses one-based `[x y width height]` with width and height given as pixel counts.

All nine auxiliary MATLAB files pass MISS_HIT parsing and lint checks. They have not been run against the original optical calibration images in this environment.
