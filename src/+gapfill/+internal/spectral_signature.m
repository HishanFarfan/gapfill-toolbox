function spectrum = spectral_signature(x, nBins)
%GAPFILL.INTERNAL.SPECTRAL_SIGNATURE Compact normalized spectral descriptor.

    x = double(x(:));
    x = x(~isnan(x));

    spectrum = struct( ...
        "signature", NaN(nBins, 1), ...
        "entropy", NaN, ...
        "centroid", NaN, ...
        "low_frequency_fraction", NaN, ...
        "dominant_frequency", NaN, ...
        "dominant_period", NaN, ...
        "peak_prominence", NaN);

    if numel(x) < 8
        return;
    end

    x = detrend(x, 1);
    x = x - mean(x);
    n = numel(x);
    nfft = 2 ^ nextpow2(n);
    y = fft(x, nfft);
    power = abs(y(2:floor(nfft / 2) + 1)) .^ 2;
    freq = (1:numel(power)).' / nfft;

    totalPower = sum(power);
    if totalPower <= eps
        return;
    end

    power = power / totalPower;
    xi = linspace(freq(1), freq(end), nBins).';
    signature = interp1(freq, power, xi, "linear", "extrap");
    signature = max(signature, 0);
    signature = signature / max(sum(signature), eps);

    [peakPower, peakIdx] = max(power);
    if ~isempty(peakIdx) && peakIdx >= 1 && freq(peakIdx) > 0
        dominantFrequency = freq(peakIdx);
        dominantPeriod = 1 / dominantFrequency;
    else
        dominantFrequency = NaN;
        dominantPeriod = NaN;
    end

    lowCut = max(1, floor(nBins / 3));
    spectrum.signature = signature;
    spectrum.entropy = -sum(signature .* log(signature + eps)) / log(numel(signature));
    spectrum.centroid = sum(xi .* signature);
    spectrum.low_frequency_fraction = sum(signature(1:lowCut));
    spectrum.dominant_frequency = dominantFrequency;
    spectrum.dominant_period = dominantPeriod;
    spectrum.peak_prominence = peakPower / max(median(power), eps);
end
