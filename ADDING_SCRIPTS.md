# Adding scripts

Place each script in the relevant chapter folder. Put reusable functions in `shared/` and small example inputs in `examples/`. Keep the original filenames where that helps preserve function calls and dependencies.

Add a short README in each chapter folder explaining:

- Which method the scripts implement and which script to run first.
- The command to run it, including the expected working directory.
- The required input files, their format and units, and where to obtain them.
- The required software and toolboxes. State the version actually tested when known; otherwise say that the version or test status is unconfirmed.
- Which settings the user must adjust and what outputs the script produces.

Keep dataset-specific settings together near the top of the script or in a separate configuration file. Explain settings such as cropping, calibration, frame selection, timing, normalisation and smoothing wherever they affect the analysis. Label demonstration settings as examples unless they are verified for a named experimental record.

General implementations are welcome. If a script was reconstructed from the described method, say so briefly; do not present it as an exact copy of the historical analysis. Remove local machine paths and include or identify the helper functions it needs.

After adding the first scripts, update the repository README to describe what is available.
