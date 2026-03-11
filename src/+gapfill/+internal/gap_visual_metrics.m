function metrics = gap_visual_metrics(xTrue, xPred)
%GAPFILL.INTERNAL.GAP_VISUAL_METRICS Structural similarity metrics inside a gap.

    xTrue = double(xTrue(:));
    xPred = double(xPred(:));
    mask = ~isnan(xTrue) & ~isnan(xPred);
    xTrue = xTrue(mask);
    xPred = xPred(mask);

    metrics = struct( ...
        "shape_distance", NaN, ...
        "derivative_distance", NaN, ...
        "curvature_distance", NaN, ...
        "tv_distance", NaN, ...
        "turning_point_distance", NaN, ...
        "amplitude_distance", NaN, ...
        "visual_distance", NaN);

    if numel(xTrue) < 2
        return;
    end

    metrics.shape_distance = shape_distance(xTrue, xPred);
    metrics.derivative_distance = derivative_distance(xTrue, xPred);
    metrics.tv_distance = total_variation_distance(xTrue, xPred);
    metrics.turning_point_distance = turning_point_distance(xTrue, xPred);
    metrics.amplitude_distance = amplitude_distance(xTrue, xPred);

    if numel(xTrue) >= 3
        metrics.curvature_distance = curvature_distance(xTrue, xPred);
    else
        metrics.curvature_distance = 0;
    end

    componentValues = [ ...
        metrics.shape_distance, ...
        metrics.derivative_distance, ...
        metrics.curvature_distance, ...
        metrics.tv_distance, ...
        metrics.turning_point_distance, ...
        metrics.amplitude_distance];
    componentWeights = [0.30, 0.22, 0.16, 0.14, 0.10, 0.08];
    metrics.visual_distance = nansum(componentWeights .* componentValues);
end

function d = shape_distance(xTrue, xPred)
    zTrue = zscore_safe(xTrue);
    zPred = zscore_safe(xPred);
    if numel(zTrue) < 2
        d = 0;
        return;
    end

    c = corrcoef(zTrue, zPred);
    if numel(c) < 4 || isnan(c(1, 2))
        d = 1;
    else
        d = 1 - max(min(c(1, 2), 1), -1);
    end
end

function d = derivative_distance(xTrue, xPred)
    dxTrue = diff(xTrue);
    dxPred = diff(xPred);
    scale = max(std(dxTrue), eps);
    d = sqrt(mean((dxPred - dxTrue) .^ 2)) / scale;
    d = min(d, 3);
end

function d = curvature_distance(xTrue, xPred)
    ddTrue = diff(xTrue, 2);
    ddPred = diff(xPred, 2);
    scale = max(std(ddTrue), eps);
    d = sqrt(mean((ddPred - ddTrue) .^ 2)) / scale;
    d = min(d, 3);
end

function d = total_variation_distance(xTrue, xPred)
    tvTrue = sum(abs(diff(xTrue)));
    tvPred = sum(abs(diff(xPred)));
    d = abs(tvPred - tvTrue) / max(tvTrue, eps);
    d = min(d, 3);
end

function d = turning_point_distance(xTrue, xPred)
    tpTrue = count_turning_points(xTrue);
    tpPred = count_turning_points(xPred);
    d = abs(tpPred - tpTrue) / max(tpTrue, 1);
    d = min(d, 3);
end

function d = amplitude_distance(xTrue, xPred)
    ampTrue = max(xTrue) - min(xTrue);
    ampPred = max(xPred) - min(xPred);
    d = abs(ampPred - ampTrue) / max(ampTrue, eps);
    d = min(d, 3);
end

function z = zscore_safe(x)
    x = x(:);
    scale = std(x);
    if scale <= eps
        z = zeros(size(x));
    else
        z = (x - mean(x)) / scale;
    end
end

function n = count_turning_points(x)
    dx = diff(x);
    s = sign(dx);
    s(s == 0) = [];
    if numel(s) < 2
        n = 0;
        return;
    end
    n = sum(diff(s) ~= 0);
end
