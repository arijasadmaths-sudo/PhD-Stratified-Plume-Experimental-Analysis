# Image-edge measurements

`auto_vorticity_length.m` measures the separation of two image-intensity edges. The script name is historical; its output is an edge separation, not vorticity.

Use a graphical MATLAB session for frame review and plot editing. Complete the required fields in `auto_vorticity_length_config.m` and run:

```matlab
addpath('chapter-03-rectangular-quiescent');
cfg = auto_vorticity_length_config();
[results, fits] = auto_vorticity_length(cfg);
```

| Setting | Input |
| --- | --- |
| `inputFolder`, `outputFolder` | Source images and a separate results folder. |
| `imageOrder`, `framePositions` | Optional permutation of lexically sorted filenames, and positions in that ordered sequence. Empty `imageOrder` uses natural filename order; empty `framePositions` selects all images. |
| `cropRect`, `bandRows`, `referenceWidthPx` | One-based pixel crop `[x y width height]`, first and last rows to average within the crop, and pixel scale for normalised separation. |
| `timeValues`, `timeOrigin`, `timeScale` | One time per ordered image, before frame selection. The plotted time is `(timeValues-timeOrigin)/timeScale`. |
| `detector.smoothWindow`, `detector.minWidthPx`, `detector.centreGapPx`, `detector.minContrast` | Odd smoothing width, minimum separation, central exclusion width, and contrast threshold. |

The remaining detector options are documented in the configuration template. `selectionMode = 'outermost'` selects the widest qualifying edge pair; `'best-pair'` scores pairs and checks competing candidates. `reviewEachFrame` lets you confirm, replace or skip each detection. Closing the review dialogue saves measurements already confirmed.

`earlyFitPositions` and `powerFitPositions` refer to selected frame positions. An empty early interval disables the exponential fit; an empty power interval includes all selected frames. `powerMode = 'prescribed'` displays a supplied curve using either explicit coefficients or the physical parameters documented in the configuration file. Fits require at least three positive lengths at positive normalised times.

Results are saved in `outputFolder`:

| File | Contents |
| --- | --- |
| `edge_lengths.csv` | Frame order, times, edges and review status, including skipped frames. |
| `edge_lengths.mat` | Measurements, settings, fit coefficients and any plot edits. |
| `edges_*.png` | Frame overlays when `saveDiagnostics` is enabled. |
| `edge_lengths.png`, `edge_length_comparison.png` | Measured separations and fitted or prescribed curves. |

The plot editor can omit displayed points or curves without changing the measurements or refitting. Export also writes a plot without axes (PNG and PDF) and a CSV of displayed points.
