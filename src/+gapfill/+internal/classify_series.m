function classification = classify_series(profileReport)
%GAPFILL.INTERNAL.CLASSIFY_SERIES Assign a coarse structural class to a series.

    stats = profileReport.stats;

    scores = struct;
    scores.smooth = max(0, 1 - min(gapfill.internal.nan_to_zero(stats.roughness_ratio), 2) / 2) + ...
        max(0, 1 - min(8 * gapfill.internal.nan_to_zero(stats.outlier_fraction), 1));
    scores.persistent = max(0, gapfill.internal.nan_to_zero(stats.persistence_lag1)) + ...
        max(0, gapfill.internal.nan_to_zero(stats.spectral_low_frequency_fraction) - 0.35);
    scores.seasonal = gapfill.internal.nan_to_zero(stats.seasonality_strength) + ...
        0.5 * double(~isnan(stats.seasonality_period) && stats.seasonality_period >= 3) + ...
        0.2 * min(gapfill.internal.nan_to_zero(stats.trend_rsq), 1);
    scores.bursty = min(gapfill.internal.nan_to_zero(stats.burstiness_index), 2) + ...
        min(10 * gapfill.internal.nan_to_zero(stats.outlier_fraction), 1);
    scores.regime_switching = gapfill.internal.nan_to_zero(stats.regime_change_score) + ...
        0.6 * gapfill.internal.nan_to_zero(stats.regime_multiscale_score) + ...
        0.15 * min(gapfill.internal.nan_to_zero(stats.regime_change_count), 5);

    baseLabels = {'smooth', 'persistent', 'seasonal', 'bursty'};
    baseVector = [scores.smooth, scores.persistent, scores.seasonal, scores.bursty];
    [baseWinner, idx] = max(baseVector);
    baseLabel = baseLabels{idx};

    hasRegimeChanges = gapfill.internal.nan_to_zero(stats.regime_change_score) > 0.12 || ...
        gapfill.internal.nan_to_zero(stats.regime_change_count) >= 2;
    isMultiscale = gapfill.internal.nan_to_zero(stats.regime_multiscale_score) > 0.035;

    label = baseLabel;
    secondaryLabel = '';
    if hasRegimeChanges
        secondaryLabel = 'regime_switching';
        if ~strcmp(baseLabel, 'seasonal') && ...
                (scores.regime_switching >= 0.75 * baseWinner || ...
                gapfill.internal.nan_to_zero(stats.regime_change_count) >= 2)
            label = 'regime_switching';
        end
    end

    if strcmp(label, 'regime_switching')
        winner = scores.regime_switching;
        totalScore = sum(baseVector) + scores.regime_switching;
    else
        winner = baseWinner;
        totalScore = sum(baseVector) + 0.5 * scores.regime_switching;
    end
    confidence = winner / max(totalScore + eps, eps);

    classification = struct;
    classification.label = label;
    classification.primary_label = baseLabel;
    classification.secondary_label = secondaryLabel;
    classification.confidence = confidence;
    classification.scores = scores;
    classification.flags = struct( ...
        'has_regime_changes', hasRegimeChanges, ...
        'is_multiscale', isMultiscale);
end
