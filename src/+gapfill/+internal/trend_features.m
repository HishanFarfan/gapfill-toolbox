function trend = trend_features(t, x)
%GAPFILL.INTERNAL.TREND_FEATURES Estimate linear trend descriptors.

    t = double(t(:));
    x = double(x(:));
    mask = ~isnan(t) & ~isnan(x);
    t = t(mask);
    x = x(mask);

    trend = struct( ...
        "slope", NaN, ...
        "intercept", NaN, ...
        "rsq", NaN, ...
        "strength", NaN, ...
        "span", NaN, ...
        "scale", NaN);

    if numel(x) < 2
        return;
    end

    coeffs = polyfit(t, x, 1);
    yfit = polyval(coeffs, t);
    ssTot = sum((x - mean(x)) .^ 2);
    ssRes = sum((x - yfit) .^ 2);
    if ssTot <= eps
        rsq = NaN;
    else
        rsq = 1 - ssRes / ssTot;
    end

    span = max(t) - min(t);
    scale = std(x);
    strength = abs(coeffs(1)) * max(span, 1) / max(scale, eps);

    trend.slope = coeffs(1);
    trend.intercept = coeffs(2);
    trend.rsq = rsq;
    trend.strength = strength;
    trend.span = span;
    trend.scale = scale;
end
