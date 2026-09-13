function [results, fits] = auto_vorticity_length(cfg)
%AUTO_VORTICITY_LENGTH Measure the separation of two image-profile edges.
%   [results, fits] = auto_vorticity_length(cfg)
%   Complete auto_vorticity_length_config before running this function.
%   The filename is retained from the thesis code. This measures image-edge
%   separation as a proxy for ring diameter; it does not calculate vorticity.
%   Check the saved overlays before interpreting the measured lengths.
%   Plot edits do not change the measurements or refit the curves.

if nargin ~= 1
    error('Supply a configuration from auto_vorticity_length_config.');
end
validateConfiguration(cfg);
inputFolder = char(cfg.inputFolder);
imagePattern = char(cfg.imagePattern);
outputFolder = char(cfg.outputFolder);
framePositions = cfg.framePositions;
cropRect = cfg.cropRect;
bandRows = cfg.bandRows;
referenceWidthPx = cfg.referenceWidthPx;
det = cfg.detector;
showDiagnostics = cfg.showDiagnostics;
saveDiagnostics = cfg.saveDiagnostics;
reviewEachFrame = cfg.reviewEachFrame;
enablePlotEditor = cfg.enablePlotEditor;
powerMode = cfg.powerMode;
earlyFitPositions = cfg.earlyFitPositions;
powerFitPositions = cfg.powerFitPositions;
[modelA, modelB] = prescribedModel(cfg);
fits = struct();

% Read and order filenames.
imagesPNG = dir(fullfile(inputFolder, imagePattern));
imagesPNG = imagesPNG(~[imagesPNG.isdir]);
N = numel(imagesPNG);
if N == 0
    error('No matching images found in %s.', inputFolder);
end
% A supplied permutation refers to lexically sorted filenames.
[~, lexicalOrder] = sort({imagesPNG.name});
imagesPNG = imagesPNG(lexicalOrder);
if isempty(cfg.imageOrder)
    imageOrder = naturalFileOrder({imagesPNG.name});
else
    imageOrder = cfg.imageOrder(:)';
    if numel(imageOrder) ~= N || ~isequal(sort(imageOrder), 1:N)
        error('imageOrder must contain each ordered file index once.');
    end
end
orderedImages = imagesPNG(imageOrder);
if isempty(framePositions)
    framePositions = (1:N)';
else
    framePositions = framePositions(:);
    validatePositions(framePositions, N, 'framePositions');
end
selectedImages = orderedImages(framePositions);
nFrames = numel(selectedImages);
fileNames = {selectedImages.name}';

% Times refer to the ordered sequence before frame selection.
if numel(cfg.timeValues) ~= N || any(diff(cfg.timeValues(:)) <= 0)
    error('timeValues must give one strictly increasing time per ordered image.');
end
tAll = (cfg.timeValues(framePositions)-cfg.timeOrigin)/cfg.timeScale;
tAll = tAll(:);
validatePositions(earlyFitPositions, nFrames, 'earlyFitPositions');
validatePositions(powerFitPositions, nFrames, 'powerFitPositions');
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Measure the image edges.
edgeLengths = nan(nFrames, 1);
leftEdges = nan(nFrames, 1);
rightEdges = nan(nFrames, 1);
candidateLeft = nan(nFrames, 1);
candidateRight = nan(nFrames, 1);
pairRatio = nan(nFrames, 1);
status = repmat({'not processed'}, nFrames, 1);
automaticStatus = repmat({'not processed'}, nFrames, 1);
measurementMethod = repmat({'none'}, nFrames, 1);
diagnosticFigure = [];
if showDiagnostics || saveDiagnostics || reviewEachFrame
    visibility = 'off';
    if showDiagnostics || reviewEachFrame, visibility = 'on'; end
    diagnosticFigure = figure('Name', 'Edge detection and review', ...
        'NumberTitle', 'off', 'Visible', visibility, 'Color', 'w', ...
        'Position', [100 100 1000 650]);
end

for j = 1:nFrames
    fullName = fullfile(inputFolder, selectedImages(j).name);
    grayImage = readGrayImage(fullName);
    [imageHeight, imageWidth] = size(grayImage);
    x1 = cropRect(1); y1 = cropRect(2);
    x2 = x1 + cropRect(3) - 1;
    y2 = y1 + cropRect(4) - 1;
    if x2 > imageWidth || y2 > imageHeight
        error('Crop lies outside %s. Adjust cropRect.', selectedImages(j).name);
    end
    cropped = grayImage(y1:y2, x1:x2);
    row1 = bandRows(1);
    row2 = bandRows(2);
    if row2 > size(cropped, 1)
        error('Invalid bandRows for %s.', selectedImages(j).name);
    end
    profile = mean(cropped(row1:row2, :), 1);
    [measurement, smoothProfile] = detectEdgePair(profile, det);
    measurement.method = 'automatic';
    % Retain the automatic proposal even if the final measurement is manual.
    candidateLeft(j) = measurement.left;
    candidateRight(j) = measurement.right;
    pairRatio(j) = measurement.pairRatio;
    automaticStatus{j} = measurement.status;
    stopRequested = false;
    if reviewEachFrame
        [measurement, diagnosticFigure, stopRequested] = reviewFrame( ...
            diagnosticFigure, cropped, smoothProfile, [row1 row2], ...
            measurement, selectedImages(j).name, framePositions(j));
    end
    % Commit only the reviewed result. Unconfirmed proposals are never fitted.
    status{j} = measurement.status;
    if measurement.accepted
        leftEdges(j) = measurement.left;
        rightEdges(j) = measurement.right;
        edgeLengths(j) = rightEdges(j) - leftEdges(j);
        measurementMethod{j} = measurement.method;
    end
    fprintf('%2d/%2d  %-35s  L = %7.1f px  %s\n', ...
        j, nFrames, selectedImages(j).name, edgeLengths(j), status{j});

    if showDiagnostics || saveDiagnostics || reviewEachFrame
        diagnosticFigure = drawFrameDiagnostic(diagnosticFigure, cropped, ...
            smoothProfile, [row1 row2], measurement, ...
            selectedImages(j).name, framePositions(j), visibility);
        if saveDiagnostics
            print(diagnosticFigure, fullfile(outputFolder, ...
                sprintf('edges_%04d.png', framePositions(j))), '-dpng', '-r130');
        end
    end
    if stopRequested
        fprintf('Review stopped. Saving the confirmed measurements.\n');
        break;
    end
end
if ~showDiagnostics && ~isempty(diagnosticFigure) && ishandle(diagnosticFigure)
    close(diagnosticFigure);
end

% Save rejected frames at their original times.
LAll = edgeLengths/referenceWidthPx;
results = table(framePositions, fileNames, tAll, leftEdges, rightEdges, ...
    edgeLengths, LAll, candidateLeft, candidateRight, pairRatio, status, ...
    measurementMethod, automaticStatus, ...
    'VariableNames', {'OrderedFrame','FileName','NormalizedTime', ...
    'LeftEdgeCropPx','RightEdgeCropPx','LengthPx','NormalizedLength', ...
    'CandidateLeftCropPx','CandidateRightCropPx','PairRatio','Status', ...
    'MeasurementMethod','AutomaticStatus'});
writetable(results, fullfile(outputFolder, 'edge_lengths.csv'));
settings = cfg;
settings.imageOrder = imageOrder;
settings.framePositions = framePositions;
settings.modelA = modelA;
settings.modelB = modelB;
save(fullfile(outputFolder, 'edge_lengths.mat'), ...
    'edgeLengths', 'results', 'settings');

figure('Color', 'w');
plot(framePositions, edgeLengths, 'b-o', 'LineWidth', 2);
xlabel('Frame (ordered)');
ylabel('Image-edge separation (pixels)');
title('Image-edge separations');
grid on;
print(gcf, fullfile(outputFolder, 'edge_lengths.png'), '-dpng', '-r180');

% Compare the measured lengths with the selected curves.
valid = isfinite(LAll) & LAll > 0 & isfinite(tAll) & tAll > 0;
fprintf('\nAccepted %d/%d frames. Review the saved edge overlays.\n', ...
    sum(valid), nFrames);
if sum(valid) < 3
    warning(['Fewer than three reliable lengths: measurements and overlays saved, ' ...
        'but fits skipped. Check the crop, centre, polarity and width settings.']);
    return;
end
if isempty(powerFitPositions), powerFitPositions = 1:nFrames; end
powerMask = valid & ismember((1:nFrames)', powerFitPositions);
earlyMask = valid & ismember((1:nFrames)', earlyFitPositions);
% Select fit ranges before excluding rejected frames.
if sum(powerMask) >= 3
    pPower = polyfit(log(tAll(powerMask)), log(LAll(powerMask)), 1);
    fits.powerA = exp(pPower(2));
    fits.powerB = pPower(1);
    fits.powerR2 = linearR2(LAll(powerMask), ...
        fits.powerA*tAll(powerMask).^fits.powerB);
    fprintf('Power-law regression: L = %.6g t^(%.6g), R2 = %.4f (%d points)\n', ...
        fits.powerA, fits.powerB, fits.powerR2, sum(powerMask));
end
if sum(earlyMask) >= 3
    pExp = polyfit(tAll(earlyMask), log(LAll(earlyMask)), 1);
    fits.expA = exp(pExp(2));
    fits.expB = pExp(1);
    fits.expR2 = linearR2(LAll(earlyMask), ...
        fits.expA*exp(fits.expB*tAll(earlyMask)));
    fprintf('Early exponential fit: L = %.6g exp(%.6g t), R2 = %.4f (%d points)\n', ...
        fits.expA, fits.expB, fits.expR2, sum(earlyMask));
elseif ~isempty(earlyFitPositions)
    warning('Fewer than three valid early frames; exponential fit skipped.');
end
% Fit log(L), then calculate R2 on the length scale over each fit interval.
comparisonFigure = figure('Color', 'w');
dataLine = plot(tAll(valid), LAll(valid), 'ko', 'LineWidth', 1.5, ...
    'DisplayName', 'Data');
hold on;
comparisonAxes = gca;
modelLines = gobjects(0, 1);
tPlot = linspace(min(tAll(valid)), max(tAll(valid)), 300);
if strcmpi(powerMode, 'prescribed')
    modelLines(end+1,1) = plot(tPlot, modelA*tPlot.^modelB, 'r-', 'LineWidth', 2, ...
        'DisplayName', 'Late-time model (prescribed)');
    fprintf('Plotted prescribed model: L = %.6g t^(%.6g)\n', modelA, modelB);
elseif strcmpi(powerMode, 'fit')
    if isfield(fits, 'powerA')
        modelLines(end+1,1) = plot(tPlot, fits.powerA*tPlot.^fits.powerB, 'r-', 'LineWidth', 2, ...
            'DisplayName', sprintf('Power-law fit (b = %.3f)', fits.powerB));
    else
        warning('Fewer than three valid power-fit frames; power fit skipped.');
    end
else
    error('powerMode must be ''prescribed'' or ''fit''.');
end
if isfield(fits, 'expA')
    % The early fit is extended over the displayed interval.
    modelLines(end+1,1) = plot(tPlot, fits.expA*exp(fits.expB*tPlot), 'b--', 'LineWidth', 2, ...
        'DisplayName', 'Early-time exponential (extended)');
end
xlabel('Normalised time');
ylabel('Normalised image-edge separation');
legend('show', 'Location', 'best');
grid on;
print(comparisonFigure, fullfile(outputFolder, 'edge_length_comparison.png'), ...
    '-dpng', '-r180');
save(fullfile(outputFolder, 'edge_lengths.mat'), 'fits', '-append');
fprintf('Results saved in %s\n', outputFolder);
if enablePlotEditor
    installPlotEditor(comparisonFigure, comparisonAxes, dataLine, ...
        modelLines, framePositions(valid), outputFolder);
end

end

% Local functions
function installPlotEditor(fig, ax, dataLine, modelLines, frameNumbers, outputFolder)
    % Plot edits preserve the measurement table and fitted coefficients.
    originalX = get(dataLine, 'XData'); originalX = originalX(:);
    originalY = get(dataLine, 'YData'); originalY = originalY(:);
    keepPoint = true(size(originalX));
    showCurve = true(numel(modelLines), 1);
    curveNames = cell(numel(modelLines), 1);
    for k = 1:numel(modelLines)
        curveNames{k} = get(modelLines(k), 'DisplayName');
    end
    undoStack = {};
    set(fig, 'Name', 'Image-edge separation: edit and export', 'NumberTitle', 'off');
    set(ax, 'Units', 'normalized', 'Position', [0.12 0.24 0.83 0.70]);
    % Fixed limits prevent deletion from moving the remaining points.
    set(ax, 'XLim', get(ax, 'XLim'), 'YLim', get(ax, 'YLim'));
    buttons = gobjects(4, 1);
    buttons(1) = uicontrol(fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
        'Position', [0.04 0.035 0.20 0.07], 'String', 'Delete point', ...
        'Callback', @deletePoint);
    buttons(2) = uicontrol(fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
        'Position', [0.26 0.035 0.20 0.07], 'String', 'Delete line', ...
        'Callback', @deleteCurve);
    buttons(3) = uicontrol(fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
        'Position', [0.48 0.035 0.14 0.07], 'String', 'Undo', ...
        'Callback', @undoEdit);
    buttons(4) = uicontrol(fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
        'Position', [0.64 0.035 0.32 0.07], 'String', 'Save without axes', ...
        'Callback', @saveCleanPlot);
    statusText = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
        'Position', [0.04 0.115 0.92 0.065], 'BackgroundColor', 'w', ...
        'HorizontalAlignment', 'left', 'String', ...
        'Edit points or curves, then save. Curves are not refitted after point deletion.');
    drawnow;

    function restoreButtons()
        if ishandle(fig)
            set(buttons(ishandle(buttons)), 'Enable', 'on');
        end
    end

    function rememberState()
        undoStack{end+1} = struct('keepPoint', keepPoint, 'showCurve', showCurve);
    end

    function refreshPlot()
        displayedY = originalY;
        displayedY(~keepPoint) = NaN;
        set(dataLine, 'XData', originalX, 'YData', displayedY);
        legendLines = gobjects(0, 1);
        legendNames = {};
        if any(keepPoint)
            legendLines(end+1,1) = dataLine;
            legendNames{end+1} = 'Data';
        end
        for c = 1:numel(modelLines)
            if showCurve(c)
                set(modelLines(c), 'Visible', 'on', 'HandleVisibility', 'on');
                legendLines(end+1,1) = modelLines(c);
                legendNames{end+1} = curveNames{c};
            else
                set(modelLines(c), 'Visible', 'off', 'HandleVisibility', 'off');
            end
        end
        if isempty(legendLines)
            legend(ax, 'off');
        else
            legend(ax, legendLines, legendNames, 'Location', 'best');
        end
        drawnow;
    end

    function deletePoint(~, ~)
        if ~any(keepPoint)
            set(statusText, 'String', 'No displayed points remain. Use Undo to restore them.');
            return;
        end
        set(buttons, 'Enable', 'off');
        cleanup = onCleanup(@restoreButtons); %#ok<NASGU>
        set(statusText, 'String', 'Click a data point to remove it. Press Enter to cancel.');
        figure(fig); axes(ax);
        % Disable navigation while selecting a point.
        zoom(fig, 'off'); pan(fig, 'off'); datacursormode(fig, 'off');
        try
            [x, y, button] = ginput(1);
        catch exception
            if ~ishandle(fig), return; end
            rethrow(exception);
        end
        if ~ishandle(fig), return; end
        if isempty(x) || button ~= 1
            set(statusText, 'String', 'Point deletion cancelled.');
            return;
        end
        xl = get(ax, 'XLim'); yl = get(ax, 'YLim');
        axesPixels = getpixelposition(ax, true);
        visible = find(keepPoint);
        distance = hypot((originalX(visible)-x)/diff(xl)*axesPixels(3), ...
            (originalY(visible)-y)/diff(yl)*axesPixels(4));
        [nearestDistance, index] = min(distance);
        if nearestDistance > 16 || x < xl(1) || x > xl(2) || y < yl(1) || y > yl(2)
            set(statusText, 'String', 'No data point close to that click. Click Delete point to try again.');
            return;
        end
        index = visible(index);
        rememberState();
        keepPoint(index) = false;
        refreshPlot();
        set(statusText, 'String', sprintf('Removed frame %d from the plot. Undo restores it.', ...
            frameNumbers(index)));
    end

    function deleteCurve(~, ~)
        available = find(showCurve);
        if isempty(available)
            set(statusText, 'String', 'No displayed lines remain. Use Undo to restore them.');
            return;
        end
        set(buttons, 'Enable', 'off');
        cleanup = onCleanup(@restoreButtons); %#ok<NASGU>
        [selected, confirmed] = listdlg('PromptString', 'Select the line(s) to remove:', ...
            'Name', 'Delete lines', 'SelectionMode', 'multiple', ...
            'ListString', curveNames(available), 'ListSize', [360 100]);
        if ~ishandle(fig), return; end
        if ~confirmed || isempty(selected), return; end
        rememberState();
        showCurve(available(selected)) = false;
        refreshPlot();
        set(statusText, 'String', 'Selected lines removed from the plot. Undo restores them.');
    end

    function undoEdit(~, ~)
        if isempty(undoStack)
            set(statusText, 'String', 'No edits to undo.');
            return;
        end
        previous = undoStack{end};
        undoStack(end) = [];
        keepPoint = previous.keepPoint;
        showCurve = previous.showCurve;
        refreshPlot();
        set(statusText, 'String', 'Last edit undone.');
    end

    function saveCleanPlot(~, ~)
        set(buttons, 'Enable', 'off');
        cleanup = onCleanup(@restoreButtons); %#ok<NASGU>
        baseName = fullfile(outputFolder, 'edge_length_comparison_no_axes');
        try
            exportWithoutAxes(ax, baseName);
            % Record which points were included in the exported plot.
            plotPoints = table(frameNumbers(:), originalX, originalY, keepPoint, ...
                'VariableNames', {'OrderedFrame','NormalizedTime', ...
                'NormalizedLength','IncludedInPlot'});
            writetable(plotPoints, [baseName '_points.csv']);
            plotEdits = struct('frameNumbers', frameNumbers, 'keepPoint', keepPoint, ...
                'curveNames', {curveNames}, 'showCurve', showCurve);
            save(fullfile(outputFolder, 'edge_lengths.mat'), 'plotEdits', '-append');
            if ishandle(statusText)
                set(statusText, 'String', 'Saved PNG, PDF and point selection in the results folder.');
            end
            fprintf('Saved %s.png and %s.pdf\n', baseName, baseName);
        catch exception
            if ishandle(statusText)
                set(statusText, 'String', ['Save failed: ' exception.message]);
            end
            warning('PlotExport:Failed', '%s', exception.message);
        end
    end
end

function exportWithoutAxes(sourceAxes, baseName)
    % Copy only the axes. Editor buttons and the source legend are not copied.
    axesPixels = getpixelposition(sourceAxes, true);
    widthInches = 7;
    heightInches = widthInches*axesPixels(4)/max(axesPixels(3), 1);
    cleanFigure = figure('Visible', 'off', 'Color', 'w', 'Units', 'inches', ...
        'Position', [1 1 widthInches heightInches], 'MenuBar', 'none', 'ToolBar', 'none');
    cleanup = onCleanup(@() closePlotFigure(cleanFigure)); %#ok<NASGU>
    cleanAxes = copyobj(sourceAxes, cleanFigure);
    set(cleanAxes, 'Units', 'normalized', 'Position', [0.02 0.02 0.96 0.96], ...
        'Visible', 'off', 'Box', 'off', 'XGrid', 'off', 'YGrid', 'off', ...
        'XMinorGrid', 'off', 'YMinorGrid', 'off');
    set(get(cleanAxes, 'XLabel'), 'Visible', 'off');
    set(get(cleanAxes, 'YLabel'), 'Visible', 'off');
    set(get(cleanAxes, 'Title'), 'Visible', 'off');
    legend(cleanAxes, 'off');
    set(cleanFigure, 'PaperUnits', 'inches', 'PaperSize', [widthInches heightInches], ...
        'PaperPosition', [0 0 widthInches heightInches], 'InvertHardcopy', 'off');
    print(cleanFigure, [baseName '.png'], '-dpng', '-r300');
    print(cleanFigure, [baseName '.pdf'], '-dpdf', '-painters');
end

function closePlotFigure(fig)
    if ishandle(fig), close(fig); end
end

function [measurement, fig, stopRequested] = reviewFrame( ...
        fig, cropped, smoothProfile, rows, measurement, fileName, frameNumber)
    stopRequested = false;
    while true
        [fig, profileAxes] = drawFrameDiagnostic(fig, cropped, smoothProfile, ...
            rows, measurement, fileName, frameNumber, 'on');
        if measurement.accepted
            prompt = sprintf(['%s\nFrame %d: %s edges, length = %.1f pixels.\n' ...
                'Confirm these edges, or change them manually.'], ...
                fileName, frameNumber, measurement.method, ...
                measurement.right-measurement.left);
            defaultChoice = 'Confirm & next';
        else
            prompt = sprintf(['%s\nFrame %d: %s.\n' ...
                'Choose edges manually or skip this frame.'], ...
                fileName, frameNumber, measurement.status);
            defaultChoice = 'Change manually';
        end
        choice = questdlg(prompt, 'Review image-edge separation', 'Confirm & next', ...
            'Change manually', 'Skip frame', defaultChoice);
        switch choice
            case 'Confirm & next'
                if measurement.accepted
                    measurement.status = ['confirmed: ' measurement.method];
                    return;
                end
                uiwait(warndlg('No accepted edges exist. Choose edges manually or skip.', ...
                    'Choose edges first', 'modal'));
            case 'Change manually'
                % Choose the edges on the intensity profile.
                if ~ishandle(fig)
                    [fig, profileAxes] = drawFrameDiagnostic(fig, cropped, ...
                        smoothProfile, rows, measurement, fileName, frameNumber, 'on');
                end
                figure(fig);
                axes(profileAxes);
                title(profileAxes, ['Click the LEFT and RIGHT edges on this profile. ' ...
                    'Press Enter to cancel.']);
                drawnow;
                try
                    [xPicked, ~, buttons] = ginput(2);
                catch exception
                    if ~ishandle(fig)
                        measurement.accepted = false;
                        measurement.status = 'not confirmed: review stopped';
                        stopRequested = true;
                        return;
                    end
                    rethrow(exception);
                end
                if numel(xPicked) ~= 2 || any(buttons ~= 1)
                    % Keep the current proposal if selection is cancelled.
                    continue;
                end
                chosen = sort(round(xPicked));
                if any(~isfinite(chosen)) || chosen(1) < 1 || ...
                        chosen(2) > numel(smoothProfile) || chosen(1) == chosen(2)
                    uiwait(warndlg('Choose two different positions within the crop.', ...
                        'Invalid edge positions', 'modal'));
                    continue;
                end
                measurement.left = chosen(1);
                measurement.right = chosen(2);
                measurement.method = 'manual';
                measurement.accepted = true;
                measurement.status = 'manual selection: awaiting confirmation';
                % Redraw the edges before confirmation.
            case 'Skip frame'
                measurement.accepted = false;
                measurement.status = 'skipped by user';
                return;
            otherwise
                % Closing the dialog saves earlier confirmations and stops.
                measurement.accepted = false;
                measurement.status = 'not confirmed: review stopped';
                stopRequested = true;
                return;
        end
    end
end

function [fig, profileAxes] = drawFrameDiagnostic( ...
        fig, cropped, smoothProfile, rows, measurement, fileName, frameNumber, visibility)
    if isempty(fig) || ~ishandle(fig)
        fig = figure('Name', 'Edge detection and review', 'NumberTitle', 'off', ...
            'Visible', visibility, 'Color', 'w', 'Position', [100 100 1000 650]);
    end
    set(fig, 'Visible', visibility);
    set(0, 'CurrentFigure', fig);
    clf(fig);
    subplot(2, 1, 1);
    imagesc(cropped); colormap(gray(256)); axis image;
    hold on;
    rectangle('Position', [1 rows(1) size(cropped,2)-1 rows(2)-rows(1)], ...
        'EdgeColor', 'r', 'LineWidth', 1.5);
    plot([measurement.centre measurement.centre], [1 size(cropped,1)], ...
        'c:', 'LineWidth', 1);
    edgeColour = [0 0.65 0];
    if ~measurement.accepted, edgeColour = [0.95 0.5 0]; end
    if isfinite(measurement.left) && isfinite(measurement.right)
        plot([measurement.left measurement.left], [1 size(cropped,1)], ...
            '--', 'Color', edgeColour, 'LineWidth', 1.5);
        plot([measurement.right measurement.right], [1 size(cropped,1)], ...
            '--', 'Color', edgeColour, 'LineWidth', 1.5);
    end
    title(sprintf('%s | frame %d | %s', fileName, frameNumber, ...
        measurement.status), 'Interpreter', 'none');
    xlabel('X position within crop (pixels)');
    ylabel('Y position within crop (pixels)');

    profileAxes = subplot(2, 1, 2);
    plotRange = max(smoothProfile)-min(smoothProfile);
    plottedProfile = (smoothProfile-min(smoothProfile))/max(plotRange, eps);
    plot(plottedProfile, 'b-', 'LineWidth', 2); hold on;
    selectedLength = NaN;
    if isfinite(measurement.left) && isfinite(measurement.right)
        plot([measurement.left measurement.right], ...
            plottedProfile([measurement.left measurement.right]), ...
            'o', 'Color', edgeColour, 'MarkerFaceColor', edgeColour, 'MarkerSize', 7);
        selectedLength = measurement.right-measurement.left;
    end
    xlabel('X position within crop (pixels)');
    ylabel('Normalised mean intensity');
    title(sprintf('Selected length = %.1f px | %s', selectedLength, ...
        measurement.status), 'Interpreter', 'none');
    xlim([1 numel(smoothProfile)]);
    grid on;
    drawnow;
end

function grayImage = readGrayImage(fileName)
    [img, map] = imread(fileName);
    if ~isempty(map)
        img = ind2rgb(img, map);
    end
    if isinteger(img)
        img = double(img)/double(intmax(class(img)));
    else
        img = double(img);
    end
    if ndims(img) == 3
        grayImage = 0.2989*img(:,:,1) + 0.5870*img(:,:,2) + 0.1140*img(:,:,3);
    else
        grayImage = img;
    end
end

function [out, smoothed] = detectEdgePair(profile, cfg)
    % Detect edges on the input intensity scale; normalise only for display.
    profile = double(profile(:)');
    n = numel(profile);
    smoothed = movmean(profile, cfg.smoothWindow);
    centre = cfg.centreX;
    if isempty(centre), centre = (n + 1)/2; end
    out = struct('left', NaN, 'right', NaN, 'centre', centre, ...
        'accepted', false, 'pairRatio', NaN, 'status', 'no reliable edge pair');
    pad = ceil(cfg.smoothWindow/2);
    if n < 6*pad || centre <= 1 || centre >= n
        out.status = 'review: crop too narrow or centre outside crop';
        return;
    end
    residual = profile - smoothed;
    intensityNoise = robustSigma(residual);
    minContrast = max(cfg.minContrast, cfg.noiseMultiplier*intensityNoise);
    if max(smoothed) - min(smoothed) < minContrast
        out.status = 'review: insufficient intensity contrast';
        return;
    end
    slope = gradient(smoothed);
    % Estimate gradient noise from the high-pass residual.
    noiseSlope = gradient(movmean(residual, cfg.smoothWindow));
    gradientNoise = robustSigma(noiseSlope);
    minGradient = max(cfg.noiseMultiplier*gradientNoise, ...
        cfg.minContrast/(4*cfg.smoothWindow));
    strength = abs(slope);
    peaks = find(strength(2:end-1) >= strength(1:end-2) & ...
        strength(2:end-1) > strength(3:end)) + 1;
    % Keep enough room on both flanks to check actual intensity contrasts.
    peaks = peaks(peaks > 2*pad & peaks <= n-2*pad & ...
        strength(peaks) >= minGradient);
    candidateLimit = cfg.maxCandidatesPerSide;
    if strcmpi(cfg.selectionMode, 'outermost')
        candidateLimit = Inf;         % Do not discard weaker outer edges
    end
    left = separatedPeaks(peaks(peaks < centre-cfg.centreGapPx), ...
        strength, cfg.smoothWindow, candidateLimit);
    right = separatedPeaks(peaks(peaks > centre+cfg.centreGapPx), ...
        strength, cfg.smoothWindow, candidateLimit);
    maxWidth = cfg.maxWidthPx;
    if isempty(maxWidth), maxWidth = n-1; end
    pairs = zeros(0, 3);              % [left, right, score]
    for a = 1:numel(left)
        for b = 1:numel(right)
            l = left(a); r = right(b);
            width = r-l;
            if width < max(cfg.minWidthPx, 4*pad) || width > maxWidth || ...
                    slope(l)*slope(r) >= 0
                continue;
            end
            if strcmpi(cfg.polarity, 'bright') && slope(l) < 0, continue; end
            if strcmpi(cfg.polarity, 'dark') && slope(l) > 0, continue; end
            % Positive jumps on both flanks indicate a bright interior;
            % negative jumps on both flanks indicate a dark interior.
            jumpLeft = mean(smoothed(l+pad:l+2*pad)) - ...
                mean(smoothed(l-2*pad:l-pad));
            jumpRight = mean(smoothed(r-2*pad:r-pad)) - ...
                mean(smoothed(r+pad:r+2*pad));
            if jumpLeft*jumpRight <= 0 || ...
                    min(abs([jumpLeft jumpRight])) < minContrast || ...
                    jumpLeft*slope(l) <= 0 || jumpRight*slope(r) >= 0
                continue;
            end
            % A weak symmetry preference, with no assumed width or shrinkage.
            centreWeight = exp(-0.5*(((l+r)/2-centre)/(0.25*n))^2);
            balance = min(strength(l), strength(r))/max(strength(l), strength(r));
            score = sqrt(strength(l)*strength(r))*balance^0.25*centreWeight;
            pairs(end+1, :) = [l r score]; %#ok<AGROW>
        end
    end
    if isempty(pairs), return; end
    if strcmpi(cfg.selectionMode, 'outermost')
        % Measure across the complete feature, including any internal edges.
        % Choose the widest qualifying pair; use strength only to break ties.
        widths = pairs(:,2) - pairs(:,1);
        [~, rank] = sortrows([-widths, -pairs(:,3)], [1 2]);
        out.left = pairs(rank(1),1);
        out.right = pairs(rank(1),2);
        out.accepted = true;
        out.status = 'accepted: outermost edges';
        % PairRatio remains NaN: ambiguity is not assessed in this mode.
        return;
    end
    [~, rank] = sort(pairs(:,3), 'descend');
    pairs = pairs(rank, :);
    out.left = pairs(1,1);
    out.right = pairs(1,2);
    out.pairRatio = Inf;
    if size(pairs, 1) > 1
        out.pairRatio = pairs(1,3)/pairs(2,3);
    end
    if out.pairRatio < cfg.minPairRatio
        out.status = 'review: competing edge pairs';
    else
        out.accepted = true;
        out.status = 'accepted';
    end
end

function kept = separatedPeaks(indices, strength, minDistance, maxCount)
    % Collapse nearby gradient maxima before measuring pair ambiguity.
    kept = [];
    [~, rank] = sort(strength(indices), 'descend');
    for k = 1:numel(rank)
        candidate = indices(rank(k));
        if isempty(kept) || all(abs(kept-candidate) >= minDistance)
            kept(end+1) = candidate; %#ok<AGROW>
            if numel(kept) >= maxCount, break; end
        end
    end
end

function sigma = robustSigma(x)
    sigma = 1.4826*median(abs(x-median(x)));
end

function r2 = linearR2(observed, predicted)
    total = sum((observed-mean(observed)).^2);
    if total <= eps*max(1, sum(observed.^2))
        r2 = NaN;
    else
        r2 = 1-sum((observed-predicted).^2)/total;
    end
end

function order = naturalFileOrder(names)
    % Zero-pad each integer run for natural ordering without external tools.
    keys = cell(size(names));
    for j = 1:numel(names)
        name = lower(names{j});
        [starts, ends] = regexp(name, '\d+', 'start', 'end');
        for k = numel(starts):-1:1
            numberText = name(starts(k):ends(k));
            padded = [repmat('0', 1, max(0, 20-numel(numberText))), numberText];
            name = [name(1:starts(k)-1), padded, name(ends(k)+1:end)];
        end
        keys{j} = name;
    end
    [~, order] = sort(keys);
end

function validateConfiguration(cfg)
    if ~isstruct(cfg) || ~isscalar(cfg)
        error('Configuration must be a scalar structure.');
    end
    required = {'inputFolder','outputFolder','imagePattern','imageOrder', ...
        'framePositions','cropRect','bandRows','referenceWidthPx', ...
        'timeValues','timeOrigin','timeScale','detector','showDiagnostics', ...
        'saveDiagnostics','reviewEachFrame','enablePlotEditor','powerMode', ...
        'earlyFitPositions','powerFitPositions','model'};
    requireFields(cfg, required, 'cfg');
    textFields = {'inputFolder','outputFolder','imagePattern','powerMode'};
    for k = 1:numel(textFields)
        value = cfg.(textFields{k});
        if ~((ischar(value) && isrow(value) && ~isempty(strtrim(value))) || ...
                (isstring(value) && isscalar(value) && strlength(strtrim(value)) > 0))
            error('cfg.%s must be nonempty text.', textFields{k});
        end
    end
    if ~exist(cfg.inputFolder, 'dir')
        error('inputFolder does not exist.');
    end
    [~, inputAttributes] = fileattrib(cfg.inputFolder);
    if exist(cfg.outputFolder, 'dir')
        [~, outputAttributes] = fileattrib(cfg.outputFolder);
        if strcmp(inputAttributes.Name, outputAttributes.Name)
            error('Use a separate outputFolder for the results.');
        end
    elseif exist(cfg.outputFolder, 'file')
        error('outputFolder refers to an existing file.');
    end
    validateattributes(cfg.cropRect, {'numeric'}, ...
        {'real','finite','integer','positive','vector','numel',4}, mfilename, 'cropRect');
    validateattributes(cfg.bandRows, {'numeric'}, ...
        {'real','finite','integer','positive','vector','numel',2}, mfilename, 'bandRows');
    if cfg.bandRows(2) <= cfg.bandRows(1) || cfg.bandRows(2) > cfg.cropRect(4)
        error('bandRows must select at least two rows inside the crop.');
    end
    validateattributes(cfg.referenceWidthPx, {'numeric'}, ...
        {'real','finite','scalar','positive'}, mfilename, 'referenceWidthPx');
    validateattributes(cfg.timeValues, {'numeric'}, ...
        {'real','finite','vector','nonempty'}, mfilename, 'timeValues');
    validateattributes(cfg.timeOrigin, {'numeric'}, ...
        {'real','finite','scalar'}, mfilename, 'timeOrigin');
    validateattributes(cfg.timeScale, {'numeric'}, ...
        {'real','finite','scalar','positive'}, mfilename, 'timeScale');
    validatePositions(cfg.imageOrder, Inf, 'imageOrder', false);
    validatePositions(cfg.framePositions, Inf, 'framePositions');
    switches = {'showDiagnostics','saveDiagnostics','reviewEachFrame','enablePlotEditor'};
    for k = 1:numel(switches)
        validateattributes(cfg.(switches{k}), {'logical','numeric'}, ...
            {'scalar','binary'}, mfilename, switches{k});
    end
    if ~any(strcmpi(cfg.powerMode, {'prescribed','fit'}))
        error('powerMode must be ''prescribed'' or ''fit''.');
    end
    requireFields(cfg.detector, {'smoothWindow','selectionMode','centreX', ...
        'minWidthPx','maxWidthPx','centreGapPx','polarity','minContrast', ...
        'noiseMultiplier','minPairRatio','maxCandidatesPerSide'}, 'cfg.detector');
    det = cfg.detector;
    validateattributes(det.smoothWindow, {'numeric'}, ...
        {'real','finite','scalar','integer','positive'}, mfilename, 'detector.smoothWindow');
    if mod(det.smoothWindow, 2) ~= 1
        error('detector.smoothWindow must be odd.');
    end
    validateattributes(det.minWidthPx, {'numeric'}, ...
        {'real','finite','scalar','positive'}, mfilename, 'detector.minWidthPx');
    validateattributes(det.centreGapPx, {'numeric'}, ...
        {'real','finite','scalar','nonnegative'}, mfilename, 'detector.centreGapPx');
    validateattributes(det.minContrast, {'numeric'}, ...
        {'real','finite','scalar','positive','<=',1}, mfilename, 'detector.minContrast');
    validateattributes(det.noiseMultiplier, {'numeric'}, ...
        {'real','finite','scalar','positive'}, mfilename, 'detector.noiseMultiplier');
    validateattributes(det.minPairRatio, {'numeric'}, ...
        {'real','finite','scalar','>=',1}, mfilename, 'detector.minPairRatio');
    validateattributes(det.maxCandidatesPerSide, {'numeric'}, ...
        {'real','finite','scalar','integer','positive'}, mfilename, 'detector.maxCandidatesPerSide');
    if ~isempty(det.centreX)
        validateattributes(det.centreX, {'numeric'}, ...
            {'real','finite','scalar','>',1,'<',cfg.cropRect(3)}, mfilename, 'detector.centreX');
    end
    if ~isempty(det.maxWidthPx)
        validateattributes(det.maxWidthPx, {'numeric'}, ...
            {'real','finite','scalar','>=',det.minWidthPx}, mfilename, 'detector.maxWidthPx');
    end
    if ~any(strcmpi(det.selectionMode, {'outermost','best-pair'}))
        error('detector.selectionMode must be ''outermost'' or ''best-pair''.');
    end
    if ~any(strcmpi(det.polarity, {'bright','dark','either'}))
        error('detector.polarity must be ''bright'', ''dark'' or ''either''.');
    end
end

function requireFields(value, names, label)
    if ~isstruct(value) || ~isscalar(value)
        error('%s must be a scalar structure.', label);
    end
    for k = 1:numel(names)
        if ~isfield(value, names{k})
            error('Missing %s.%s. Use auto_vorticity_length_config as a template.', ...
                label, names{k});
        end
    end
end

function validatePositions(positions, count, label, increasing)
    if nargin < 4, increasing = true; end
    if isempty(positions), return; end
    validateattributes(positions, {'numeric'}, ...
        {'real','finite','vector','integer','positive'}, mfilename, label);
    if any(positions > count) || numel(unique(positions)) ~= numel(positions) || ...
            (increasing && any(diff(positions(:)) <= 0))
        error('%s must contain distinct valid indices in the requested order.', label);
    end
end

function [amplitude, exponent] = prescribedModel(cfg)
    amplitude = NaN;
    exponent = NaN;
    if ~strcmpi(cfg.powerMode, 'prescribed'), return; end
    model = cfg.model;
    requireFields(model, {'kind','amplitude'}, 'cfg.model');
    validateattributes(model.amplitude, {'numeric'}, ...
        {'real','finite','scalar','positive'}, mfilename, 'model.amplitude');
    amplitude = model.amplitude;
    if strcmpi(model.kind, 'coefficients')
        requireFields(model, {'exponent'}, 'cfg.model');
        validateattributes(model.exponent, {'numeric'}, ...
            {'real','finite','scalar'}, mfilename, 'model.exponent');
        exponent = model.exponent;
    elseif strcmpi(model.kind, 'physical')
        fields = {'rhoHigh','rhoLow','area','gravity','height','densityDifference'};
        requireFields(model, fields, 'cfg.model');
        for k = 1:numel(fields)
            validateattributes(model.(fields{k}), {'numeric'}, ...
                {'real','finite','scalar','positive'}, mfilename, ['model.' fields{k}]);
        end
        if model.rhoHigh <= model.rhoLow
            error('model.rhoHigh must be greater than model.rhoLow.');
        end
        atwood = (model.rhoHigh-model.rhoLow)/(model.rhoHigh+model.rhoLow);
        first = model.gravity*atwood^2/(model.area^2*pi^2);
        exponent = -first/(model.gravity*model.height* ...
            model.densityDifference/model.rhoHigh)^(3/2);
        if ~isfinite(exponent)
            error('The prescribed model parameters give a nonfinite exponent.');
        end
    else
        error('model.kind must be ''coefficients'' or ''physical''.');
    end
end
