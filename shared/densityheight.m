function results = densityheight(config)
%DENSITYHEIGHT Read image sequences and compare their vertical profiles.
%   RESULTS = DENSITYHEIGHT(CONFIG) uses the same reference subtraction and
%   intensity normalisation as the thesis analysis script. The output is a
%   normalised intensity profile, not a calibrated density in kg m^-3.
%
%   Required fields:
%     imageFolder       Folder containing the images.
%     referenceFrame    Index of the reference image in the retained sequence.
%     timeSeconds       Time of each retained image, in seconds. Alternatively,
%                       supply frameIntervalSeconds for equally spaced images.
%
%   Optional fields:
%     imageFiles        Cell array of filenames in the required time order.
%                       Otherwise, imagePattern matches files, sorted by name.
%     imagePattern      Pattern used to find images; default '*.png'.
%     cropRows          Rows retained from each image; default all rows.
%     cropColumns       Columns retained from each image; default all columns.
%     averagingColumns  Columns of the cropped image to average; default all.
%     rowCoordinates_m  Distance below the ceiling of each retained row, in
%                       metres, in image order. If omitted, coordinates run
%                       from 0 at the top to 1 at the bottom.
%     gradientDiagnostic  Return positions beside the largest adjacent profile difference.
%                       Default false. This is a diagnostic, not a threshold
%                       measurement of the stratified layer.
%     legacyDiagnostic  Return the time-ordered profile-value signal; default
%                       false. This signal is dimensionless, not a height.
%     fitTarget         'none' (default), 'gradient_position', or
%                       'legacy_profile_signal'. The corresponding diagnostic
%                       must be enabled. Fits use time in seconds.
%     compareModels     Also fit linear, quadratic and b*(1+exp(-a*t)) models
%                       to the chosen signal; default false.
%     makePlots         Display profile and selected diagnostic plots; true.
%     inspectionFrames  Frames for raw horizontal/vertical profiles; default [].
%     inspectionRows    Rows of cropped images for inspection; default all.
%     inspectionColumns Columns of cropped images for inspection; default all.
%     outputFolder      Optional destination for results.mat, profiles.csv,
%                       diagnostics.csv and JPEG figures. Existing files at
%                       these paths are replaced.

    if nargin ~= 1 || ~isstruct(config) || ~isscalar(config)
        error('densityheight:Configuration', 'Supply one configuration structure.');
    end
    require_field(config, 'imageFolder');
    require_field(config, 'referenceFrame');
    config = defaults(config);
    check_flag(config.gradientDiagnostic, 'gradientDiagnostic');
    check_flag(config.legacyDiagnostic, 'legacyDiagnostic');
    check_flag(config.compareModels, 'compareModels');
    check_flag(config.makePlots, 'makePlots');
    if strcmp(config.fitTarget, 'legacy_sorted_signal')
        error('densityheight:RemovedSortedSignal', ...
            ['legacy_sorted_signal has been removed: sorting values breaks ' ...
             'their timestamp association. Use legacy_profile_signal for the ' ...
             'time-ordered dimensionless diagnostic; it is not a layer height.']);
    end
    fitTarget = validatestring(config.fitTarget, ...
        {'none', 'gradient_position', 'legacy_profile_signal'});

    [imageFiles, imagePaths] = find_images(config);
    frameCount = numel(imagePaths);
    timeSeconds = frame_times(config, frameCount);
    referenceFrame = config.referenceFrame;
    validateattributes(referenceFrame, {'numeric'}, ...
        {'scalar', 'integer', '>=', 1, '<=', frameCount}, mfilename, 'referenceFrame');

    firstImage = read_image(imagePaths{1});
    imageSize = size(firstImage);
    cropRows = selected_indices(config.cropRows, imageSize(1), 'cropRows');
    cropColumns = selected_indices(config.cropColumns, imageSize(2), 'cropColumns');
    averagingColumns = selected_indices(config.averagingColumns, ...
        numel(cropColumns), 'averagingColumns');
    if numel(cropRows) < 2
        error('densityheight:Rows', 'Retain at least two image rows.');
    end
    [rowCoordinates, coordinateLabel, coordinateUnits] = ...
        coordinates(config, cropRows);
    rawProfiles = zeros(numel(cropRows), frameCount);
    for frame = 1:frameCount
        if frame == 1
            imageData = firstImage;
        else
            imageData = read_image(imagePaths{frame});
        end
        if ~isequal(size(imageData), imageSize)
            error('densityheight:ImageSize', 'Image dimensions differ: %s', imageFiles{frame});
        end
        imageData = imageData(cropRows, cropColumns);
        rawProfiles(:, frame) = mean(imageData(:, averagingColumns), 2);
    end

    % Subtract the reference before applying the original intensity scaling.
    referenceProfile = rawProfiles(:, referenceFrame);
    invertedProfiles = 1 - bsxfun(@minus, rawProfiles, referenceProfile);
    minimumValue = min(invertedProfiles(:));
    normalisationScale = 1 - minimumValue;
    if normalisationScale <= 0 || ~isfinite(normalisationScale)
        error('densityheight:Normalisation', ...
            ['The chosen reference gives no positive intensity difference. ' ...
             'The original normalisation would divide by zero. Check the reference and crop.']);
    end
    normalisedProfiles = (invertedProfiles - minimumValue) / normalisationScale;

    results.config = config;
    results.imageFiles = imageFiles;
    results.timeSeconds = timeSeconds;
    results.cropRows = cropRows;
    results.cropColumns = cropColumns;
    results.averagingColumns = averagingColumns;
    results.rowCoordinates = rowCoordinates;
    results.coordinateUnits = coordinateUnits;
    results.rawProfiles = rawProfiles;
    results.referenceProfile = referenceProfile;
    results.normalisationMinimum = minimumValue;
    results.normalisationScale = normalisationScale;
    results.normalisedProfiles = normalisedProfiles;
    results.gradient = [];
    results.legacy = [];
    results.powerFit = [];
    results.modelComparison = [];

    if config.gradientDiagnostic || config.legacyDiagnostic
        [selectedRows, profileValues, pairStartRows, gradientMagnitude] = ...
            gradient_samples(normalisedProfiles);
        if config.gradientDiagnostic
            results.gradient.pairStartRows = pairStartRows;
            results.gradient.selectedRows = selectedRows;
            results.gradient.profileValues = profileValues;
            results.gradient.positions = reshape(rowCoordinates(selectedRows), 1, []);
            results.gradient.maxAdjacentDifference = gradientMagnitude;
            % A flat profile has no gradient position, including the reference.
            results.gradient.positions(gradientMagnitude == 0) = NaN;
        end
        if config.legacyDiagnostic
            % Keep each profile value paired with its original frame and time.
            % This remains a dimensionless signal, not a spatial height.
            results.legacy.profileValues = profileValues;
            results.legacy.timeOrderedSignal = 1 - profileValues;
        end
    end

    [fitValues, fitLabel] = fitting_signal(results, fitTarget);
    if ~isempty(fitValues)
        results.powerFit = power_fit(timeSeconds, fitValues);
        if config.compareModels
            results.modelComparison = compare_models(timeSeconds, fitValues);
        end
    elseif config.compareModels
        error('densityheight:FitTarget', 'Choose a fitTarget before setting compareModels to true.');
    end

    figures = gobjects(0);
    figureNames = {};
    if config.makePlots
        figures(end+1) = figure;
        plot(normalisedProfiles, rowCoordinates);
        set(gca, 'YDir', 'reverse');
        xlabel('Normalised profile'); ylabel(coordinateLabel);
        title('Vertical profiles');
        figureNames{end+1} = 'vertical_profiles';
        if config.gradientDiagnostic
            figures(end+1) = figure;
            plot(timeSeconds, results.gradient.positions, 'o-');
            set(gca, 'YDir', 'reverse');
            xlabel('Time (s)'); ylabel(coordinateLabel);
            title('Position beside the largest adjacent profile difference');
            figureNames{end+1} = 'gradient_position';
        end
        if config.legacyDiagnostic
            figures(end+1) = figure;
            plot(timeSeconds, results.legacy.timeOrderedSignal, 'o-');
            xlabel('Time (s)'); ylabel('Time-ordered profile-value signal');
            title('Legacy dimensionless diagnostic');
            figureNames{end+1} = 'legacy_profile_signal';
        end
        if ~isempty(results.powerFit)
            figures(end+1) = plot_power_fit(timeSeconds, fitValues, ...
                results.powerFit, fitLabel, strcmp(fitTarget, 'gradient_position'));
            figureNames{end+1} = 'power_fit';
        end
        if ~isempty(results.modelComparison)
            [comparisonFigure, residualFigure] = plot_comparison(timeSeconds, ...
                fitValues, results.modelComparison, fitLabel, ...
                strcmp(fitTarget, 'gradient_position'));
            figures(end+1:end+2) = [comparisonFigure, residualFigure];
            figureNames(end+1:end+2) = {'model_comparison', 'model_residuals'};
        end
    end

    % Inspect raw image sections without assembling copies of the whole sequence.
    inspectionFrames = optional_indices(config.inspectionFrames, frameCount, 'inspectionFrames');
    inspectionRows = selected_indices(config.inspectionRows, numel(cropRows), 'inspectionRows');
    inspectionColumns = selected_indices(config.inspectionColumns, numel(cropColumns), 'inspectionColumns');
    results.inspection = struct('frame', {}, 'rows', {}, 'columns', {}, ...
        'horizontalProfiles', {}, 'verticalProfiles', {});
    for index = 1:numel(inspectionFrames)
        frame = inspectionFrames(index);
        imageData = read_image(imagePaths{frame});
        imageData = imageData(cropRows, cropColumns);
        results.inspection(index).frame = frame;
        results.inspection(index).rows = inspectionRows;
        results.inspection(index).columns = inspectionColumns;
        results.inspection(index).horizontalProfiles = imageData(inspectionRows, :);
        results.inspection(index).verticalProfiles = imageData(:, inspectionColumns);
        if config.makePlots
            figures(end+1) = figure;
            plot(cropColumns, imageData(inspectionRows, :).');
            xlabel('Image column'); ylabel('Image intensity');
            title(sprintf('Horizontal sections: frame %d', frame));
            figureNames{end+1} = sprintf('horizontal_sections_%d', frame);
            figures(end+1) = figure;
            plot(imageData(:, inspectionColumns), rowCoordinates);
            set(gca, 'YDir', 'reverse');
            xlabel('Image intensity'); ylabel(coordinateLabel);
            title(sprintf('Vertical sections: frame %d', frame));
            figureNames{end+1} = sprintf('vertical_sections_%d', frame);
        end
    end

    if ~isempty(config.outputFolder)
        save_results(results, config.outputFolder, figures, figureNames);
    end
end

function config = defaults(config)
    values = struct('imageFiles', {{}}, 'imagePattern', '*.png', ...
        'timeSeconds', [], 'frameIntervalSeconds', [], 'cropRows', [], ...
        'cropColumns', [], 'averagingColumns', [], 'rowCoordinates_m', [], ...
        'gradientDiagnostic', false, 'legacyDiagnostic', false, ...
        'fitTarget', 'none', 'compareModels', false, 'makePlots', true, ...
        'inspectionFrames', [], 'inspectionRows', [], 'inspectionColumns', [], ...
        'outputFolder', '');
    names = fieldnames(values);
    for index = 1:numel(names)
        if ~isfield(config, names{index})
            config.(names{index}) = values.(names{index});
        end
    end
end

function require_field(config, name)
    if ~isfield(config, name) || isempty(config.(name))
        error('densityheight:RequiredField', 'Set config.%s.', name);
    end
end

function check_flag(value, name)
    validateattributes(value, {'logical', 'numeric'}, {'scalar', 'real', 'finite'}, mfilename, name);
    if value ~= 0 && value ~= 1
        error('densityheight:Flag', '%s must be true or false.', name);
    end
end

function [names, paths] = find_images(config)
    if ~isfolder(config.imageFolder)
        error('densityheight:ImageFolder', 'Image folder does not exist: %s', config.imageFolder);
    end
    if isempty(config.imageFiles)
        files = dir(fullfile(config.imageFolder, config.imagePattern));
        files = files(~[files.isdir]);
        names = sort({files.name});
    else
        names = cellstr(config.imageFiles);
        names = reshape(names, 1, []);
    end
    if isempty(names)
        error('densityheight:NoImages', 'No images were found.');
    end
    paths = cellfun(@(name) fullfile(config.imageFolder, name), names, 'UniformOutput', false);
    for index = 1:numel(paths)
        if ~isfile(paths{index})
            error('densityheight:MissingImage', 'Image does not exist: %s', paths{index});
        end
    end
end

function imageData = read_image(path)
    [imageData, colourMap] = imread(path);
    if ~isempty(colourMap)
        error('densityheight:IndexedImage', 'Convert indexed images to greyscale or RGB first: %s', path);
    end
    imageData = im2double(im2gray(imageData));
    if any(~isfinite(imageData(:)))
        error('densityheight:ImageValues', 'Image contains non-finite values: %s', path);
    end
end

function indices = selected_indices(indices, count, name)
    if isempty(indices)
        indices = 1:count;
    end
    validateattributes(indices, {'numeric'}, ...
        {'vector', 'integer', '>=', 1, '<=', count}, mfilename, name);
    indices = reshape(indices, 1, []);
    if any(diff(indices) <= 0)
        error('densityheight:Indices', '%s must be strictly increasing.', name);
    end
end

function indices = optional_indices(indices, count, name)
    if ~isempty(indices)
        indices = selected_indices(indices, count, name);
    end
end

function time = frame_times(config, frameCount)
    if ~isempty(config.timeSeconds) && ~isempty(config.frameIntervalSeconds)
        error('densityheight:Time', 'Supply timeSeconds or frameIntervalSeconds, not both.');
    end
    if ~isempty(config.timeSeconds)
        validateattributes(config.timeSeconds, {'numeric'}, ...
            {'vector', 'real', 'finite', 'numel', frameCount}, mfilename, 'timeSeconds');
        time = reshape(config.timeSeconds, 1, []);
        if any(diff(time) <= 0)
            error('densityheight:Time', 'timeSeconds must be strictly increasing.');
        end
    else
        validateattributes(config.frameIntervalSeconds, {'numeric'}, ...
            {'scalar', 'real', 'finite', 'positive'}, mfilename, 'frameIntervalSeconds');
        time = (0:frameCount-1) * config.frameIntervalSeconds;
    end
end

function [height, label, units] = coordinates(config, rows)
    rowCount = numel(rows);
    if isempty(config.rowCoordinates_m)
        height = (rows(:)-rows(1)) / (rows(end)-rows(1));
        label = 'Normalised distance from ceiling';
        units = 'dimensionless';
    else
        validateattributes(config.rowCoordinates_m, {'numeric'}, ...
            {'vector', 'real', 'finite', 'numel', rowCount}, mfilename, 'rowCoordinates_m');
        height = config.rowCoordinates_m(:);
        if ~all(diff(height) > 0) || any(height < 0)
            error('densityheight:Coordinates', ...
                'rowCoordinates_m must be nonnegative distances increasing from the ceiling.');
        end
        label = 'Distance from ceiling (m)';
        units = 'm';
    end
end

function [selectedRows, values, pairStartRows, magnitudes] = gradient_samples(profiles)
    frameCount = size(profiles, 2);
    selectedRows = zeros(1, frameCount);
    values = zeros(1, frameCount);
    pairStartRows = zeros(1, frameCount);
    magnitudes = zeros(1, frameCount);
    for frame = 1:frameCount
        profile = profiles(:, frame);
        [magnitudes(frame), row] = max(abs(diff(profile)));
        % Keep the original choice between the two rows beside the gradient.
        if row == 1 || (row < numel(profile)-1 && ...
                abs(profile(row+1)-profile(row+2)) < abs(profile(row)-profile(row-1)))
            selectedRow = row;
        else
            selectedRow = row + 1;
        end
        pairStartRows(frame) = row;
        selectedRows(frame) = selectedRow;
        values(frame) = profile(selectedRow);
    end
end

function [values, label] = fitting_signal(results, target)
    values = [];
    label = '';
    switch target
        case 'gradient_position'
            if isempty(results.gradient)
                error('densityheight:FitTarget', 'Enable gradientDiagnostic to fit gradient positions.');
            end
            values = results.gradient.positions;
            if strcmp(results.coordinateUnits, 'm')
                label = 'Gradient position (m)';
            else
                label = 'Normalised gradient position';
            end
        case 'legacy_profile_signal'
            if isempty(results.legacy)
                error('densityheight:FitTarget', 'Enable legacyDiagnostic to fit its time-ordered signal.');
            end
            values = results.legacy.timeOrderedSignal;
            label = 'Time-ordered profile-value signal';
    end
end

function result = power_fit(time, values)
    % The power fit uses positive values and least squares in logarithmic space.
    valid = isfinite(time) & isfinite(values) & time > 0 & values > 0;
    if nnz(valid) < 2
        error('densityheight:PowerFit', 'A power fit needs at least two positive time/value pairs.');
    end
    coefficients = polyfit(log(time(valid)), log(values(valid)), 1);
    result.a = exp(coefficients(2));
    result.b = coefficients(1);
    result.validFrames = find(valid);
    result.fittedValues = result.a * time(valid).^result.b;
    result.R2 = compute_r2(values(valid), result.fittedValues);
    fprintf('Power fit: y = %.6g t^{%.6g}, R^2 = %.6g (time in seconds)\n', ...
        result.a, result.b, result.R2);
end

function result = compare_models(time, values)
    time = time(:);
    values = values(:);
    valid = isfinite(time) & isfinite(values);
    result.validFrames = find(valid);
    if nnz(valid) < 3
        error('densityheight:ModelComparison', 'Model comparison needs at least three finite samples.');
    end
    result.linear.coefficients = polyfit(time(valid), values(valid), 1);
    result.linear.fittedValues = polyval(result.linear.coefficients, time);
    result.quadratic.coefficients = polyfit(time(valid), values(valid), 2);
    result.quadratic.fittedValues = polyval(result.quadratic.coefficients, time);
    model = @(parameters, t) parameters(2) * (1 + exp(-parameters(1)*t));
    objective = @(parameters) sum((model(parameters, time(valid))-values(valid)).^2);
    [parameters, ~, exitFlag] = fminsearch(objective, [1, mean(values(valid))], ...
        optimset('Display', 'off'));
    result.exponential.parameters = parameters;
    result.exponential.fittedValues = model(parameters, time);
    result.exponential.exitFlag = exitFlag;
    names = {'linear', 'quadratic', 'exponential'};
    scores = nan(1, numel(names));
    for index = 1:numel(names)
        name = names{index};
        result.(name).residuals = values - result.(name).fittedValues;
        result.(name).R2 = compute_r2(values(valid), result.(name).fittedValues(valid));
        scores(index) = result.(name).R2;
        fprintf('%s: R^2 = %.6g\n', name, scores(index));
    end
    if exitFlag <= 0
        warning('densityheight:ExponentialFit', 'The exponential fit did not converge.');
    end
    finiteScores = isfinite(scores);
    result.bestByR2 = '';
    if any(finiteScores)
        scores(~finiteScores) = -Inf;
        [~, index] = max(scores);
        result.bestByR2 = names{index};
    end
end

function value = compute_r2(observed, fitted)
    total = sum((observed-mean(observed)).^2);
    if total == 0 || any(~isfinite(fitted))
        value = NaN;
    else
        value = 1 - sum((observed-fitted).^2)/total;
    end
end

function handle = plot_power_fit(time, values, result, label, fromCeiling)
    handle = figure;
    frames = result.validFrames;
    scatter(time(frames), values(frames), 'bo'); hold on;
    fitLine = plot(time(frames), result.fittedValues, 'r-', 'LineWidth', 2);
    xlabel('Time (s)'); ylabel(label);
    if fromCeiling
        set(gca, 'YDir', 'reverse');
    end
    titleHandle = title(sprintf('Power fit: y = %.4g t^{%.4g}', result.a, result.b));
    fitLegend = legend('Data', sprintf('Fit (R^2 = %.3f)', result.R2), 'Location', 'best');
    grid on;
    axesHandle = gca;
    set(axesHandle, 'Position', [0.13 0.23 0.775 0.68]);
    lambdaLabel = uicontrol(handle, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.12 0.04 0.27 0.06], 'String', sprintf('lambda = %.4g', result.a));
    uicontrol(handle, 'Style', 'slider', 'Units', 'normalized', ...
        'Position', [0.40 0.045 0.48 0.05], 'Min', 0, 'Max', 2*result.a, ...
        'Value', result.a, 'Callback', @set_lambda);

    function set_lambda(source, ~)
        lambda = get(source, 'Value');
        fitted = lambda * time(frames).^result.b;
        set(fitLine, 'YData', fitted);
        set(lambdaLabel, 'String', sprintf('lambda = %.4g', lambda));
        set(titleHandle, 'String', sprintf('Power fit: y = %.4g t^{%.4g}', lambda, result.b));
        set(fitLegend, 'String', {'Data', ...
            sprintf('Fit (R^2 = %.3f)', compute_r2(values(frames), fitted))});
    end
end

function [fitFigure, residualFigure] = plot_comparison(time, values, result, label, fromCeiling)
    fitFigure = figure;
    plot(time, values, 'ko', 'MarkerFaceColor', 'k'); hold on;
    plot(time, result.linear.fittedValues, 'b-', 'LineWidth', 2);
    plot(time, result.quadratic.fittedValues, 'r--', 'LineWidth', 2);
    plot(time, result.exponential.fittedValues, 'm-.', 'LineWidth', 2);
    if fromCeiling
        set(gca, 'YDir', 'reverse');
    end
    xlabel('Time (s)'); ylabel(label); title('Model comparison');
    legend('Data', sprintf('Linear (R^2 = %.3f)', result.linear.R2), ...
        sprintf('Quadratic (R^2 = %.3f)', result.quadratic.R2), ...
        sprintf('Exponential (R^2 = %.3f)', result.exponential.R2), 'Location', 'best');
    grid on;
    residualFigure = figure;
    plot(time, result.linear.residuals, 'b-o', ...
        time, result.quadratic.residuals, 'r--s', ...
        time, result.exponential.residuals, 'm-.^', 'LineWidth', 1.5);
    xlabel('Time (s)'); ylabel('Data - fit'); title('Model residuals');
    legend('Linear', 'Quadratic', 'Exponential', 'Location', 'best'); grid on;
end

function save_results(results, folder, figures, figureNames)
    if ~isfolder(folder)
        mkdir(folder);
    end
    save(fullfile(folder, 'results.mat'), 'results');
    [rowIndex, frameIndex] = ndgrid(1:numel(results.rowCoordinates), ...
        1:numel(results.timeSeconds));
    times = results.timeSeconds(frameIndex(:));
    heights = results.rowCoordinates(rowIndex(:));
    profiles = table(frameIndex(:), rowIndex(:), times(:), heights(:), ...
        results.rawProfiles(:), results.normalisedProfiles(:), ...
        'VariableNames', {'Frame', 'Row', 'Time_s', 'RowCoordinate', ...
        'MeanImageIntensity', 'NormalisedProfile'});
    writetable(profiles, fullfile(folder, 'profiles.csv'));
    diagnostics = table((1:numel(results.timeSeconds)).', results.timeSeconds(:), ...
        'VariableNames', {'Frame', 'Time_s'});
    if ~isempty(results.gradient)
        diagnostics.GradientPosition = results.gradient.positions(:);
        diagnostics.SelectedRow = results.gradient.selectedRows(:);
        diagnostics.ProfileValueAtSelectedRow = results.gradient.profileValues(:);
        diagnostics.MaxAdjacentDifference = results.gradient.maxAdjacentDifference(:);
    end
    if ~isempty(results.legacy)
        diagnostics.LegacyTimeOrderedSignal = results.legacy.timeOrderedSignal(:);
    end
    writetable(diagnostics, fullfile(folder, 'diagnostics.csv'));
    for index = 1:numel(figures)
        saveas(figures(index), fullfile(folder, [figureNames{index}, '.jpg']));
    end
end
