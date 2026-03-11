function [xFilled, report] = local_ar_fill(x, varargin)
%GAPFILL.INTERNAL.LOCAL_AR_FILL Fill internal gaps with local AR simulation.

    parser = inputParser;
    parser.addParameter("Window", 150, @(v) isnumeric(v) && isscalar(v) && v >= 5);
    parser.addParameter("MaxOrder", 12, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("MinGapLength", 4, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("MaxGapLength", 200, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("Seed", 1, @(v) isnumeric(v) && isscalar(v));
    parser.parse(varargin{:});
    opts = parser.Results;

    oldRng = rng;
    cleanupObj = onCleanup(@() rng(oldRng));
    rng(opts.Seed);

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

        leftIdx = max(1, gapStart - opts.Window):gapStart - 1;
        rightIdx = gapEnd + 1:min(numel(xFilled), gapEnd + opts.Window);

        leftContext = xFilled(leftIdx);
        rightContext = xFilled(rightIdx);
        leftContext = leftContext(~isnan(leftContext));
        rightContext = rightContext(~isnan(rightContext));

        leftModel = gapfill.internal.fit_local_ar(leftContext, opts.MaxOrder);
        rightModel = gapfill.internal.fit_local_ar(flipud(rightContext), opts.MaxOrder);

        leftFill = NaN(gapLength, 1);
        rightFill = NaN(gapLength, 1);

        if leftModel.is_valid
            leftFill = gapfill.internal.simulate_ar(leftModel, leftContext, gapLength);
        end
        if rightModel.is_valid
            rightFill = flipud(gapfill.internal.simulate_ar(rightModel, flipud(rightContext), gapLength));
        end

        if all(isnan(leftFill)) && all(isnan(rightFill))
            continue;
        elseif any(~isnan(leftFill)) && any(~isnan(rightFill))
            weights = linspace(0, 1, gapLength).';
            gapValues = (1 - weights) .* leftFill + weights .* rightFill;
        elseif any(~isnan(leftFill))
            gapValues = leftFill;
        else
            gapValues = rightFill;
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

    clear cleanupObj
end
