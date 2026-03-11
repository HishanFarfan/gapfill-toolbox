function report = profile(data, varargin)
%GAPFILL.PROFILE Summarize missing-data geometry and baseline series metrics.

    parser = inputParser;
    parser.addParameter("Time", [], @(x) isempty(x) || isvector(x));
    parser.addParameter("MaxLag", 20, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    parser.parse(varargin{:});
    opts = parser.Results;

    x = double(data(:));
    n = numel(x);

    if isempty(opts.Time)
        t = (1:n).';
    else
        t = double(opts.Time(:));
        if numel(t) ~= n
            error("gapfill:profile:TimeSizeMismatch", ...
                "Time vector must have the same length as data.");
        end
    end

    valid = ~isnan(x);
    missing = ~valid;
    [gapStarts, gapEnds, gapLengths] = gapfill.internal.find_gaps(missing);
    [segmentStarts, segmentEnds] = gapfill.internal.find_segments(valid);

    xValid = x(valid);
    tValid = t(valid);

    report = struct;
    report.n_total = n;
    report.n_valid = sum(valid);
    report.n_missing = sum(missing);
    report.missing_fraction = sum(missing) / max(n, 1);
    report.gap_starts = gapStarts;
    report.gap_ends = gapEnds;
    report.gap_lengths = gapLengths;
    report.n_gaps = numel(gapLengths);
    report.max_gap = gapfill.internal.safe_stat(gapLengths, "max");
    report.mean_gap = gapfill.internal.safe_stat(gapLengths, "mean");
    report.median_gap = gapfill.internal.safe_stat(gapLengths, "median");
    report.segment_starts = segmentStarts;
    report.segment_ends = segmentEnds;
    report.segment_lengths = segmentEnds - segmentStarts + 1;

    stats = struct;
    if isempty(xValid)
        stats.mean = NaN;
        stats.std = NaN;
        stats.var = NaN;
        stats.median = NaN;
        stats.mad = NaN;
        stats.min = NaN;
        stats.max = NaN;
        stats.range = NaN;
        stats.outlier_fraction = NaN;
        stats.trend_slope = NaN;
        stats.trend_intercept = NaN;
        stats.trend_rsq = NaN;
        stats.trend_strength = NaN;
        stats.roughness = NaN;
        stats.roughness_ratio = NaN;
        stats.burstiness_index = NaN;
        stats.hurst_exponent = NaN;
        stats.hurst_effective = NaN;
        stats.hurst_rsq = NaN;
        stats.acf = NaN(opts.MaxLag + 1, 1);
        stats.acf_lags = (0:opts.MaxLag).';
        stats.persistence_lag1 = NaN;
        stats.seasonality_period = NaN;
        stats.seasonality_strength = NaN;
        stats.seasonality_peak_value = NaN;
        stats.seasonality_spectral_period = NaN;
        stats.seasonality_spectral_prominence = NaN;
        stats.spectral_signature = NaN(32, 1);
        stats.spectral_entropy = NaN;
        stats.spectral_centroid = NaN;
        stats.spectral_low_frequency_fraction = NaN;
        stats.spectral_dominant_period = NaN;
        stats.spectral_peak_prominence = NaN;
        stats.regime_change_score = NaN;
        stats.regime_multiscale_score = NaN;
        stats.regime_change_count = NaN;
        stats.regime_heterogeneity_score = NaN;
        report.regime = struct;
        report.hurst = struct;
    else
        stats.mean = mean(xValid);
        stats.std = std(xValid);
        stats.var = var(xValid);
        stats.median = median(xValid);
        stats.mad = median(abs(xValid - stats.median));
        stats.min = min(xValid);
        stats.max = max(xValid);
        stats.range = stats.max - stats.min;
        stats.outlier_fraction = gapfill.internal.outlier_fraction(xValid);

        if numel(xValid) >= 2
            stats.roughness = std(diff(xValid));
            stats.roughness_ratio = stats.roughness / max(stats.std, eps);
            stats.burstiness_index = gapfill.internal.burstiness_index(xValid);
        else
            stats.roughness = NaN;
            stats.roughness_ratio = NaN;
            stats.burstiness_index = NaN;
        end

        trend = gapfill.internal.trend_features(tValid, xValid);
        stats.trend_slope = trend.slope;
        stats.trend_intercept = trend.intercept;
        stats.trend_rsq = trend.rsq;
        stats.trend_strength = trend.strength;

        hurst = gapfill.internal.dfa_hurst(xValid);
        stats.hurst_exponent = hurst.value;
        stats.hurst_effective = min(max(hurst.value, 0), 1);
        stats.hurst_rsq = hurst.rsq;
        report.hurst = hurst;

        stats.acf = gapfill.internal.autocorrelation(xValid, opts.MaxLag);
        stats.acf_lags = (0:numel(stats.acf) - 1).';
        if numel(stats.acf) >= 2
            stats.persistence_lag1 = stats.acf(2);
        else
            stats.persistence_lag1 = NaN;
        end

        seasonalMaxLag = min(max(opts.MaxLag * 3, 24), max(6, floor(numel(xValid) / 3)));
        seasonality = gapfill.internal.seasonality_features(xValid, seasonalMaxLag);
        stats.seasonality_period = seasonality.period;
        stats.seasonality_strength = seasonality.strength;
        stats.seasonality_peak_value = seasonality.peak_value;
        stats.seasonality_spectral_period = seasonality.spectral_period;
        stats.seasonality_spectral_prominence = seasonality.spectral_prominence;

        spectrum = gapfill.internal.spectral_signature(xValid, 32);
        stats.spectral_signature = spectrum.signature;
        stats.spectral_entropy = spectrum.entropy;
        stats.spectral_centroid = spectrum.centroid;
        stats.spectral_low_frequency_fraction = spectrum.low_frequency_fraction;
        stats.spectral_dominant_period = spectrum.dominant_period;
        stats.spectral_peak_prominence = spectrum.peak_prominence;

        regime = gapfill.internal.regime_features(xValid);
        stats.regime_change_score = regime.change_score;
        stats.regime_multiscale_score = regime.multiscale_score;
        stats.regime_change_count = regime.estimated_change_count;
        stats.regime_heterogeneity_score = regime.heterogeneity_score;
        report.regime = regime;
    end

    report.stats = stats;
    report.classification = gapfill.internal.classify_series(report);
end
