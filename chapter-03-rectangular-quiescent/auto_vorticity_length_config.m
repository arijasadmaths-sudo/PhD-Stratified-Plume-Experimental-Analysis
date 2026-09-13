function cfg = auto_vorticity_length_config()
%AUTO_VORTICITY_LENGTH_CONFIG Settings for image-edge measurements.
%   Fill the empty required fields using the image sequence being analysed.
%   Pixel positions are one-based. Lengths are measured within the crop.

cfg.inputFolder = '';                 % Folder containing the source images
cfg.outputFolder = '';                % A separate folder for the results
cfg.imagePattern = '*.png';
cfg.imageOrder = [];                   % []: natural filename order
% A custom order is a permutation of the lexically sorted filenames.
cfg.framePositions = [];               % []: analyse the complete ordered sequence
cfg.cropRect = [];                     % Required [x y width height], in pixels
cfg.bandRows = [];                     % Required [first last] rows within the crop
cfg.referenceWidthPx = [];             % Required scale for normalised lengths

% Supply times for every ordered image, before selecting frames.
% The plotted coordinate is (timeValues - timeOrigin)/timeScale.
% Use consistent time units. Frame positions may also be used explicitly.
cfg.timeValues = [];
cfg.timeOrigin = [];
cfg.timeScale = [];

cfg.detector.smoothWindow = [];        % Required odd smoothing window, in pixels
cfg.detector.selectionMode = 'outermost'; % 'outermost' or 'best-pair'
cfg.detector.centreX = [];             % []: midpoint of the crop
cfg.detector.minWidthPx = [];          % Required minimum edge separation
cfg.detector.maxWidthPx = [];          % []: full width of the crop
cfg.detector.centreGapPx = [];         % Required gap excluded about the centre
cfg.detector.polarity = 'either';      % 'bright', 'dark' or 'either'
cfg.detector.minContrast = [];         % Required fraction of the intensity scale
cfg.detector.noiseMultiplier = 4;
cfg.detector.minPairRatio = 1.15;       % Minimum score ratio in 'best-pair' mode
cfg.detector.maxCandidatesPerSide = 10; % Candidate limit in 'best-pair' mode

cfg.showDiagnostics = true;
cfg.saveDiagnostics = true;
cfg.reviewEachFrame = true;            % Confirm, replace or skip each measurement
cfg.enablePlotEditor = true;           % Remove points/curves, undo and export
% Closing the review dialog saves the measurements already confirmed.
% Plot edits change only the displayed comparison; curves are not refitted.

cfg.powerMode = 'fit';                 % 'fit' or 'prescribed'
cfg.earlyFitPositions = [];            % Positions in the selected sequence; []: no fit
cfg.powerFitPositions = [];            % Positions in the selected sequence; []: all

% A prescribed curve has the form L = amplitude*t^exponent, using the same
% normalised coordinates as the measured lengths and times.
cfg.model.kind = 'coefficients';       % 'coefficients' or 'physical'
cfg.model.amplitude = [];              % Required only for a prescribed curve
cfg.model.exponent = [];               % Required for prescribed 'coefficients'

% The 'physical' option retains the expression used in the thesis script:
% Atwood = (rhoHigh-rhoLow)/(rhoHigh+rhoLow)
% exponent = -(g*Atwood^2/(area^2*pi^2)) / ...
%              (g*height*densityDifference/rhoHigh)^(3/2).
% Supply the same dimensional convention used to derive the chosen curve.
% densityDifference is independent of the density pair in this expression.
cfg.model.rhoHigh = [];
cfg.model.rhoLow = [];
cfg.model.area = [];
cfg.model.gravity = [];
cfg.model.height = [];
cfg.model.densityDifference = [];
end
