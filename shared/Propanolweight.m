function [Grams, Prop, NaCln, segment] = Propanolweight(ps, pf, fw, saltCalibration, propanolCalibration)
%PROPANOLWEIGHT Calculate propanol mass from paired refractive-index calibrations.
%   [Grams, Prop, NaCln, segment] = Propanolweight(ps, pf, fw, ...
%       saltCalibration, propanolCalibration)
%
%   ps is the salt-solution density and pf is the base-fluid density, both in
%   kg m^-3. fw is the base-fluid volume in m^3, before adding propanol.
%
%   Supply the empirical calibration tables as numeric arrays:
%     saltCalibration     = [density_kg_m3, refractive_index];
%     propanolCalibration = [refractive_index, mass_ratio_percent].
%   Each table must have the same number of rows, with at least two rows.
%   Rows must be ordered by increasing first-column value. Segment k in the
%   salt table is paired with segment k in the propanol table.
%
%   The salt density selects the segment for both interpolations. At an
%   internal salt-density knot, use the segment above it. The final knot uses
%   the last segment. Salt densities outside the calibration range are rejected.
%   The paired propanol segment is retained even if NaCln falls outside its
%   refractive-index interval; this step then extrapolates that segment.
%
%   Prop is grams of propanol per 100 grams of base fluid, not the percentage
%   of the final mixture. Grams is the mass of propanol to add. NaCln is the
%   interpolated refractive index and segment identifies the paired rows used.

    narginchk(5, 5);
    validateattributes(ps, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'}, mfilename, 'ps');
    validateattributes(pf, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'}, mfilename, 'pf');
    validateattributes(fw, {'numeric'}, ...
        {'scalar', 'real', 'finite', 'positive'}, mfilename, 'fw');
    validateattributes(saltCalibration, {'numeric'}, ...
        {'2d', 'real', 'finite', 'ncols', 2}, mfilename, 'saltCalibration');
    validateattributes(propanolCalibration, {'numeric'}, ...
        {'2d', 'real', 'finite', 'ncols', 2}, mfilename, 'propanolCalibration');

    rowCount = size(saltCalibration, 1);
    if rowCount < 2 || size(propanolCalibration, 1) ~= rowCount
        error('Propanolweight:CalibrationSize', ...
            'The calibration tables must have the same number of rows, with at least two rows.');
    end
    if any(diff(saltCalibration(:, 1)) <= 0) || ...
            any(diff(propanolCalibration(:, 1)) <= 0)
        error('Propanolweight:CalibrationOrder', ...
            'The first column of each calibration table must be strictly increasing.');
    end
    if any(saltCalibration(:) <= 0) || ...
            any(propanolCalibration(:, 1) <= 0) || ...
            any(propanolCalibration(:, 2) < 0)
        error('Propanolweight:CalibrationValues', ...
            'Densities and refractive indices must be positive; mass ratios must be non-negative.');
    end
    if ps < saltCalibration(1, 1) || ps > saltCalibration(end, 1)
        error('Propanolweight:DensityRange', ...
            'The salt-solution density lies outside the supplied calibration range.');
    end

    % Keep the same paired segment through both calculations.
    segment = find(ps >= saltCalibration(:, 1), 1, 'last');
    segment = min(segment, rowCount - 1);
    saltPair = double(saltCalibration(segment:segment + 1, :));
    propanolPair = double(propanolCalibration(segment:segment + 1, :));
    NaCln = saltPair(1, 2) + (saltPair(2, 2) - saltPair(1, 2)) * ...
        (double(ps) - saltPair(1, 1)) / (saltPair(2, 1) - saltPair(1, 1));
    Prop = propanolPair(1, 2) + (propanolPair(2, 2) - propanolPair(1, 2)) * ...
        (NaCln - propanolPair(1, 1)) / (propanolPair(2, 1) - propanolPair(1, 1));
    if Prop < 0
        error('Propanolweight:NegativeMass', ...
            'The paired calibration segment gives a negative propanol mass ratio.');
    end

    % Convert the base-fluid mass to grams, then apply the mass ratio.
    Grams = (Prop / 100) * double(pf) * double(fw) * 1000;
end
