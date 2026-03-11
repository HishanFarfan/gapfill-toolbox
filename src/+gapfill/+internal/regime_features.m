function info = regime_features(x)
%GAPFILL.INTERNAL.REGIME_FEATURES Estimate change-of-regime and multiscale structure.

    x = double(x(:));
    x = x(~isnan(x));

    info = struct( ...
        "window_lengths", NaN, ...
        "change_score", NaN, ...
        "mean_shift_score", NaN, ...
        "variance_shift_score", NaN, ...
        "roughness_shift_score", NaN, ...
        "multiscale_score", NaN, ...
        "estimated_change_count", NaN, ...
        "heterogeneity_score", NaN);

    n = numel(x);
    if n < 24
        return;
    end

    windowLengths = unique(max(8, round([n / 20, n / 12, n / 8])));
    scaleScores = NaN(numel(windowLengths), 1);
    changeCounts = NaN(numel(windowLengths), 1);
    meanScores = NaN(numel(windowLengths), 1);
    varScores = NaN(numel(windowLengths), 1);
    roughScores = NaN(numel(windowLengths), 1);

    seriesScale = max(std(x), eps);
    diffScale = max(std(diff(x)), eps);

    for i = 1:numel(windowLengths)
        w = windowLengths(i);
        if n < 2 * w + 2
            continue;
        end

        rollMean = movmean(x, w, 'Endpoints', 'discard');
        rollStd = movstd(x, w, 0, 'Endpoints', 'discard');
        rollDiff = movstd(diff(x), max(w - 1, 2), 0, 'Endpoints', 'discard');

        meanDelta = abs(diff(rollMean));
        stdDelta = abs(diff(rollStd));
        roughDelta = abs(diff(rollDiff));

        meanScore = mean(meanDelta) / seriesScale;
        varScore = mean(stdDelta) / seriesScale;
        roughScore = mean(roughDelta) / diffScale;

        combined = normalize_vector(meanDelta) + normalize_vector(stdDelta) + normalize_vector(roughDelta);
        threshold = mean(combined) + std(combined);
        changeCounts(i) = sum(combined > threshold);

        meanScores(i) = meanScore;
        varScores(i) = varScore;
        roughScores(i) = roughScore;
        scaleScores(i) = 0.45 * meanScore + 0.30 * varScore + 0.25 * roughScore;
    end

    info.window_lengths = windowLengths(:);
    info.change_score = mean(scaleScores, 'omitnan');
    info.mean_shift_score = mean(meanScores, 'omitnan');
    info.variance_shift_score = mean(varScores, 'omitnan');
    info.roughness_shift_score = mean(roughScores, 'omitnan');
    info.multiscale_score = std(scaleScores, 'omitnan');
    info.estimated_change_count = round(mean(changeCounts, 'omitnan'));
    info.heterogeneity_score = info.change_score + 0.5 * info.multiscale_score;
end

function y = normalize_vector(x)
    x = x(:);
    if isempty(x) || all(x == 0)
        y = zeros(size(x));
        return;
    end
    xmin = min(x);
    xmax = max(x);
    if xmax == xmin
        y = zeros(size(x));
    else
        y = (x - xmin) / (xmax - xmin);
    end
end
