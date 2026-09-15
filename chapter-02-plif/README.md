# PLIF reconstruction

These functions reconstruct a dimensionless field from fluorescence images, then calculate the fluorescence that the reconstructed field would produce. The inverse and forward methods come from the supplied `test_forward_ray_A` and `validate_plif_reconstruction_checkpoint_v3` scripts. Their shared calculations are in `plif_reconstruct.m`.

The model uses one light source, refraction through the wall and straight light tubes in the fluid. Image rows follow the direction of propagation. The reconstructed field is bounded between 0 and 1; converting this field to density requires the density calibration for the data set.

## Setup

Use MATLAB with Image Processing Toolbox. The drivers also use `tiledlayout` and `exportgraphics`; use a MATLAB release that provides both. Add this folder to the MATLAB path. All required supporting functions are kept in this folder.

```matlab
addpath('chapter-02-plif'); % From the repository root.
cfg = plif_settings();
% Fill in cfg with the settings for the images being processed.
outputs = test_forward_ray_A(cfg);
summary = validate_plif_reconstruction(cfg);
```

`plif_settings` deliberately leaves measured quantities unset. Set them before running either driver. Keep a copy of the completed configuration with the data.

| Setting | Meaning |
| --- | --- |
| `inputFolder`, `outputFolder` | Input images and saved results. |
| `calibrationFile` | Calibration image filename, relative to `inputFolder`. |
| `imageFiles` | Image filenames in processing order, excluding the calibration image. |
| `cropRect` | `[x y width height]`, using one-based pixel indices and width/height as pixel counts; `[]` uses the full image. Applied to both calibration and measurement images. |
| `resizeScale` | Common image resizing factor. The cropped images must have equal dimensions. |
| `intensityDivisor` | Raw image value that represents intensity 1. RGB images use the mean of the three channels. |
| `calibrationScaleFactor` | Multiplier placing calibration and measurement images on a common intensity scale. |
| `geometry.sourceCoordinates` | `[horizontal vertical]` source position in cropped, unresized image coordinates. A source above the crop has a negative vertical coordinate. |
| `geometry.refractiveIndices` | `[air wall fluid]`. |
| `geometry.wallThickness`, `geometry.unseenFluidDepth` | Distances in the same pixel units as the unresized source coordinates. |
| `geometry.fanHalfAngleDegrees` | Fan half-angle in air, in degrees. |
| `calibrationField` | Known dimensionless field on the resized grid, with values in `[0,1]`. Supply an array or a function handle accepting `[rows cols]`. |
| `kappa0` | Background attenuation per resized image row. |
| `kappa1` | Field-dependent attenuation coefficient. Set `[]` to fit it from the calibration image, or supply a positive scalar. |
| `attenuationFitRows` | Inclusive `[first last]` rows used when fitting `kappa1`. These refer to the resized image. The original fit uses row index divided by the light-tube path length across one row. |
| `forwardIncidentIntensity` | For the forward driver, use `'calibration'`, a nonnegative scalar, or one intensity per reconstructed image column. |
| `signalThresholdFraction` | Fraction of the measured intensity range used to select the signal region in validation. |
| `figureResolution`, `overwrite` | Diagnostic figure resolution in dpi and permission to replace existing output files. |

Changing the image size, crop or optical system requires checking the geometry and attenuation settings. Lens correction is not included; where required, apply an independently calibrated correction to both image sets before reconstruction.

## Outputs

`test_forward_ray_A` saves the reconstructed field as a standalone greyscale PNG in `outputFolder/reconstructed_fields`. This folder can be supplied to `densityheight` for image-profile processing. The PNG quantises the field; the MAT file retains its full numerical precision. Do not feed the diagnostic panel images to `densityheight`. The returned cell array has one row per image, with paths to the MAT file, comparison PNG and standalone field PNG in that order.

The output folder also contains a MAT file and a four-panel diagnostic PNG for each image. The MAT file includes the reconstructed field, measured and synthetic fluorescence, incident-intensity estimates, attenuation coefficients, configuration and source filename.

`validate_plif_reconstruction` always uses the calibration-derived incident intensities for both reconstruction and forward projection. It saves a MAT file and a three-panel comparison for each completed image, plus `PLIF_validation_summary.csv`. The summary reports RMSE, mean and maximum absolute residual, correlation, and errors within the signal region. NRMSE is reported as a percentage of the measured intensity range, separately for the full image and signal region.

This comparison measures consistency between reconstruction and forward projection using the same optical model. It does not provide an independent validation of absolute density.
