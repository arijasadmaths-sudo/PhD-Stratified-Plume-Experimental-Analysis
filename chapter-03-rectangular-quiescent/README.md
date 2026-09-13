# Image-based vortex-ring measurements

`auto_vorticity_length.m` measures the separation of two intensity-profile edges. The filename follows the thesis code. The measurement can be used as a proxy for ring diameter; it does not calculate vorticity from a velocity field.

Complete the empty settings in `auto_vorticity_length_config.m`, then run:

```matlab
cfg = auto_vorticity_length_config();
[results, fits] = auto_vorticity_length(cfg);
```

The function uses MATLAB image, table, plotting and dialogue functions. Interactive review and plot editing require a graphical session.

## Settings

| Setting | Meaning |
| --- | --- |
| `inputFolder`, `outputFolder` | Source images and a separate results folder. |
| `cropRect` | `[x y width height]` in source-image pixels. |
| `bandRows` | First and last rows averaged within the crop. |
| `referenceWidthPx` | Pixel scale used to calculate normalised edge separation. |
| `timeValues` | One time for every image in the ordered sequence, before frame selection. |
| `timeOrigin`, `timeScale` | The plotted time is `(timeValues-timeOrigin)/timeScale`. Use consistent units. |
| `detector.smoothWindow` | Odd smoothing-window width in pixels. |
| `detector.minWidthPx`, `detector.centreGapPx` | Minimum separation and central exclusion width in pixels. |
| `detector.minContrast` | Minimum intensity contrast as a fraction of the image intensity scale. |

Pixel coordinates start at one. The crop and averaging band must lie inside each image. Inspect the edge overlays when choosing detector settings.

Empty `imageOrder` uses natural filename order, with `frame2` before `frame10`. A supplied permutation applies to the lexically sorted filenames. Empty `framePositions` selects every image; otherwise, positions refer to the ordered sequence. Supply `timeValues` in that same order. Frame positions can be supplied as the time coordinate explicitly if that is the intended convention.

The detector supports `outermost`, which selects the widest qualifying pair, and `best-pair`, which uses pair scores and rejects competing candidates. Review allows each proposal to be confirmed, replaced manually or skipped. Closing the review dialogue saves the measurements already confirmed. Set `reviewEachFrame = false` for automatic measurements.

## Fits and prescribed curves

`earlyFitPositions` and `powerFitPositions` refer to the selected sequence. Rejected measurements do not shift these positions. Empty `earlyFitPositions` disables the exponential fit; empty `powerFitPositions` uses all selected frames.

The power law and exponential are fitted in logarithmic length. Reported R² is calculated on the length scale within the corresponding fit interval. Only positive lengths and positive normalised times enter the comparison and fits. At least three valid points are required for each fit.

Set `powerMode = 'fit'` to display the power-law regression. Set it to `'prescribed'` to display a specified power law while retaining the regression results. A prescribed curve can use explicit amplitude and exponent, or the physical-parameter expression retained from the thesis script. Its settings are documented in the configuration file. The physical option requires all density, geometry and gravity inputs; the amplitude and exponent must use the same coordinate convention as the plotted data.

## Results

| File | Contents |
| --- | --- |
| `edge_lengths.csv` | Frame names, times, measured edges, automatic proposals and review status, including rejected and unprocessed frames. |
| `edge_lengths.mat` | Measurements, resolved settings and any fitted coefficients. |
| `edges_*.png` | Per-frame diagnostic overlays when `saveDiagnostics` is enabled. |
| `edge_lengths.png` | Edge separation in pixels against ordered frame position. |
| `edge_length_comparison.png` | Normalised measurements and comparison curves when enough valid points are available. |

The plot editor can remove points or curves, undo edits and save a figure without axes. These edits do not change the measurements or refit curves. Export creates `edge_length_comparison_no_axes.png`, the matching PDF and a `_points.csv` file recording the displayed points. The edit state is also saved in `edge_lengths.mat`.
