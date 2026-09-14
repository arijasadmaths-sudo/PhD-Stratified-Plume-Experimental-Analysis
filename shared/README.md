# Image profiles

`densityheight.m` is a general version of the image-processing script used across the thesis, with the image selection and configuration supplied by the caller. It reads a sequence of greyscale or RGB images, averages selected columns and compares the resulting vertical profiles. MATLAB with the Image Processing Toolbox is required (`im2gray` and `im2double`).

Set the image order, timing and reference explicitly before running it:

```matlab
config.imageFolder = imageFolder;
config.imageFiles = retainedImageNames; % Filenames in time order.
config.timeSeconds = retainedImageTimes_s;
config.referenceFrame = referenceFrameIndex;
config.cropRows = retainedRows;
config.cropColumns = retainedColumns;
config.averagingColumns = profileColumns; % Indices within the cropped image.
config.rowCoordinates_m = retainedRowHeights_m;
config.outputFolder = outputFolder;
results = densityheight(config);
```

The variables in this example are inputs from the image sequence and its calibration. The crop and averaging fields may be omitted to use the whole image. Height coordinates may be omitted for a normalised coordinate that decreases from 1 at the top row to 0 at the bottom. Supply the physical coordinate of each retained row to use a spatial calibration; the script does not assume a pixel size or image orientation in metres.

For equally spaced retained images, use `frameIntervalSeconds` instead of `timeSeconds`. This is the interval between the images being analysed. If `imageFiles` is omitted, files matching `imagePattern` (default `*.png`) are sorted lexicographically by filename. Check that this agrees with the time vector; names such as `1.png`, `10.png`, `2.png` need an explicit order.

## Profile calculation

Writing the mean image intensity as `I` and the reference profile as `Iref`, the original calculation is retained:

```matlab
J = 1 - (I - Iref);
P = (J - min(J(:))) / (1 - min(J(:)));
```

The minimum is taken over the full retained sequence. Changing the retained images can therefore change the scaling of all profiles. This operation does not convert intensity to density in kg m^-3. Values are not clipped; profiles can exceed 1 when their intensity falls below the reference. A reference that gives a zero denominator is rejected.

## Optional diagnostics and fits

The supplied script found the largest difference between neighbouring profile values and selected one of the two values beside it. It then sorted those values across the image sequence and plotted `1 - sortedValues` as a height. These are profile values, not row positions, and sorting them removes their association with individual frames. The sorting has now been removed: `1 - profileValues` retains the original frame/time pairing. It remains an optional, dimensionless diagnostic, not a layer height:

```matlab
config.legacyDiagnostic = true;
config.fitTarget = 'legacy_profile_signal';
config.compareModels = true;
```

`legacy_sorted_signal` is no longer accepted as a fit target: the function stops with an explanatory error so an old configuration cannot silently change meaning. The result is now `results.legacy.timeOrderedSignal`, and the CSV field is `LegacyTimeOrderedSignal`. Previously exported sorted histories and fits are not repaired by this code change; regenerate them from the original ordered inputs.

Neither option implements the Chapter 2 bottom-up dimensional density-difference detector with its ambient-return rejection. That historical production implementation and its run-specific settings still need to be archived. Do not pass the thesis's kg m^-3 tolerances to this intensity-normalisation workflow.

Set `gradientDiagnostic = true` to inspect the coordinate of the selected row, keeping the same choice between neighbouring rows and retaining frame order. Selection uses the largest adjacent profile difference without dividing by row spacing; it is not a spatial derivative on a nonuniform grid. A flat profile has no gradient position and is recorded as `NaN`; such samples are excluded from fits. This spatial diagnostic is separate from the time-ordered profile-value signal. It is not a reconstruction of a threshold-based layer-height method, and it does not establish that the largest gradient identifies the layer boundary. Set `fitTarget = 'gradient_position'` explicitly to fit this coordinate.

The default `fitTarget = 'none'` does not fit a growth law. A requested power fit retains the original least-squares calculation in log-log space, using positive time/value pairs. Its R² is calculated in the original value space. The optional model comparison retains the linear, quadratic and `b*(1 + exp(-a*t))` models and their residual plots. R² ranks the fits on these samples; it does not establish a physical model. All fits use seconds, so coefficients from runs previously expressed in minutes need the corresponding unit conversion.

Use `inspectionFrames`, `inspectionRows` and `inspectionColumns` to inspect raw image sections. Rows and columns are indexed within the crop. These profiles are returned in `results.inspection` and plotted when `makePlots = true`.

## Results

Run `test_densityheight_time_order` with this folder on the MATLAB path for a synthetic regression test of a non-monotonic signal, its time pairing, fitted exponent and rejection of the removed option. The test was added during the audit fix; native MATLAB execution is still required (MATLAB/Octave were not available in the editing environment).

The returned structure contains the configuration, image order, raw and normalised profiles, normalisation constants, coordinates and any requested diagnostics or fits. No source images are changed. With `outputFolder` supplied, the script writes `results.mat`, `profiles.csv`, `diagnostics.csv` and any displayed figures as JPEG files. These filenames are replaced on a subsequent run to the same output folder. CSV row coordinates and gradient positions use metres when `rowCoordinates_m` was supplied and are otherwise dimensionless; their units are also stored in `results.coordinateUnits`.

## TIFF selection

`image_saver.m` selects files that already exist. It includes `.tif` and `.tiff` files, sorted alphabetically without regard to case. Use zero-padded frame names or check this ordering before choosing indices.

```matlab
selectedFiles = image_saver(sourceFolder, destinationFolder, ...
    firstIndex, stride, lastIndex, 'copy');
```

Selection is `firstIndex:stride:lastIndex`. Use `[]` for `lastIndex` to select through the last TIFF. Copying is the default; pass `'move'` explicitly to move the selected files. Existing destination files are checked before transfer and are not intentionally overwritten. This utility does not acquire camera images.

## Refractive-index matching

`Propanolweight.m` retains the paired interpolation used to calculate a propanol addition:

```matlab
[Grams, Prop, NaCln, segment] = Propanolweight( ...
    saltDensity, baseFluidDensity, baseFluidVolume, ...
    saltCalibration, propanolCalibration);
```

Densities are in kg m^-3 and base-fluid volume is in m^3 before the addition. Supply the measured calibration tables as `[density, refractive_index]` and `[refractive_index, mass_ratio_percent]`, with matching row counts. The salt density selects the same segment index in both tables; the function deliberately preserves that pairing. Internal density knots use the upper segment. Salt densities outside the calibration range are rejected; the paired propanol segment can extrapolate in refractive index, as in the supplied calculation.

`Prop` is grams of propanol per 100 grams of base fluid, and `Grams` is the mass to add. This is a mass ratio relative to the base fluid, not a percentage of the final mixture. `NaCln` is the interpolated salt-solution refractive index. No empirical calibration values are assumed. These two utilities use base MATLAB functions.
