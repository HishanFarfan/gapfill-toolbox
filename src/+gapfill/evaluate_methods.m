function evaluation = evaluate_methods(data, varargin)
%GAPFILL.EVALUATE_METHODS Score interpolation candidates with blocked CV.

    parser = inputParser;
    parser.addParameter("Time", [], @(x) isempty(x) || isvector(x));
    parser.addParameter("Methods", {"linear", "pchip", "makima"});
    parser.addParameter("NumReplicates", 6, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    parser.addParameter("HoldoutFraction", 0.2, @(x) isnumeric(x) && isscalar(x) && x > 0 && x < 1);
    parser.addParameter("MinSegmentLength", 8, @(x) isnumeric(x) && isscalar(x) && x >= 3);
    parser.addParameter("MaxLag", 20, @(x) isnumeric(x) && isscalar(x) && x >= 1);
    parser.addParameter("Weights", [], ...
        @(x) isempty(x) || (isnumeric(x) && any(numel(x) == [4, 7])));
    parser.addParameter("Seed", 1, @(x) isnumeric(x) && isscalar(x));
    parser.parse(varargin{:});
    opts = parser.Results;

    x = double(data(:));
    n = numel(x);
    if isempty(opts.Time)
        t = (1:n).';
    else
        t = double(opts.Time(:));
        if numel(t) ~= n
            error("gapfill:evaluate_methods:TimeSizeMismatch", ...
                "Time vector must have the same length as data.");
        end
    end

    methods = gapfill.internal.filter_supported_methods(opts.Methods);
    if isempty(methods)
        error("gapfill:evaluate_methods:NoSupportedMethods", ...
            "No supported interpolation methods are available.");
    end

    profileReport = gapfill.profile(x, "Time", t, "MaxLag", opts.MaxLag);
    backend = gapfill.internal.select_backend(profileReport.classification, methods, opts.Weights);
    methods = backend.preferred_methods;
    valid = ~isnan(x);
    xValid = x(valid);
    baseAcf = gapfill.internal.autocorrelation(xValid, opts.MaxLag);
    baseRoughness = profileReport.stats.roughness;
    baseSpectrum = gapfill.internal.spectral_signature(xValid, 32);
    baseTrend = gapfill.internal.trend_features(t(valid), xValid);
    seasonalMaxLag = min(max(opts.MaxLag * 3, 24), max(6, floor(numel(xValid) / 3)));
    baseSeasonality = gapfill.internal.seasonality_features(xValid, seasonalMaxLag);

    oldRng = rng;
    cleanupObj = onCleanup(@() rng(oldRng));
    rng(opts.Seed);

    nMethods = numel(methods);
    rmseMean = NaN(nMethods, 1);
    biasMean = NaN(nMethods, 1);
    acfMean = NaN(nMethods, 1);
    roughnessMean = NaN(nMethods, 1);
    spectralMean = NaN(nMethods, 1);
    trendMean = NaN(nMethods, 1);
    seasonalMean = NaN(nMethods, 1);
    shapeMean = NaN(nMethods, 1);
    derivativeMean = NaN(nMethods, 1);
    curvatureMean = NaN(nMethods, 1);
    tvMean = NaN(nMethods, 1);
    turningPointMean = NaN(nMethods, 1);
    visualMean = NaN(nMethods, 1);
    successRate = NaN(nMethods, 1);

    for iMethod = 1:nMethods
        rmseRuns = NaN(opts.NumReplicates, 1);
        biasRuns = NaN(opts.NumReplicates, 1);
        acfRuns = NaN(opts.NumReplicates, 1);
        roughnessRuns = NaN(opts.NumReplicates, 1);
        spectralRuns = NaN(opts.NumReplicates, 1);
        trendRuns = NaN(opts.NumReplicates, 1);
        seasonalRuns = NaN(opts.NumReplicates, 1);
        shapeRuns = NaN(opts.NumReplicates, 1);
        derivativeRuns = NaN(opts.NumReplicates, 1);
        curvatureRuns = NaN(opts.NumReplicates, 1);
        tvRuns = NaN(opts.NumReplicates, 1);
        turningPointRuns = NaN(opts.NumReplicates, 1);
        visualRuns = NaN(opts.NumReplicates, 1);
        successRuns = false(opts.NumReplicates, 1);

        for iRep = 1:opts.NumReplicates
            holdout = gapfill.internal.sample_holdout_block(valid, ...
                opts.HoldoutFraction, opts.MinSegmentLength);
            if isempty(holdout)
                continue;
            end

            xTrain = x;
            xTrain(holdout) = NaN;
            xInterp = gapfill.internal.interpolate_limited(t, xTrain, methods{iMethod}, Inf);

            if any(isnan(xInterp(holdout)))
                continue;
            end

            delta = xInterp(holdout) - x(holdout);
            rmseRuns(iRep) = sqrt(mean(delta .^ 2));
            biasRuns(iRep) = abs(mean(delta));

            visualMetrics = gapfill.internal.gap_visual_metrics(x(holdout), xInterp(holdout));
            shapeRuns(iRep) = visualMetrics.shape_distance;
            derivativeRuns(iRep) = visualMetrics.derivative_distance;
            curvatureRuns(iRep) = visualMetrics.curvature_distance;
            tvRuns(iRep) = visualMetrics.tv_distance;
            turningPointRuns(iRep) = visualMetrics.turning_point_distance;
            visualRuns(iRep) = visualMetrics.visual_distance;

            xInterpValid = xInterp(valid);
            interpAcf = gapfill.internal.autocorrelation(xInterpValid, opts.MaxLag);
            acfRuns(iRep) = gapfill.internal.acf_distance(baseAcf, interpAcf);

            if numel(xInterpValid) >= 2 && ~isnan(baseRoughness)
                roughnessRuns(iRep) = abs(std(diff(xInterpValid)) - baseRoughness);
            end

            interpSpectrum = gapfill.internal.spectral_signature(xInterpValid, 32);
            spectralRuns(iRep) = gapfill.internal.spectral_distance( ...
                baseSpectrum.signature, interpSpectrum.signature);

            interpTrend = gapfill.internal.trend_features(t(valid), xInterpValid);
            trendRuns(iRep) = gapfill.internal.trend_distance(baseTrend, interpTrend);

            interpSeasonality = gapfill.internal.seasonality_features(xInterpValid, seasonalMaxLag);
            seasonalRuns(iRep) = gapfill.internal.seasonality_distance(baseSeasonality, interpSeasonality);

            successRuns(iRep) = true;
        end

        rmseMean(iMethod) = gapfill.internal.safe_stat(rmseRuns, "mean");
        biasMean(iMethod) = gapfill.internal.safe_stat(biasRuns, "mean");
        acfMean(iMethod) = gapfill.internal.safe_stat(acfRuns, "mean");
        roughnessMean(iMethod) = gapfill.internal.safe_stat(roughnessRuns, "mean");
        spectralMean(iMethod) = gapfill.internal.safe_stat(spectralRuns, "mean");
        trendMean(iMethod) = gapfill.internal.safe_stat(trendRuns, "mean");
        seasonalMean(iMethod) = gapfill.internal.safe_stat(seasonalRuns, "mean");
        shapeMean(iMethod) = gapfill.internal.safe_stat(shapeRuns, "mean");
        derivativeMean(iMethod) = gapfill.internal.safe_stat(derivativeRuns, "mean");
        curvatureMean(iMethod) = gapfill.internal.safe_stat(curvatureRuns, "mean");
        tvMean(iMethod) = gapfill.internal.safe_stat(tvRuns, "mean");
        turningPointMean(iMethod) = gapfill.internal.safe_stat(turningPointRuns, "mean");
        visualMean(iMethod) = gapfill.internal.safe_stat(visualRuns, "mean");
        successRate(iMethod) = mean(successRuns);
    end

    score = backend.weights(1) * gapfill.internal.normalize_minmax(rmseMean) + ...
        backend.weights(2) * gapfill.internal.normalize_minmax(biasMean) + ...
        backend.weights(3) * gapfill.internal.normalize_minmax(acfMean) + ...
        backend.weights(4) * gapfill.internal.normalize_minmax(roughnessMean) + ...
        backend.weights(5) * gapfill.internal.normalize_minmax(spectralMean) + ...
        backend.weights(6) * gapfill.internal.normalize_minmax(trendMean) + ...
        backend.weights(7) * gapfill.internal.normalize_minmax(seasonalMean) + ...
        backend.weights(8) * gapfill.internal.normalize_minmax(visualMean);

    penalty = 1 - successRate;
    score = score + 0.25 * penalty;

    methodColumn = methods(:);
    resultsTable = table(methodColumn, rmseMean, biasMean, acfMean, roughnessMean, ...
        spectralMean, trendMean, seasonalMean, shapeMean, derivativeMean, ...
        curvatureMean, tvMean, turningPointMean, visualMean, successRate, score, ...
        'VariableNames', {'Method', 'RMSE', 'Bias', 'ACFDistance', ...
        'RoughnessDistance', 'SpectralDistance', 'TrendDistance', ...
        'SeasonalityDistance', 'ShapeDistance', 'DerivativeDistance', ...
        'CurvatureDistance', 'TVDistance', 'TurningPointDistance', ...
        'VisualDistance', 'SuccessRate', 'Score'});
    resultsTable = sortrows(resultsTable, 'Score', 'ascend');

    evaluation = struct;
    evaluation.profile = profileReport;
    evaluation.results = resultsTable;
    evaluation.best_method = resultsTable.Method{1};
    evaluation.series_class = profileReport.classification.label;
    evaluation.classification = profileReport.classification;
    evaluation.backend = backend;
    evaluation.options = opts;

    clear cleanupObj
end
