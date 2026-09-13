# Inputs and configuration

The configuration functions beside each entry point list the settings required for a run. They contain empty fields for measured quantities rather than values from a particular experiment.

Keep images in a separate input folder and write generated files to a separate output folder. Supply the calibration image by name. Check the selected file order before assigning timestamps: alphabetical ordering and numerical filename ordering can differ.

For the shared profile routine, provide the image sequence, selected columns, reference frame and time coordinates. For PLIF reconstruction, provide the optical calibration and the intensity scale as well. For image-edge measurements, provide the crop, averaging band, detector settings and time/length normalisations.

Experimental images are not included. See the [shared code instructions](../shared/README.md), [PLIF instructions](../chapter-02-plif/README.md) and [image-edge instructions](../chapter-03-rectangular-quiescent/README.md) for the entry points and outputs.
