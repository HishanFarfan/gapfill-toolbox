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

    windowLengths = unique(max(16, round([n / 10, n / 8, n / 6])));
    scaleScores = NaN(numel(windowLengths), 1);
    changeCounts = NaN(numel(windowLengths), 1);
    meanScores = NaN(numel(windowLengths), 1);
    varScores = NaN(numel(windowLengths), 1);
    roughScores = NaN(numel(windowLengths), 1);
    heterogeneityScores = NaN(numel(windowLengths), 1);

    seriesScale = max(std(x), eps);
    diffScale = max(std(diff(x)), eps);

    for i = 1:numel(windowLengths)
        w = windowLengths(i);
        nBlocks = floor(n / w);
        if nBlocks < 3
            continue;
        end

        usable = x(1:nBlocks * w);
        blocks = reshape(usable, w, nBlocks);
        blockMeans = mean(blocks, 1).';
        blockStds = std(blocks, 0, 1).';
        blockRough = NaN(nBlocks, 1);
        for b = 1:nBlocks
            blockRough(b) = std(diff(blocks(:, b)));
        end

        meanDelta = abs(diff(blockMeans));
        stdDelta = abs(diff(blockStds));
        roughDelta = abs(diff(blockRough));

        meanScore = mean(meanDelta) / seriesScale;
        varScore = mean(stdDelta) / seriesScale;
        roughScore = mean(roughDelta) / diffScale;
        heterogeneityScore = std(blockMeans) / seriesScale + 0.5 * std(blockStds) / seriesScale;

        combined = meanDelta / seriesScale + 0.5 * stdDelta / seriesScale;
        threshold = mean(combined) + 0.75 * std(combined);
        changeCounts(i) = sum(combined > threshold);

        meanScores(i) = meanScore;
        varScores(i) = varScore;
        roughScores(i) = roughScore;
        heterogeneityScores(i) = heterogeneityScore;
        scaleScores(i) = 0.35 * meanScore + 0.20 * varScore + 0.15 * roughScore + 0.30 * heterogeneityScore;
    end

    info.window_lengths = windowLengths(:);
    info.change_score = mean(scaleScores, 'omitnan');
    info.mean_shift_score = mean(meanScores, 'omitnan');
    info.variance_shift_score = mean(varScores, 'omitnan');
    info.roughness_shift_score = mean(roughScores, 'omitnan');
    info.multiscale_score = std(scaleScores, 'omitnan');
    info.estimated_change_count = round(mean(changeCounts, 'omitnan'));
    info.heterogeneity_score = mean(heterogeneityScores, 'omitnan');
end
