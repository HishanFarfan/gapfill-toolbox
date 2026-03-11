function [xFilled, report] = rolling_ar_fill(x, varargin)
%GAPFILL.INTERNAL.ROLLING_AR_FILL Fill gaps using deterministic rolling AR forecasts.

    parser = inputParser;
    parser.addParameter("Window", 150, @(v) isnumeric(v) && isscalar(v) && v >= 5);
    parser.addParameter("MaxOrder", 10, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("MinGapLength", 4, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("MaxGapLength", 80, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.parse(varargin{:});
    opts = parser.Results;

    xFilled = double(x(:));
    missing = isnan(xFilled);
    [gapStarts, gapEnds, gapLengths] = gapfill.internal.find_gaps(missing);

    filledStarts = [];
    filledEnds = [];
    filledLengths = [];

    for i = 1:numel(gapLengths)
        gapLength = gapLengths(i);
        if gapLength < opts.MinGapLength || gapLength > opts.MaxGapLength
            continue;
        end

        gapStart = gapStarts(i);
        gapEnd = gapEnds(i);
        if gapStart == 1 || gapEnd == numel(xFilled)
            continue;
        end

        leftBase = xFilled(max(1, gapStart - opts.Window):gapStart - 1);
        rightBase = xFilled(gapEnd + 1:min(numel(xFilled), gapEnd + opts.Window));
        leftBase = leftBase(~isnan(leftBase));
        rightBase = rightBase(~isnan(rightBase));

        if numel(leftBase) < 6 && numel(rightBase) < 6
            continue;
        end

        leftForecast = build_path(leftBase, gapLength, opts.Window, opts.MaxOrder);
        rightForecast = flipud(build_path(flipud(rightBase), gapLength, opts.Window, opts.MaxOrder));

        if all(isnan(leftForecast)) && all(isnan(rightForecast))
            continue;
        elseif any(~isnan(leftForecast)) && any(~isnan(rightForecast))
            weights = linspace(0, 1, gapLength).';
            gapValues = (1 - weights) .* leftForecast + weights .* rightForecast;
        elseif any(~isnan(leftForecast))
            gapValues = leftForecast;
        else
            gapValues = rightForecast;
        end

        xFilled(gapStart:gapEnd) = gapValues;
        filledStarts(end + 1, 1) = gapStart; %#ok<AGROW>
        filledEnds(end + 1, 1) = gapEnd; %#ok<AGROW>
        filledLengths(end + 1, 1) = gapLength; %#ok<AGROW>
    end

    report = struct;
    report.filled_gap_starts = filledStarts;
    report.filled_gap_ends = filledEnds;
    report.filled_gap_lengths = filledLengths;
    report.n_filled_gaps = numel(filledLengths);
end

function path = build_path(baseContext, gapLength, window, maxOrder)
    path = NaN(gapLength, 1);
    history = baseContext(:);
    for k = 1:gapLength
        localContext = history(max(1, end - window + 1):end);
        model = gapfill.internal.fit_local_ar(localContext, maxOrder);
        prediction = gapfill.internal.predict_ar_step(model, localContext);
        if isnan(prediction)
            return;
        end
        path(k) = prediction;
        history(end + 1, 1) = prediction; %#ok<AGROW>
    end
end
