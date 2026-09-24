# Experimental analysis code

MATLAB scripts accompanying Arij Asad's PhD thesis, *Mixing behaviour of plumes* (University of Bristol).

| Folder | Entry points |
| --- | --- |
| [chapter-02-plif](chapter-02-plif) | `test_forward_ray_A.m`, `validate_plif_reconstruction.m` |
| [chapter-03-rectangular-quiescent](chapter-03-rectangular-quiescent) | `auto_vorticity_length.m` |
| [shared](shared) | `densityheight.m`, `detect_stratification_depth.m`, `stratification_height_tolerances.m`, `image_saver.m`, `Propanolweight.m` |

Each folder has a README with the required inputs and saved outputs. Add the relevant folder to the MATLAB path, supply the settings for the image sequence, and run its entry point. The PLIF drivers also require the supporting functions alongside them; `auto_vorticity_length.m` uses `auto_vorticity_length_config.m`.

MATLAB and Image Processing Toolbox are required for image processing. Interactive image review requires a graphical MATLAB session.

Source images, empirical calibrations and completed run configurations are not included. Supply the image selections, timing, geometry, crop and calibration values from the corresponding data set.
