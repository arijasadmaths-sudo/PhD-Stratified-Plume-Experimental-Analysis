function outputFiles = test_forward_ray_A(cfg)
% Reconstruct each selected image and save its forward projection.
% Start with cfg = plif_settings(), then supply the image and calibration data.
% The MAT file keeps the dimensionless field at full precision.
% Standalone field PNGs are saved separately from comparison panels.
if nargin < 1
    error('PLIF:Settings', 'Supply a configuration created with plif_settings().');
end
[cali,imageFiles,outputNames] = plif_prepare(cfg,'_PLIF_forward');
fieldFolder = fullfile(cfg.outputFolder,'reconstructed_fields');
for k = 1:numel(imageFiles)
    fieldPath = fullfile(fieldFolder,[outputNames{k} '.png']);
    if ~cfg.overwrite && isfile(fieldPath)
        error('PLIF:ExistingOutput', 'Output already exists: %s',fieldPath);
    end
end
if ~isfolder(fieldFolder)
    mkdir(fieldFolder);
end
outputFiles = cell(numel(imageFiles),3);
for k = 1:numel(imageFiles)
    fprintf('Reconstruction %d/%d: %s\n',k,numel(imageFiles),imageFiles{k});
    image_in = plif_read_image(fullfile(cfg.inputFolder,imageFiles{k}),cfg.cropRect);
    result = plif_reconstruct(image_in,cali,cfg);
    sourceFile = imageFiles{k};
    dataPath = fullfile(cfg.outputFolder,[outputNames{k} '.mat']);
    save(dataPath,'result','cfg','sourceFile');
    fieldPath = fullfile(fieldFolder,[outputNames{k} '.png']);
    imwrite(result.reconstructedField,fieldPath,'png');

    fig = figure('Color','w','Visible','off','Position',[100 100 1400 440]);
    cleanup = onCleanup(@() close(fig));
    layout = tiledlayout(fig,1,4,'Padding','compact','TileSpacing','compact');
    panels = {result.measuredFluorescence,result.reconstructedField, ...
        result.syntheticFluorescence, ...
        abs(result.syntheticFluorescence-result.measuredFluorescence)};
    labels = {'Measured fluorescence','Reconstructed field', ...
        'Synthetic fluorescence','Absolute residual'};
    commonValues = [panels{1}(:);panels{3}(:)];
    commonValues = commonValues(isfinite(commonValues));
    if isempty(commonValues)
        error('PLIF:ForwardImage', 'No finite fluorescence values were produced for %s.',sourceFile);
    end
    commonLimits = [min(commonValues) max(commonValues)];
    if commonLimits(1) == commonLimits(2)
        commonLimits(2) = commonLimits(1)+1;
    end
    for p = 1:4
        ax = nexttile(layout);
        imagesc(ax,panels{p});
        axis(ax,'image');
        axis(ax,'off');
        title(ax,labels{p});
        colorbar(ax);
        if p == 1 || p == 3
            caxis(ax,commonLimits);
        elseif p == 2
            caxis(ax,[0 1]);
        end
    end
    colormap(fig,gray(256));
    sgtitle(layout,sourceFile,'Interpreter','none');
    figurePath = fullfile(cfg.outputFolder,[outputNames{k} '.png']);
    exportgraphics(fig,figurePath,'Resolution',cfg.figureResolution,'BackgroundColor','white');
    outputFiles(k,:) = {dataPath,figurePath,fieldPath};
    clear cleanup
end
end
