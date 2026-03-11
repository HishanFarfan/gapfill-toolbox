function backend = select_backend(classification, availableMethods, customWeights)
%GAPFILL.INTERNAL.SELECT_BACKEND Select adaptive scoring/backend config.

    label = classification.label;
    switch label
        case 'smooth'
            defaultWeights = [0.28, 0.08, 0.10, 0.10, 0.22, 0.17, 0.05];
            preferred = {'pchip', 'makima', 'spline', 'linear'};
            gapScale = 1.30;
            gapCap = 40;
            seasonalGapFactor = 1.25;
            rollingARMaxGap = 48;
            localARMaxGap = 200;
        case 'persistent'
            defaultWeights = [0.18, 0.06, 0.25, 0.10, 0.26, 0.11, 0.04];
            preferred = {'pchip', 'makima', 'linear', 'spline'};
            gapScale = 0.90;
            gapCap = 22;
            seasonalGapFactor = 1.00;
            rollingARMaxGap = 96;
            localARMaxGap = 220;
        case 'antipersistent'
            defaultWeights = [0.24, 0.10, 0.22, 0.16, 0.16, 0.08, 0.04];
            preferred = {'linear', 'pchip', 'makima', 'spline'};
            gapScale = 0.75;
            gapCap = 14;
            seasonalGapFactor = 0.75;
            rollingARMaxGap = 40;
            localARMaxGap = 200;
        case 'seasonal'
            defaultWeights = [0.18, 0.06, 0.12, 0.08, 0.16, 0.16, 0.24];
            preferred = {'makima', 'pchip', 'linear', 'spline'};
            gapScale = 0.85;
            gapCap = 20;
            seasonalGapFactor = 2.25;
            rollingARMaxGap = 60;
            localARMaxGap = 200;
        case 'bursty'
            defaultWeights = [0.26, 0.18, 0.16, 0.16, 0.10, 0.08, 0.06];
            preferred = {'linear', 'pchip', 'makima', 'spline'};
            gapScale = 0.65;
            gapCap = 12;
            seasonalGapFactor = 0.75;
            rollingARMaxGap = 36;
            localARMaxGap = 120;
        case 'regime_switching'
            defaultWeights = [0.22, 0.10, 0.18, 0.16, 0.14, 0.16, 0.04];
            preferred = {'linear', 'pchip', 'makima', 'spline'};
            gapScale = 0.70;
            gapCap = 14;
            seasonalGapFactor = 1.25;
            rollingARMaxGap = 96;
            localARMaxGap = 140;
        otherwise
            defaultWeights = [0.25, 0.10, 0.18, 0.12, 0.18, 0.12, 0.05];
            preferred = {'linear', 'pchip', 'makima', 'spline'};
            gapScale = 1.00;
            gapCap = 25;
            seasonalGapFactor = 1.00;
            rollingARMaxGap = 64;
            localARMaxGap = 200;
    end

    if isfield(classification, 'flags') && classification.flags.has_regime_changes
        gapCap = max(8, round(0.8 * gapCap));
        rollingARMaxGap = max(rollingARMaxGap, 96);
    end
    if isfield(classification, 'flags') && classification.flags.is_multiscale
        defaultWeights(5) = defaultWeights(5) + 0.04;
        defaultWeights(6) = defaultWeights(6) + 0.03;
    end

    weights = expand_weights(customWeights, defaultWeights);
    preferredMethods = [intersect(preferred, availableMethods, 'stable'), ...
        setdiff(availableMethods, preferred, 'stable')];

    backend = struct;
    backend.label = label;
    backend.weights = weights;
    backend.weight_names = {'RMSE', 'Bias', 'ACFDistance', 'RoughnessDistance', ...
        'SpectralDistance', 'TrendDistance', 'SeasonalityDistance'};
    backend.preferred_methods = preferredMethods;
    backend.interpolation_gap_scale = gapScale;
    backend.interpolation_gap_cap = gapCap;
    backend.use_seasonal_template = strcmp(classification.primary_label, 'seasonal');
    backend.seasonal_gap_factor = seasonalGapFactor;
    backend.use_rolling_ar = true;
    backend.rolling_ar_max_gap = rollingARMaxGap;
    backend.local_ar_max_gap = localARMaxGap;
end

function weights = expand_weights(customWeights, defaultWeights)
    if isempty(customWeights)
        weights = defaultWeights;
    elseif numel(customWeights) == 7
        weights = double(customWeights(:)).';
    elseif numel(customWeights) == 4
        base = zeros(1, 7);
        base(1:4) = double(customWeights(:)).';
        residual = max(1 - sum(base), 0);
        base(5:7) = residual * defaultWeights(5:7) / max(sum(defaultWeights(5:7)), eps);
        weights = base;
    else
        error("gapfill:internal:select_backend:BadWeights", ...
            "Weights must have length 4 or 7.");
    end

    weights = max(weights, 0);
    weights = weights / max(sum(weights), eps);
end
