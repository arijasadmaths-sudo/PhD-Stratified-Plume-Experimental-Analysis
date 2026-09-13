# Mixing behaviour of plumes — supporting code

Supporting code for Arij Asad's PhD thesis, *Mixing behaviour of plumes*, University of Bristol.

This repository contains general versions of the MATLAB code used for the experimental processing and analysis. The input files, calibration, measurement window and time coordinates are supplied for each configuration.

`densityheight` was used in most situations, with small changes for each configuration. Its common processing is kept in `shared/`, so it does not need a separate copy for every chapter. The supplied version produces normalised image profiles; the input scale determines their physical interpretation.

These files document the methods and their required settings. They are not an archive of every historical script, experimental record or figure configuration. Experimental images and fitted values are not included.

## Included code

| Entry point | Purpose |
| --- | --- |
| [densityheight.m](shared/densityheight.m) | Average image columns, subtract a reference profile, normalise profiles and compare selected signals with fitted curves |
| [image_saver.m](shared/image_saver.m) | Select existing TIFF files and copy or move them to another folder |
| [Propanolweight.m](shared/Propanolweight.m) | Calculate a propanol addition from supplied refractive-index calibration tables |
| [test_forward_ray_A.m](chapter-02-plif/test_forward_ray_A.m) | Reconstruct a scalar field from fluorescence images and calibration data |
| [validate_plif_reconstruction.m](chapter-02-plif/validate_plif_reconstruction.m) | Compare measured fluorescence with a forward image using the incident intensities used in reconstruction |
| [auto_vorticity_length.m](chapter-03-rectangular-quiescent/auto_vorticity_length.m) | Measure image-edge separation, review detections and compare length histories with exponential and power curves |

The two PLIF entry points share the reconstruction routines. The name `auto_vorticity_length` is retained for continuity; it measures lengths in scalar images, not a vorticity field.

## Adding your scripts

The [script coverage checklist](SCRIPT_CHECKLIST.md) records which parts of the wider thesis workflow are supplied. One entry point can serve several configurations. Numerical solvers and further analysis files can be added to the existing chapter folders when available.

## Repository structure

| Folder | Intended contents |
| --- | --- |
| `chapter-02-plif/` | PLIF calibration, reconstruction and image processing |
| `chapter-03-rectangular-quiescent/` | Layer heights, density profiles and dye-feature analysis in the quiescent rectangular enclosure |
| `chapter-04-rectangular-crossflow/` | Density profiles and reduced-model analysis for rectangular crossflow |
| `chapter-05-circular-enclosure/` | Layer heights, density profiles and crossflow analysis in the circular enclosure |
| `chapter-06-numerical-models/` | Numerical models and their post-processing |
| `shared/` | Functions used by more than one analysis |
| `examples/` | Small example inputs and demonstrations, where available |

## Using the code

Start with the instructions in [shared/](shared/README.md), [Chapter 2](chapter-02-plif/README.md) or [Chapter 3](chapter-03-rectangular-quiescent/README.md). Add the relevant folders to the MATLAB path, fill in the required configuration inputs, then call the entry point. Empty required settings are deliberate: the code does not assume a particular experiment.

Use the timestamps and spatial calibration belonging to the selected images. Retained-image spacing is separate from camera frame rate. A normalised image profile alone does not establish dimensional density or a threshold-defined layer height.

MATLAB is required, with the Image Processing Toolbox for the image workflows. The interactive review tools need a graphical MATLAB session. The cleaned code has undergone static syntax and source review; MATLAB execution and data-based validation have not been performed in this environment. See [CODE_NOTES.md](CODE_NOTES.md) for the changes and limits of this check.

See [ADDING_SCRIPTS.md](ADDING_SCRIPTS.md) for the short guide to adding code.

