function hurst = dfa_hurst(x, varargin)
%GAPFILL.INTERNAL.DFA_HURST Estimate the Hurst exponent with simple DFA.

    parser = inputParser;
    parser.addParameter("Order", 1, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("MinScale", 8, @(v) isnumeric(v) && isscalar(v) && v >= 4);
    parser.addParameter("NumScales", 12, @(v) isnumeric(v) && isscalar(v) && v >= 4);
    parser.parse(varargin{:});
    opts = parser.Results;

    x = double(x(:));
    x = x(~isnan(x));

    hurst = struct( ...
        "value", NaN, ...
        "rsq", NaN, ...
        "scales", NaN, ...
        "fluctuations", NaN, ...
        "slope", NaN, ...
        "intercept", NaN);

    n = numel(x);
    if n < max(32, 4 * opts.MinScale)
        return;
    end

    x = x - mean(x);
    profile = cumsum(x);

    maxScale = floor(n / 4);
    if maxScale <= opts.MinScale
        return;
    end

    exponents = linspace(log2(opts.MinScale), log2(maxScale), opts.NumScales);
    scales = unique(max(4, round(2 .^ exponents)));

    fluct = NaN(numel(scales), 1);
    for i = 1:numel(scales)
        s = scales(i);
        nSeg = floor(n / s);
        if nSeg < 2
            continue;
        end

        rmsValues = NaN(2 * nSeg, 1);
        for direction = 1:2
            if direction == 1
                y = profile;
            else
                y = flipud(profile);
            end

            for seg = 1:nSeg
                idx = (seg - 1) * s + (1:s);
                localX = (1:s).';
                coeffs = polyfit(localX, y(idx), opts.Order);
                trend = polyval(coeffs, localX);
                residual = y(idx) - trend;
                rmsValues((direction - 1) * nSeg + seg) = sqrt(mean(residual .^ 2));
            end
        end

        fluct(i) = sqrt(mean(rmsValues .^ 2, 'omitnan'));
    end

    mask = ~isnan(fluct) & fluct > 0;
    if sum(mask) < 4
        return;
    end

    xFit = log2(scales(mask));
    xFit = xFit(:);
    yFit = log2(fluct(mask));
    yFit = yFit(:);
    coeffs = polyfit(xFit, yFit, 1);
    fitted = polyval(coeffs, xFit);
    fitted = fitted(:);

    ssTot = sum((yFit - mean(yFit)) .^ 2);
    ssRes = sum((yFit - fitted) .^ 2);
    if ssTot <= eps
        rsq = NaN;
    else
        rsq = 1 - ssRes / ssTot;
    end

    hurst.value = coeffs(1);
    hurst.rsq = rsq;
    hurst.scales = scales(mask);
    hurst.fluctuations = fluct(mask);
    hurst.slope = coeffs(1);
    hurst.intercept = coeffs(2);
end
