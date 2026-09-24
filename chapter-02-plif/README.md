# PLIF reconstruction

`test_forward_ray_A.m` reconstructs a dimensionless field from each fluorescence image and saves its forward projection. `validate_plif_reconstruction.m` compares that forward projection with the measured fluorescence. Both drivers use `plif_prepare.m`, `plif_read_image.m` and `plif_reconstruct.m`.

Use MATLAB with Image Processing Toolbox and a release supporting `tiledlayout` and `exportgraphics`. From the repository root:

```matlab
addpath('chapter-02-plif');
cfg = plif_settings();
% Set the paths, image list, calibration and optical geometry for this run.
outputs = test_forward_ray_A(cfg);
summary = validate_plif_reconstruction(cfg);
```

`plif_settings.m` is a template. Its unset fields must be filled with measurements from the data set. In particular:

| Field | Input |
| --- | --- |
| `inputFolder`, `outputFolder`, `calibrationFile`, `imageFiles` | Source folder, destination, calibration image filename and ordered measurement filenames. |
| `cropRect`, `resizeScale` | Common crop `[x y width height]` in one-based source-image pixels (`[]` uses the full image) and resizing factor. |
| `intensityDivisor`, `calibrationScaleFactor` | Raw intensity corresponding to 1, and multiplier placing calibration and measurement images on a common scale. |
| `geometry.sourceCoordinates`, `geometry.wallThickness`, `geometry.unseenFluidDepth` | Source position `[horizontal vertical]` and distances in cropped, unresized image pixels. |
| `geometry.refractiveIndices`, `geometry.fanHalfAngleDegrees` | Refractive indices `[air wall fluid]` and source fan half-angle in degrees. |
| `calibrationField`, `kappa0`, `kappa1`, `attenuationFitRows` | Known field on the resized grid, background attenuation per resized row, optional field-dependent attenuation coefficient (`[]` fits it), and inclusive resized row range for that fit. |
| `forwardIncidentIntensity` | `'calibration'`, a nonnegative scalar or one value per image column for `test_forward_ray_A`. Validation uses calibration-derived values. |
| `signalThresholdFraction`, `figureResolution`, `overwrite` | Validation signal region, figure dpi and output replacement. |

`calibrationField` accepts an array or a function handle called with `[rows cols]`; its values must be in `[0,1]`. Apply the same crop to calibration and measurement images. Keep the completed settings with the source data.

`test_forward_ray_A` returns one row per image containing the paths to a MAT result, four-panel PNG and standalone reconstructed-field PNG. The standalone PNGs are saved in `outputFolder/reconstructed_fields` and can be read by `densityheight.m`. Use the MAT file for full numerical precision.

`validate_plif_reconstruction` saves per-image MAT files and three-panel PNGs, plus `PLIF_validation_summary.csv` with residuals and correlation for the full image and the selected signal region. This compares reconstruction and projection under the same optical model; it does not independently calibrate density.
