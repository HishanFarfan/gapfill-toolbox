function [xFilled, report] = seasonal_template_fill(x, varargin)
%GAPFILL.INTERNAL.SEASONAL_TEMPLATE_FILL Fill gaps using trend + seasonal template.

    parser = inputParser;
    parser.addParameter("Time", [], @(v) isempty(v) || isvector(v));
    parser.addParameter("Period", NaN, @(v) isnumeric(v) && isscalar(v));
    parser.addParameter("TrendWindow", [], @(v) isempty(v) || (isnumeric(v) && isscalar(v) && v >= 3));
    parser.addParameter("MinGapLength", 4, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("MaxGapLength", 96, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("SeedMethod", "pchip");
    parser.parse(varargin{:});
    opts = parser.Results;

    xOriginal = double(x(:));
    n = numel(xOriginal);
    if isempty(opts.Time)
        t = (1:n).';
    else
        t = double(opts.Time(:));
    end

    xFilled = xOriginal;
    period = round(opts.Period);
    if isnan(period) || period < 2 || period > floor(n / 2)
        report = empty_report();
        return;
    end

    trendWindow = opts.TrendWindow;
    if isempty(trendWindow)
        trendWindow = max(2 * period + 1, 9);
    end

    xSeed = gapfill.internal.complete_seed_series(t, xOriginal, char(opts.SeedMethod));
    if any(isnan(xSeed))
        report = empty_report();
        return;
    end

    trend = movmean(xSeed, trendWindow, 'Endpoints', 'shrink');
    phase = mod((1:n).' - 1, period) + 1;
    valid = ~isnan(xOriginal);
    detrendedObs = xOriginal(valid) - trend(valid);
    seasonalProfile = NaN(period, 1);
    for k = 1:period
        mask = valid & phase == k;
        if any(mask)
            seasonalProfile(k) = mean(xOriginal(mask) - trend(mask));
        end
    end

    seasonalProfile = fill_missing_profile(seasonalProfile);
    residualObs = xOriginal(valid) - trend(valid) - seasonalProfile(phase(valid));
    residual = interp1(t(valid), residualObs, t, 'linear', 'extrap');

    missing = isnan(xFilled);
    [gapStarts, gapEnds, gapLengths] = gapfill.internal.find_gaps(missing);
    filledStarts = [];
    filledEnds = [];
    filledLengths = [];

    for i = 1:numel(gapLengths)
        gapLength = gapLengths(i);
        if gapLength < opts.MinGapLength || gapLength > opts.MaxGapLength
            continue;
        end

        idx = (gapStarts(i):gapEnds(i)).';
        templateValues = trend(idx) + seasonalProfile(phase(idx)) + residual(idx);
        xFilled(idx) = templateValues;
        filledStarts(end + 1, 1) = gapStarts(i); %#ok<AGROW>
        filledEnds(end + 1, 1) = gapEnds(i); %#ok<AGROW>
        filledLengths(end + 1, 1) = gapLength; %#ok<AGROW>
    end

    report = struct;
    report.period = period;
    report.trend_window = trendWindow;
    report.filled_gap_starts = filledStarts;
    report.filled_gap_ends = filledEnds;
    report.filled_gap_lengths = filledLengths;
    report.n_filled_gaps = numel(filledLengths);
end

function profile = fill_missing_profile(profile)
    n = numel(profile);
    idx = (1:n).';
    valid = ~isnan(profile);
    if sum(valid) < 2
        profile(:) = 0;
        return;
    end
    profile(~valid) = interp1(idx(valid), profile(valid), idx(~valid), 'linear', 'extrap');
    profile = profile - mean(profile);
end

function report = empty_report()
    report = struct;
    report.period = NaN;
    report.trend_window = NaN;
    report.filled_gap_starts = zeros(0, 1);
    report.filled_gap_ends = zeros(0, 1);
    report.filled_gap_lengths = zeros(0, 1);
    report.n_filled_gaps = 0;
end
