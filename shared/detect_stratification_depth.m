function result = detect_stratification_depth(densityProfiles, rowCoordinates_m, ambientDensity, epsilon, tankHeight_m)
%DETECT_STRATIFICATION_DEPTH Apply the thesis stratification-height detector.
%   RESULT = DETECT_STRATIFICATION_DEPTH(DENSITYPROFILES, ROWCOORDINATES_M,
%   AMBIENTDENSITY, EPSILON) scans each dimensional density profile from the
%   lowest retained row upwards. A neighbouring-row density difference with
%   magnitude greater than EPSILON defines a candidate lower-boundary row.
%   The candidate is rejected when any strictly higher row is exactly equal
%   to AMBIENTDENSITY. The first candidate that passes this return test is
%   retained as z_b.
%
%   DENSITYPROFILES is nRows-by-nFrames and must contain reconstructed density
%   values in kg m^-3. ROWCOORDINATES_M gives the physical height of each input
%   row in metres; it may increase or decrease with image row number. EPSILON
%   is the fixed dimensional neighbouring-row tolerance for the data set, in
%   kg m^-3. The comparison is strict: abs(delta rho) > EPSILON.
%
%   RESULT = ...(..., TANKHEIGHT_M) also returns h = TANKHEIGHT_M - z_b.
%
%   The ambient-return test deliberately uses exact equality, matching the
%   bounded reconstruction described in the thesis. No intensity
%   normalisation, smoothing, interpolation or replacement tolerance is used.

    narginchk(4, 5);
    if nargin < 5
        tankHeight_m = [];
    end

    validateattributes(densityProfiles, {'numeric'}, ...
        {'real', 'finite', 'nonempty', '2d'}, mfilename, 'densityProfiles');
    validateattributes(rowCoordinates_m, {'numeric'}, ...
        {'real', 'finite', 'vector', 'nonempty'}, mfilename, 'rowCoordinates_m');
    validateattributes(ambientDensity, {'numeric'}, ...
        {'real', 'finite', 'scalar'}, mfilename, 'ambientDensity');
    validateattributes(epsilon, {'numeric'}, ...
        {'real', 'finite', 'scalar', 'positive'}, mfilename, 'epsilon');
    if ~isempty(tankHeight_m)
        validateattributes(tankHeight_m, {'numeric'}, ...
            {'real', 'finite', 'scalar', 'positive'}, mfilename, 'tankHeight_m');
    end

    if isvector(densityProfiles)
        densityProfiles = densityProfiles(:);
    end
    rowCoordinates_m = rowCoordinates_m(:);
    if size(densityProfiles, 1) ~= numel(rowCoordinates_m)
        error('detect_stratification_depth:Rows', ...
            'rowCoordinates_m must contain one coordinate for each profile row.');
    end
    if numel(rowCoordinates_m) < 2
        error('detect_stratification_depth:Rows', ...
            'At least two retained rows are required.');
    end

    [zAscending, order] = sort(rowCoordinates_m, 'ascend');
    if any(diff(zAscending) <= 0)
        error('detect_stratification_depth:Coordinates', ...
            'rowCoordinates_m must contain unique physical heights.');
    end
    if ~isempty(tankHeight_m) && tankHeight_m < zAscending(end)
        error('detect_stratification_depth:TankHeight', ...
            'tankHeight_m cannot be below the highest retained row.');
    end
    profiles = densityProfiles(order, :);
    nFrames = size(profiles, 2);

    zBoundary = nan(1, nFrames);
    layerDepth = nan(1, nFrames);
    lowerRowOriginal = nan(1, nFrames);
    upperRowOriginal = nan(1, nFrames);
    difference = nan(1, nFrames);

    for frame = 1:nFrames
        profile = profiles(:, frame);
        for lowerRow = 1:numel(zAscending)-1
            upperRow = lowerRow + 1;
            deltaRho = abs(profile(upperRow) - profile(lowerRow));
            if deltaRho <= epsilon
                continue
            end

            % The candidate is the lower row of the triggering neighbouring
            % pair. Every row above it, including the adjacent upper row, is
            % checked for an exact return to the bounded ambient density.
            if any(profile(upperRow:end) == ambientDensity)
                continue
            end

            zBoundary(frame) = zAscending(lowerRow);
            lowerRowOriginal(frame) = order(lowerRow);
            upperRowOriginal(frame) = order(upperRow);
            difference(frame) = deltaRho;
            if ~isempty(tankHeight_m)
                layerDepth(frame) = tankHeight_m - zBoundary(frame);
            end
            break
        end
    end

    result.z_b_m = zBoundary;
    result.h_m = layerDepth;
    result.candidateLowerRow = lowerRowOriginal;
    result.candidateUpperRow = upperRowOriginal;
    result.candidateDeltaRho_kg_m3 = difference;
    result.detected = isfinite(zBoundary);
    result.rowCoordinates_m = rowCoordinates_m;
    result.scanOrder = order;
    result.ambientDensity_kg_m3 = ambientDensity;
    result.epsilon_kg_m3 = epsilon;
    result.tankHeight_m = tankHeight_m;
end
