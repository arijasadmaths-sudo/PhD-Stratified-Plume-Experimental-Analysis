# Mixing behaviour of plumes — supporting code

Supporting MATLAB code for Arij Asad's PhD thesis, *Mixing behaviour of plumes*, University of Bristol.

This repository contains cleaned, general versions of the six supplied experimental-processing and analysis workflows. Local paths, experiment-specific image selections, crop dimensions, calibration values, frame intervals and fitted constants have been removed. The required settings are supplied by the user for each data set.

Experimental images, calibration data and fitted results are not included.

## Main files

| File | Purpose |
| --- | --- |
| [densityheight.m](shared/densityheight.m) | Average image columns, subtract a reference profile, normalise profiles and compare selected signals with fitted curves |
| [detect_stratification_depth.m](shared/detect_stratification_depth.m) | Apply the thesis bottom-up dimensional density-difference detector with exact ambient-return rejection |
| [stratification_height_tolerances.m](shared/stratification_height_tolerances.m) | Return the repeat-specific neighbouring-row tolerances reported in the thesis |
| [image_saver.m](shared/image_saver.m) | Select existing TIFF files and copy or move them to another folder |
| [Propanolweight.m](shared/Propanolweight.m) | Calculate a propanol addition from supplied refractive-index calibration tables |
| [test_forward_ray_A.m](chapter-02-plif/test_forward_ray_A.m) | Reconstruct a scalar field from fluorescence images and calibration data |
| [validate_plif_reconstruction.m](chapter-02-plif/validate_plif_reconstruction.m) | Compare measured fluorescence with its forward reconstruction |
| [auto_vorticity_length.m](chapter-03-rectangular-quiescent/auto_vorticity_length.m) | Measure image-edge separation, review detections and compare length histories with fitted curves |

The PLIF scripts use four supporting files in the same folder: `plif_settings.m`, `plif_prepare.m`, `plif_read_image.m` and `plif_reconstruct.m`. The image-edge script uses `auto_vorticity_length_config.m` as its configuration template.

`densityheight.m` was used in most experimental configurations with small changes to the inputs. The common processing is kept as one configurable function in `shared/`.

## Repository structure

| Folder | Contents |
| --- | --- |
| [chapter-02-plif](chapter-02-plif) | PLIF reconstruction, forward comparison and the required shared routines |
| [chapter-03-rectangular-quiescent](chapter-03-rectangular-quiescent) | Image-edge measurements and fitted length histories |
| [shared](shared) | Image profiles, TIFF selection and refractive-index matching |

## Using the code

Start with the README in the relevant folder. Add that folder to the MATLAB path, complete the required configuration and call the entry point.

MATLAB is required. The image workflows use Image Processing Toolbox, and the interactive review tools require a graphical MATLAB session.

The code has undergone static syntax and source review. It has not been run against the original data in this repository, because those data are not included. The files support the methods used in the thesis; they are not an archive of every historical script or run-specific setting.
