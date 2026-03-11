function backend = select_backend(classification, availableMethods, customWeights)
%GAPFILL.INTERNAL.SELECT_BACKEND Select adaptive scoring/backend config.

    label = classification.label;
    switch label
        case 'smooth'
            defaultWeights = [0.22, 0.06, 0.08, 0.08, 0.18, 0.14, 0.04, 0.20];
            preferred = {'pchip', 'makima', 'linear', 'spline'};
            gapScale = 1.30;
            gapCap = 40;
            seasonalGapFactor = 1.25;
            contextWindow = 20;
            contextMatchMaxGap = 28;
            contextMatchTopK = 2;
            contextMatchScoreCap = 0.85;
            roughnessWindow = 0;
            roughnessMaxGap = 0;
            roughnessTopK = 0;
            roughnessScoreCap = 0;
            waveletWindow = 0;
            waveletMaxGap = 0;
            waveletTopK = 0;
            waveletScoreCap = 0;
            multiscaleWindow = 0;
            multiscaleMaxGap = 0;
            multiscaleTopK = 0;
            multiscaleScoreCap = 0;
            rollingARMaxGap = 48;
            localARMaxGap = 200;
        case 'persistent'
            defaultWeights = [0.20, 0.06, 0.18, 0.06, 0.18, 0.10, 0.02, 0.20];
            preferred = {'linear', 'pchip', 'makima'};
            gapScale = 1.20;
            gapCap = 36;
            seasonalGapFactor = 1.00;
            contextWindow = 26;
            contextMatchMaxGap = 84;
            contextMatchTopK = 4;
            contextMatchScoreCap = 0.90;
            roughnessWindow = 52;
            roughnessMaxGap = 84;
            roughnessTopK = 4;
            roughnessScoreCap = 0.92;
            waveletWindow = 64;
            waveletMaxGap = 96;
            waveletTopK = 4;
            waveletScoreCap = 0.78;
            multiscaleWindow = 0;
            multiscaleMaxGap = 0;
            multiscaleTopK = 0;
            multiscaleScoreCap = 0;
            rollingARMaxGap = 0;
            localARMaxGap = 220;
        case 'antipersistent'
            defaultWeights = [0.18, 0.08, 0.18, 0.16, 0.12, 0.06, 0.02, 0.20];
            preferred = {'linear', 'pchip', 'makima'};
            gapScale = 0.75;
            gapCap = 14;
            seasonalGapFactor = 0.75;
            contextWindow = 16;
            contextMatchMaxGap = 28;
            contextMatchTopK = 2;
            contextMatchScoreCap = 0.85;
            roughnessWindow = 36;
            roughnessMaxGap = 40;
            roughnessTopK = 3;
            roughnessScoreCap = 0.88;
            waveletWindow = 0;
            waveletMaxGap = 0;
            waveletTopK = 0;
            waveletScoreCap = 0;
            multiscaleWindow = 0;
            multiscaleMaxGap = 0;
            multiscaleTopK = 0;
            multiscaleScoreCap = 0;
            rollingARMaxGap = 40;
            localARMaxGap = 200;
        case 'seasonal'
            defaultWeights = [0.14, 0.05, 0.08, 0.06, 0.12, 0.12, 0.18, 0.25];
            preferred = {'makima', 'pchip', 'linear'};
            gapScale = 0.85;
            gapCap = 20;
            seasonalGapFactor = 2.25;
            contextWindow = 24;
            contextMatchMaxGap = 72;
            contextMatchTopK = 3;
            contextMatchScoreCap = 0.90;
            roughnessWindow = 0;
            roughnessMaxGap = 0;
            roughnessTopK = 0;
            roughnessScoreCap = 0;
            waveletWindow = 0;
            waveletMaxGap = 0;
            waveletTopK = 0;
            waveletScoreCap = 0;
            multiscaleWindow = 0;
            multiscaleMaxGap = 0;
            multiscaleTopK = 0;
            multiscaleScoreCap = 0;
            rollingARMaxGap = 60;
            localARMaxGap = 200;
        case 'bursty'
            defaultWeights = [0.18, 0.14, 0.12, 0.14, 0.08, 0.06, 0.03, 0.25];
            preferred = {'linear', 'pchip', 'makima'};
            gapScale = 0.65;
            gapCap = 12;
            seasonalGapFactor = 0.75;
            contextWindow = 18;
            contextMatchMaxGap = 36;
            contextMatchTopK = 3;
            contextMatchScoreCap = 0.95;
            roughnessWindow = 40;
            roughnessMaxGap = 48;
            roughnessTopK = 3;
            roughnessScoreCap = 0.88;
            waveletWindow = 0;
            waveletMaxGap = 0;
            waveletTopK = 0;
            waveletScoreCap = 0;
            multiscaleWindow = 0;
            multiscaleMaxGap = 0;
            multiscaleTopK = 0;
            multiscaleScoreCap = 0;
            rollingARMaxGap = 36;
            localARMaxGap = 120;
        case 'regime_switching'
            defaultWeights = [0.16, 0.08, 0.12, 0.12, 0.10, 0.10, 0.02, 0.30];
            preferred = {'linear', 'pchip', 'makima'};
            gapScale = 0.70;
            gapCap = 14;
            seasonalGapFactor = 1.25;
            contextWindow = 22;
            contextMatchMaxGap = 72;
            contextMatchTopK = 4;
            contextMatchScoreCap = 0.88;
            roughnessWindow = 48;
            roughnessMaxGap = 72;
            roughnessTopK = 4;
            roughnessScoreCap = 0.86;
            waveletWindow = 0;
            waveletMaxGap = 0;
            waveletTopK = 0;
            waveletScoreCap = 0;
            multiscaleWindow = 0;
            multiscaleMaxGap = 0;
            multiscaleTopK = 0;
            multiscaleScoreCap = 0;
            rollingARMaxGap = 96;
            localARMaxGap = 140;
        otherwise
            defaultWeights = [0.18, 0.08, 0.14, 0.10, 0.14, 0.10, 0.03, 0.23];
            preferred = {'linear', 'pchip', 'makima'};
            gapScale = 1.00;
            gapCap = 25;
            seasonalGapFactor = 1.00;
            contextWindow = 20;
            contextMatchMaxGap = 28;
            contextMatchTopK = 2;
            contextMatchScoreCap = 0.85;
            roughnessWindow = 0;
            roughnessMaxGap = 0;
            roughnessTopK = 0;
            roughnessScoreCap = 0;
            waveletWindow = 0;
            waveletMaxGap = 0;
            waveletTopK = 0;
            waveletScoreCap = 0;
            multiscaleWindow = 0;
            multiscaleMaxGap = 0;
            multiscaleTopK = 0;
            multiscaleScoreCap = 0;
            rollingARMaxGap = 64;
            localARMaxGap = 200;
    end

    if isfield(classification, 'flags') && classification.flags.has_regime_changes
        gapCap = max(8, round(0.8 * gapCap));
        contextMatchMaxGap = max(contextMatchMaxGap, 64);
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
        'SpectralDistance', 'TrendDistance', 'SeasonalityDistance', 'VisualDistance'};
    backend.preferred_methods = preferredMethods;
    backend.interpolation_gap_scale = gapScale;
    backend.interpolation_gap_cap = gapCap;
    backend.use_seasonal_template = strcmp(classification.primary_label, 'seasonal');
    backend.seasonal_gap_factor = seasonalGapFactor;
    backend.use_context_match = contextMatchMaxGap > 0;
    backend.context_window = contextWindow;
    backend.context_match_max_gap = contextMatchMaxGap;
    backend.context_match_top_k = contextMatchTopK;
    backend.context_match_score_cap = contextMatchScoreCap;
    backend.use_roughness_bridge = roughnessMaxGap > 0;
    backend.roughness_window = roughnessWindow;
    backend.roughness_max_gap = roughnessMaxGap;
    backend.roughness_top_k = roughnessTopK;
    backend.roughness_score_cap = roughnessScoreCap;
    backend.use_wavelet_context = waveletMaxGap > 0;
    backend.wavelet_window = waveletWindow;
    backend.wavelet_max_gap = waveletMaxGap;
    backend.wavelet_top_k = waveletTopK;
    backend.wavelet_score_cap = waveletScoreCap;
    backend.use_multiscale_context = multiscaleMaxGap > 0;
    backend.multiscale_window = multiscaleWindow;
    backend.multiscale_max_gap = multiscaleMaxGap;
    backend.multiscale_top_k = multiscaleTopK;
    backend.multiscale_score_cap = multiscaleScoreCap;
    backend.use_rolling_ar = rollingARMaxGap > 0;
    backend.rolling_ar_max_gap = rollingARMaxGap;
    backend.local_ar_max_gap = localARMaxGap;
end

function weights = expand_weights(customWeights, defaultWeights)
    if isempty(customWeights)
        weights = defaultWeights;
    elseif numel(customWeights) == 8
        weights = double(customWeights(:)).';
    elseif numel(customWeights) == 4
        base = zeros(1, 8);
        base(1:4) = double(customWeights(:)).';
        residual = max(1 - sum(base), 0);
        base(5:8) = residual * defaultWeights(5:8) / max(sum(defaultWeights(5:8)), eps);
        weights = base;
    elseif numel(customWeights) == 7
        base = [double(customWeights(:)).', 0];
        residual = max(1 - sum(base), 0);
        base(8) = residual;
        weights = base;
    else
        error("gapfill:internal:select_backend:BadWeights", ...
            "Weights must have length 4, 7, or 8.");
    end

    weights = max(weights, 0);
    weights = weights / max(sum(weights), eps);
end
