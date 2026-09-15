function cfg = plif_settings()
% Set the image calibration and geometry before running either PLIF driver.
% Empty paths and NaN values must be replaced with values for the data set.

cfg.inputFolder = '';
cfg.outputFolder = '';
cfg.calibrationFile = '';
cfg.imageFiles = {};              % Filenames in the order to be processed.
cfg.cropRect = [];                % [x y width height], or [] for the full image.
cfg.resizeScale = 1;
cfg.intensityDivisor = NaN;       % Raw image value corresponding to intensity 1.
cfg.calibrationScaleFactor = NaN; % Multiplier placing calibration on the measurement intensity scale.

% Use the cropped, unresized image coordinates for the source and distances.
cfg.geometry.sourceCoordinates = [NaN NaN]; % [horizontal vertical].
cfg.geometry.refractiveIndices = [NaN NaN NaN]; % [air wall fluid].
cfg.geometry.wallThickness = NaN;
cfg.geometry.unseenFluidDepth = NaN;
cfg.geometry.fanHalfAngleDegrees = NaN;

% Supply the known dimensionless calibration field on the resized image grid.
% A function handle is also accepted: field = cfg.calibrationField([rows cols]).
% Values must lie between 0 and 1, as in the reconstruction.
cfg.calibrationField = [];
cfg.attenuationFitRows = [];      % Inclusive [first last] rows of the resized image.
cfg.kappa0 = NaN;                 % Background attenuation per resized image row.
cfg.kappa1 = [];                  % [] fits the calibration; a scalar supplies it.

% The test driver requires 'calibration', or an incident intensity for each ray.
% A scalar assigns the same intensity to all rays. Validation always uses
% the calibration estimate for both the inverse and forward calculations.
cfg.forwardIncidentIntensity = [];

cfg.signalThresholdFraction = 0.05;
cfg.figureResolution = 300;
cfg.overwrite = false;
end
