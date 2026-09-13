# Script coverage

This records the code supplied with the thesis. A shared routine can support several configurations. Inclusion records the available implementation; it does not claim that every historical setting or figure has been archived.

The six supplied MATLAB files have been generalised and added to the repository. Their entry points and supporting functions are listed in the [README](README.md). The method-level changes are recorded in [CODE_NOTES.md](CODE_NOTES.md).

| Workflow | Included implementation and scope |
| --- | --- |
| P1 — Optical and spatial calibration | The PLIF code accepts optical geometry, source coordinates and a known calibration field, and estimates attenuation and incident intensity. A complete spatial-distortion calibration workflow is not supplied. |
| P2 — PLIF reconstruction | `chapter-02-plif/test_forward_ray_A.m` and the shared reconstruction functions |
| P3 — Forward consistency | `chapter-02-plif/validate_plif_reconstruction.m`; measured/forward residuals using common incident intensities |
| P4 — Vertical profiles and heights | `shared/densityheight.m` provides image-column averaging and profile normalisation. The supplied copy has no calibrated-density conversion or fixed-threshold layer-height method. Its historical profile-value calculation is labelled separately. |
| R1 — Height histories | The shared routine retains power fitting and model comparison for explicitly selected signals. Chapter-specific height-growth models are not supplied. |
| R2 — Quiescent rectangular profiles | `shared/densityheight.m` supplies the common processing and profile plots. The theoretical comparison profiles are not part of this copy. |
| R3 — Image-feature lengths | `chapter-03-rectangular-quiescent/auto_vorticity_length.m`; automatic edge selection and manual review |
| R4 — Length fits | The same entry point retains exponential and power fits and a prescribed power curve. It does not calculate all chapter-specific intersection or characteristic-time quantities. |
| X1–X3 — Rectangular-crossflow translation, profile model and checks | Not supplied in these six files; the shared profile routine can provide the initial image processing |
| C1 — Circular geometry and height model | Not supplied in these six files |
| C2 — Quiescent circular profiles | The shared profile routine was adapted for this configuration; no separate theoretical-profile implementation is supplied |
| C3–C4 — Circular-crossflow fitting and evolution checks | Not supplied in these six files |
| N1–N4 — Numerical solvers and post-processing | Not supplied in this upload; the numerical chapter folder is retained for these files |
| S1 — Shared processing and export | `shared/densityheight.m`, `shared/image_saver.m` and the helpers beside each entry point |
| S2 — Source-parameter calculations | General source-parameter worksheets are not supplied in these six files |
| Refractive-index matching | `shared/Propanolweight.m`; paired interpolation with user-supplied calibration tables |
| Input examples | Configuration templates and input descriptions are supplied; experimental images and run-specific settings are not included |

The separate [PLIF repository](https://github.com/arijasadmaths-sudo/PLIF) is also available. `image_saver.m` in this repository selects files that already exist; it does not acquire camera frames.
