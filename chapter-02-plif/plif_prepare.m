function [cali, imageFiles, outputNames] = plif_prepare(cfg, suffix)
% Check the file selection before processing any images.
required = {'inputFolder','outputFolder','calibrationFile','imageFiles', ...
    'cropRect','resizeScale','intensityDivisor','calibrationScaleFactor', ...
    'geometry','calibrationField','attenuationFitRows','kappa0','kappa1', ...
    'forwardIncidentIntensity','signalThresholdFraction','figureResolution','overwrite'};
for i = 1:numel(required)
    if ~isfield(cfg,required{i})
        error('PLIF:Settings', 'Missing setting: %s. Start with plif_settings().',required{i});
    end
end
if isempty(cfg.inputFolder) || isempty(cfg.outputFolder) || isempty(cfg.calibrationFile)
    error('PLIF:Paths', 'Set inputFolder, outputFolder and calibrationFile.');
end
if ~isfolder(cfg.inputFolder)
    error('PLIF:InputFolder', 'Input folder does not exist: %s',cfg.inputFolder);
end
if isempty(cfg.imageFiles)
    error('PLIF:ImageFiles', 'List the images to process in cfg.imageFiles.');
end
imageFiles = cellstr(string(cfg.imageFiles));
imageFiles = imageFiles(:);
if numel(unique(imageFiles)) ~= numel(imageFiles)
    error('PLIF:ImageFiles', 'The image list contains duplicate filenames.');
end
if any(strcmpi(imageFiles,cfg.calibrationFile))
    error('PLIF:ImageFiles', 'The calibration must not also appear in cfg.imageFiles.');
end
validateattributes(cfg.overwrite, {'logical'}, {'scalar'});
validateattributes(cfg.signalThresholdFraction, {'numeric'}, {'scalar','finite','>=',0,'<=',1});
validateattributes(cfg.figureResolution, {'numeric'}, {'scalar','finite','positive'});
if ~isempty(cfg.cropRect)
    validateattributes(cfg.cropRect, {'numeric'}, {'real','finite','integer','numel',4,'positive'});
end
outputNames = cell(size(imageFiles));
for i = 1:numel(imageFiles)
    if ~isfile(fullfile(cfg.inputFolder,imageFiles{i}))
        error('PLIF:MissingImage', 'Image not found: %s',imageFiles{i});
    end
    [~,baseName] = fileparts(imageFiles{i});
    baseName = regexprep(baseName,'[^A-Za-z0-9_-]+','_');
    baseName = regexprep(baseName,'_+','_');
    baseName = regexprep(baseName,'^_|_$','');
    if isempty(baseName)
        baseName = 'frame';
    end
    outputNames{i} = [baseName suffix];
end
if numel(unique(lower(string(outputNames)))) ~= numel(outputNames)
    error('PLIF:OutputNames', 'Two input names would produce the same output filename.');
end
for i = 1:numel(outputNames)
    for extension = {'.mat','.png'}
        filename = fullfile(cfg.outputFolder,[outputNames{i} extension{1}]);
        if ~cfg.overwrite && isfile(filename)
            error('PLIF:ExistingOutput', 'Output already exists: %s',filename);
        end
    end
end
cali = plif_read_image(fullfile(cfg.inputFolder,cfg.calibrationFile),cfg.cropRect);
if ~isfolder(cfg.outputFolder)
    mkdir(cfg.outputFolder);
end
end
