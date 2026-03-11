function info = seasonality_features(x, maxLag)
%GAPFILL.INTERNAL.SEASONALITY_FEATURES Estimate simple periodicity features from ACF.

    x = double(x(:));
    x = x(~isnan(x));

    info = struct( ...
        "period", NaN, ...
        "strength", NaN, ...
        "peak_value", NaN, ...
        "spectral_period", NaN, ...
        "spectral_prominence", NaN, ...
        "acf", NaN(maxLag + 1, 1));

    if numel(x) < 6 || maxLag < 2
        return;
    end

    maxLag = min(maxLag, numel(x) - 1);
    acf = gapfill.internal.autocorrelation(x, maxLag);
    info.acf = acf;

    spectrum = gapfill.internal.spectral_signature(x, 32);
    info.spectral_period = spectrum.dominant_period;
    info.spectral_prominence = spectrum.peak_prominence;

    candidatePeriod = round(spectrum.dominant_period);
    if ~isnan(candidatePeriod) && candidatePeriod >= 4 && candidatePeriod <= maxLag
        peakValue = acf(candidatePeriod + 1);
        info.period = candidatePeriod;
        info.peak_value = peakValue;
        info.strength = 0.6 * max(0, log10(max(spectrum.peak_prominence, 1))) + ...
            0.4 * max(0, peakValue);
        return;
    end

    searchIdx = 5:numel(acf);
    if isempty(searchIdx)
        info.strength = 0;
        return;
    end

    acfSearch = acf(searchIdx);
    [peakValue, localIdx] = max(acfSearch);
    lag = searchIdx(localIdx) - 1;

    if isempty(peakValue) || isnan(peakValue) || peakValue <= 0
        info.period = NaN;
        info.strength = 0;
        info.peak_value = peakValue;
        return;
    end

    info.period = lag;
    info.peak_value = peakValue;
    info.strength = max(0, peakValue);
end
