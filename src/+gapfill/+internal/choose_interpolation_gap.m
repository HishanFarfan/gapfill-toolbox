function maxGapLength = choose_interpolation_gap(gapLengths, seriesClass, profileReport, backend)
%GAPFILL.INTERNAL.CHOOSE_INTERPOLATION_GAP Heuristic threshold for interpolation.

    gapLengths = double(gapLengths(:));
    gapLengths = gapLengths(~isnan(gapLengths));
    if isempty(gapLengths)
        maxGapLength = 0;
        return;
    end

    if nargin < 2 || isempty(seriesClass)
        seriesClass = 'persistent';
    end
    if nargin < 3
        profileReport = struct;
    end
    if nargin < 4
        backend = struct;
    end

    maxGapLength = round(median(gapLengths) + 0.5 * std(gapLengths));
    maxGapLength = max(maxGapLength, min(max(gapLengths), 3));

    gapScale = 1.0;
    gapCap = 25;
    if isfield(backend, 'interpolation_gap_scale')
        gapScale = backend.interpolation_gap_scale;
    end
    if isfield(backend, 'interpolation_gap_cap')
        gapCap = backend.interpolation_gap_cap;
    end

    switch seriesClass
        case 'smooth'
            gapScale = max(gapScale, 1.20);
        case 'seasonal'
            gapScale = min(gapScale, 0.90);
        case {'persistent', 'antipersistent'}
            gapScale = min(gapScale, 0.40);
        case 'bursty'
            gapScale = min(gapScale, 0.70);
        case 'regime_switching'
            gapScale = min(gapScale, 0.35);
        otherwise
    end

    maxGapLength = min(round(maxGapLength * gapScale), gapCap);

    if isfield(profileReport, 'stats') && isfield(profileReport.stats, 'seasonality_period')
        period = profileReport.stats.seasonality_period;
        if strcmp(seriesClass, 'seasonal') && ~isnan(period)
            maxGapLength = min(maxGapLength, max(3, floor(period / 3)));
        end
    end

    if isfield(profileReport, 'classification') && isfield(profileReport.classification, 'flags')
        if strcmp(seriesClass, 'regime_switching') && profileReport.classification.flags.has_regime_changes
            maxGapLength = min(maxGapLength, max(2, floor(0.55 * maxGapLength)));
        end
        if strcmp(seriesClass, 'regime_switching') && profileReport.classification.flags.is_multiscale
            maxGapLength = min(maxGapLength, max(2, floor(0.75 * maxGapLength)));
        end
        if strcmp(seriesClass, 'persistent')
            maxGapLength = min(maxGapLength, 3);
        end
    end

    maxGapLength = max(maxGapLength, 1);
end
