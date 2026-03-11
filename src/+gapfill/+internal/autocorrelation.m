function acf = autocorrelation(x, maxLag)
%GAPFILL.INTERNAL.AUTOCORRELATION Normalized autocorrelation for lags 0:maxLag.

    x = double(x(:));
    x = x(~isnan(x));

    if isempty(x)
        acf = NaN(maxLag + 1, 1);
        return;
    end

    x = x - mean(x);
    denom = sum(x .^ 2);
    if denom <= eps
        acf = NaN(maxLag + 1, 1);
        acf(1) = 1;
        return;
    end

    actualMaxLag = min(maxLag, numel(x) - 1);
    acf = NaN(maxLag + 1, 1);
    acf(1) = 1;

    for lag = 1:actualMaxLag
        acf(lag + 1) = sum(x(1 + lag:end) .* x(1:end - lag)) / denom;
    end
end
