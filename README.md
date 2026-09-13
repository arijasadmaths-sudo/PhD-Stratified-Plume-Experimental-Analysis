# Mixing behaviour of plumes — supporting code

Supporting code for Arij Asad's PhD thesis, *Mixing behaviour of plumes*, University of Bristol.

This repository is intended to provide general implementations of the processing and analysis methods described in the thesis. Inputs and selection settings can be adjusted for individual experimental records. It is not a complete archive of the historical code and settings used to produce every figure.

The repository currently contains the folder structure and instructions for adding scripts. Analysis code, example inputs and results have not yet been added.

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

Once scripts have been added, start with the instructions in the relevant chapter folder. Each analysis should state its entry point, required input files and software requirements. Experimental data are not included unless explicitly identified in that folder.

Dataset-specific settings, such as crop bounds, spatial calibration, retained-frame spacing and smoothing width, should be checked before running an analysis. Example settings illustrate how to use the code; they should not be assumed to be the settings used for a particular thesis figure.

See [ADDING_SCRIPTS.md](ADDING_SCRIPTS.md) for the short guide to adding code.

