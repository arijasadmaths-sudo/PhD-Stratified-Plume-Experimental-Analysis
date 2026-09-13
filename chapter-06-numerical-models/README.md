# Chapter 6 — Numerical models

[Back to the coverage checklist](../SCRIPT_CHECKLIST.md)

Include separate mesh builders, boundary-marker files, environment notes and HPC submission scripts beside the solver whenever it needs them. They can be helpers rather than separate analyses. Use subfolders for Cartesian, axisymmetric and 3D code if useful; unfinished numerical investigations do not need to be presented as completed results.

## Workflows to include

These are workflow groups, not a required number of separate files. Suggested names can be replaced by your actual filenames.

## N1 — Two-dimensional Cartesian model

**Suggested or known candidate name:** `cartesian_plume.py`.

Implement the Cartesian flow and scalar formulation described in the submitted chapter, including the boundary flux balance. Mesh creation may be inside this script.

| Item | Description |
| --- | --- |
| Inputs | Domain/mesh, source and return boundaries, fluid/scalar inputs and time-stepping settings. |
| Outputs | Saved velocity, pressure and scalar fields, run configuration and available diagnostic logs. |
| Settings to explain | State the FEniCS/DOLFIN environment actually used, numerical scheme and treatment of scalar bounds/conservation. |

## N2 — Axisymmetric model

**Suggested or known candidate name:** `axisymmetric_plume.py`.

Implement the axisymmetric formulation with the correct geometric weighting, boundary fluxes and scalar transport.

| Item | Description |
| --- | --- |
| Inputs | Axisymmetric geometry/mesh and flow, scalar and time-stepping inputs. |
| Outputs | Saved fields, run configuration and available flux/scalar-budget diagnostics. |
| Settings to explain | Axisymmetric/transformed-coordinate convention, discretisation and any boundedness correction. |

## N3 — Three-dimensional model

**Suggested or known candidate name:** `plume_3d.py`.

Provide the three-dimensional formulation represented in the submitted thesis, including conservative scalar-flux reconstruction where used.

| Item | Description |
| --- | --- |
| Inputs | Three-dimensional geometry, refined mesh, boundaries and solver/transport settings. |
| Outputs | Saved fields, solver logs and available conservation diagnostics. |
| Settings to explain | State the formulation and demonstrated scope. Providing the code does not claim completed long-time or convergence results. |

## N4 — Numerical post-processing and existing verification

**Suggested or known candidate name:** `postprocess_numerics.py or .m`.

Create snapshots, profiles and height histories; summarise volume/scalar fluxes and budgets. Include any existing mesh/time-step comparison routines used for reported results.

| Item | Description |
| --- | --- |
| Inputs | Saved simulation fields, timestamps, configuration and diagnostic logs. |
| Outputs | Numerical figures, diagnostic tables and comparisons between the runs actually analysed. |
| Settings to explain | Coordinate/volume weighting, scalar-to-density mapping, time alignment and parameters varied between runs. |

## When adding the code

Replace the candidate filename with the actual entry point, give a run command and list the required software/helpers. State the version or test status only when known. Record coverage in [SCRIPT_CHECKLIST.md](../SCRIPT_CHECKLIST.md); the same script can cover more than one entry.
