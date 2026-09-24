# Shared experimental utilities

Add this folder to the MATLAB path before calling its functions. Image processing requires Image Processing Toolbox.

## Vertical image profiles

`densityheight.m` averages selected image columns, subtracts a reference profile and returns normalised image-intensity profiles. It does not convert intensity to density. Supply the ordered image filenames and calibration for each sequence:

```matlab
config.imageFolder = imageFolder;
config.imageFiles = retainedImageNames;     % In time order.
config.timeSeconds = retainedImageTimes_s;  % Or frameIntervalSeconds.
config.referenceFrame = referenceFrameIndex;
config.cropRows = retainedRows;
config.cropColumns = retainedColumns;
config.averagingColumns = profileColumns;   % Within the crop.
config.rowCoordinates_m = distancesBelowCeiling_m;
config.outputFolder = outputFolder;
results = densityheight(config);
```

Crop and averaging fields may be omitted to use the full image. Without `rowCoordinates_m`, the row coordinate runs from 0 at the top to 1 at the bottom. Without `imageFiles`, filenames matching `imagePattern` (default `*.png`) are sorted lexically; check their order against the times. The normalisation minimum comes from the whole retained sequence, so changing the selection changes the scale.

Optional `inspectionFrames`, `inspectionRows` and `inspectionColumns` select raw image sections. `gradientDiagnostic` returns the position beside the largest adjacent profile difference; `legacyDiagnostic` returns a time-ordered profile-value signal. Neither is a threshold-derived layer height. Set `fitTarget` to `'gradient_position'` or `'legacy_profile_signal'` to fit the corresponding enabled diagnostic; its default is `'none'`. `compareModels` enables additional curve comparisons. The removed `'legacy_sorted_signal'` target raises an error because sorting detached values from their frame times.

With `outputFolder` set, the function writes `results.mat`, `profiles.csv`, `diagnostics.csv` and displayed JPEG figures. Run `test_densityheight_time_order` for a synthetic time-order check.

## Stratification depth

`detect_stratification_depth.m` accepts reconstructed density profiles (rows by frames, kg m^-3), the height of each retained row (metres), ambient density and a neighbouring-row threshold (kg m^-3). An optional tank height returns `h = H-z_b`:

```matlab
result = detect_stratification_depth( ...
    densityProfiles, rowCoordinates_m, ambientDensity, epsilon, tankHeight_m);
```

It scans upwards from the lowest physical row. A neighbouring density difference strictly greater than `epsilon` gives a candidate at the lower row; any exactly ambient row above it rejects that candidate. The first candidate that passes this check is `z_b_m`. It also returns `h_m`, detected-row indices and a detection flag for each frame. The input must be a bounded, calibrated density field. `stratification_height_tolerances.m` returns a table of run-specific thresholds for the thesis data. Do not use these dimensional thresholds with `densityheight.m` intensity profiles. Run `test_detect_stratification_depth` for synthetic detector checks.

## TIFF selection

```matlab
selectedFiles = image_saver(sourceFolder, destinationFolder, ...
    firstIndex, stride, lastIndex, 'copy');
```

The selection is `firstIndex:stride:lastIndex`, applied to case-insensitively sorted `.tif` and `.tiff` filenames. Set `lastIndex = []` to continue through the last TIFF. The default operation copies; pass `'move'` to move files. Existing destination files are checked before transfer.

## Refractive-index matching

```matlab
[Grams, Prop, NaCln, segment] = Propanolweight( ...
    saltDensity, baseFluidDensity, baseFluidVolume, ...
    saltCalibration, propanolCalibration);
```

Densities are in kg m^-3 and base-fluid volume in m^3. Supply measured calibration arrays `[density, refractive_index]` and `[refractive_index, mass_ratio_percent]` with matched rows. `Prop` is grams of propanol per 100 grams of base fluid, `Grams` is the mass to add, and `NaCln` is the interpolated salt-solution refractive index.
