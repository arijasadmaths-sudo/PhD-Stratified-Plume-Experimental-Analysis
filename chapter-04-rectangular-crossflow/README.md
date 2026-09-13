# Chapter 4 — Rectangular crossflow

The common image-profile processing is in [densityheight.m](../shared/densityheight.m). This routine was adapted for the different experimental configurations. Supply the measurement columns, reference image and times for the selected sequence; these are not inferred from the chapter name.

The supplied version performs reference subtraction and normalisation of image profiles. Dimensional density translation requires profiles on a common calibrated density scale. Independent normalisation does not retain that information.

The translating-profile model, its parameter reporting and the density-evolution checks are not implemented in the six files supplied here. Their inclusion status remains recorded in the [coverage checklist](../SCRIPT_CHECKLIST.md).
