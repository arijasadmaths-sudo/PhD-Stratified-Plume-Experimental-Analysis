function test_densityheight_time_order
% Synthetic regression test; run with the shared folder on the MATLAB path.
% Requires Image Processing Toolbox, but no experimental data.
    folder = tempname;
    mkdir(folder);
    cleanup = onCleanup(@() rmdir(folder, 's')); %#ok<NASGU>
    amplitudes = [0, 60, 20, 80];
    names = cell(1, numel(amplitudes));
    for index = 1:numel(amplitudes)
        names{index} = sprintf('%02d.png', index);
        values = uint8([0; 0; amplitudes(index); amplitudes(index)]);
        imwrite(repmat(values, 1, 3), fullfile(folder, names{index}));
    end
    config.imageFolder = folder;
    config.imageFiles = names;
    config.timeSeconds = [0, 2, 5, 9];
    config.referenceFrame = 1;
    config.makePlots = false;
    config.legacyDiagnostic = true;
    config.fitTarget = 'none';
    result = densityheight(config);
    assert(isequal(result.timeSeconds, config.timeSeconds));
    assert(max(abs(result.legacy.timeOrderedSignal - [0, .75, .25, 1])) < 1e-12);
    assert(~isfield(result.legacy, 'sortedSignal'));
    config.fitTarget = 'legacy_profile_signal';
    result = densityheight(config);
    expectedFit = polyfit(log(config.timeSeconds(2:end)), log([.75, .25, 1]), 1);
    assert(abs(result.powerFit.b - expectedFit(1)) < 1e-12);
    config.fitTarget = 'legacy_sorted_signal';
    caught = false;
    try
        densityheight(config);
    catch exception
        caught = strcmp(exception.identifier, 'densityheight:RemovedSortedSignal');
    end
    assert(caught, 'Old sorted-signal configurations must fail explicitly.');
    fprintf('Time-order and removed-option regression checks passed.\n');
end
