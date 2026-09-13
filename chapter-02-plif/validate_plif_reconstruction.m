function summaryTable = validate_plif_reconstruction(cfg)
% Compare measured fluorescence with the forward image of the reconstructed field.
% Both calculations use the same calibration-derived incident intensities.
% This checks forward consistency; it does not calibrate absolute density.
if nargin < 1
    error('PLIF:Settings', 'Supply a configuration created with plif_settings().');
end
cfg.forwardIncidentIntensity = 'calibration';
[cali,imageFiles,outputNames] = plif_prepare(cfg,'_PLIF_validation');
summaryPath = fullfile(cfg.outputFolder,'PLIF_validation_summary.csv');
if ~cfg.overwrite && isfile(summaryPath)
    error('PLIF:ExistingOutput', 'Output already exists: %s',summaryPath);
end
nFiles = numel(imageFiles);
File = strings(nFiles,1);
RMSE = nan(nFiles,1);
NRMSE_percent = nan(nFiles,1);
MAE = nan(nFiles,1);
MaxAbsResidual = nan(nFiles,1);
Correlation = nan(nFiles,1);
SignalPixelCount = zeros(nFiles,1);
SignalRMSE = nan(nFiles,1);
SignalNRMSE_percent = nan(nFiles,1);

for k = 1:nFiles
    fprintf('Validation %d/%d: %s\n',k,nFiles,imageFiles{k});
    image_in = plif_read_image(fullfile(cfg.inputFolder,imageFiles{k}),cfg.cropRect);
    result = plif_reconstruct(image_in,cali,cfg);
    img = result.measuredFluorescence;
    img_new = result.syntheticFluorescence;
    if ~isequal(size(img),size(img_new))
        error('PLIF:ForwardSize', 'Measured and synthetic image dimensions differ for %s.',imageFiles{k});
    end
    valid = isfinite(img) & isfinite(img_new);
    if nnz(valid) < 2
        warning('PLIF:ValidPixels', 'Too few valid pixels for %s.',imageFiles{k});
        continue
    end

    Fmeas = double(img(valid));
    Fsynth = double(img_new(valid));
    residualVector = Fsynth-Fmeas;
    absResidualVector = abs(residualVector);
    RMSE(k) = sqrt(mean(residualVector.^2));
    MAE(k) = mean(absResidualVector);
    MaxAbsResidual(k) = max(absResidualVector);
    measuredRange = max(Fmeas)-min(Fmeas);
    if measuredRange > 0
        NRMSE_percent(k) = 100*RMSE(k)/measuredRange;
    end
    if std(Fmeas) > 0 && std(Fsynth) > 0
        C = corrcoef(Fmeas,Fsynth);
        Correlation(k) = C(1,2);
    end

    % Report the signal region as well as the full image, which may include
    % a large area with little fluorescence.
    signalThreshold = min(Fmeas)+cfg.signalThresholdFraction*max(measuredRange,eps);
    signalMask = valid & (double(img) > signalThreshold | double(img_new) > signalThreshold);
    SignalPixelCount(k) = nnz(signalMask);
    if SignalPixelCount(k) >= 2
        signalMeasured = double(img(signalMask));
        signalSynthetic = double(img_new(signalMask));
        SignalRMSE(k) = sqrt(mean((signalSynthetic-signalMeasured).^2));
        signalRange = max(signalMeasured)-min(signalMeasured);
        if signalRange > 0
            SignalNRMSE_percent(k) = 100*SignalRMSE(k)/signalRange;
        end
    end
    File(k) = string(imageFiles{k});

    % Save the summary after each frame so completed comparisons are retained.
    summaryTable = makeSummary(File,RMSE,NRMSE_percent,MAE,MaxAbsResidual, ...
        Correlation,SignalPixelCount,SignalRMSE,SignalNRMSE_percent);
    writetable(summaryTable,summaryPath);
    fprintf('  RMSE = %.6g; full-domain NRMSE = %.3f%%; correlation = %.6f\n', ...
        RMSE(k),NRMSE_percent(k),Correlation(k));

    residualImage = abs(double(img_new)-double(img));
    residualImage(~valid) = NaN;
    commonValues = [double(img(valid));double(img_new(valid))];
    commonCLim = [min(commonValues),max(commonValues)];
    if commonCLim(2) <= commonCLim(1)
        commonCLim = commonCLim(1)+[0 1];
    end
    fig = figure('Color','w','Position',[100 100 1500 520],'Visible','off');
    cleanup = onCleanup(@() close(fig));
    tl = tiledlayout(fig,1,3,'Padding','compact','TileSpacing','compact');
    ax1 = nexttile(tl);
    imagesc(ax1,double(img));
    axis(ax1,'image');
    axis(ax1,'off');
    caxis(ax1,commonCLim);
    title(ax1,'Measured fluorescence');
    colorbar(ax1);
    ax2 = nexttile(tl);
    imagesc(ax2,double(img_new));
    axis(ax2,'image');
    axis(ax2,'off');
    caxis(ax2,commonCLim);
    title(ax2,'Synthetic fluorescence');
    colorbar(ax2);
    ax3 = nexttile(tl);
    imagesc(ax3,residualImage);
    axis(ax3,'image');
    axis(ax3,'off');
    title(ax3,'Absolute residual');
    colorbar(ax3);
    colormap(fig,gray(256));
    sgtitle(tl,sprintf('%s | full-domain NRMSE = %.2f%% | r = %.4f', ...
        imageFiles{k},NRMSE_percent(k),Correlation(k)),'Interpreter','none');
    figurePath = fullfile(cfg.outputFolder,[outputNames{k} '.png']);
    exportgraphics(fig,figurePath,'Resolution',cfg.figureResolution,'BackgroundColor','white');
    clear cleanup

    measuredFluorescence = img;
    syntheticFluorescence = img_new;
    absoluteResidual = residualImage;
    reconstructedField = result.reconstructedField;
    sourceFile = imageFiles{k};
    dataPath = fullfile(cfg.outputFolder,[outputNames{k} '.mat']);
    save(dataPath,'measuredFluorescence','syntheticFluorescence', ...
        'absoluteResidual','reconstructedField','result','cfg','sourceFile');
end
summaryTable = makeSummary(File,RMSE,NRMSE_percent,MAE,MaxAbsResidual, ...
    Correlation,SignalPixelCount,SignalRMSE,SignalNRMSE_percent);
writetable(summaryTable,summaryPath);
fprintf('Saved validation summary: %s\n',summaryPath);
end

function summaryTable = makeSummary(File,RMSE,NRMSE_percent,MAE,MaxAbsResidual, ...
        Correlation,SignalPixelCount,SignalRMSE,SignalNRMSE_percent)
completed = strlength(File) > 0;
summaryTable = table(File(completed),RMSE(completed),NRMSE_percent(completed), ...
    MAE(completed),MaxAbsResidual(completed),Correlation(completed), ...
    SignalPixelCount(completed),SignalRMSE(completed),SignalNRMSE_percent(completed), ...
    'VariableNames',{'File','RMSE','NRMSE_percent','MAE','MaxAbsResidual', ...
    'Correlation','SignalPixelCount','SignalRMSE','SignalNRMSE_percent'});
end
