function [xFilled, report] = context_match_fill(x, varargin)
%GAPFILL.INTERNAL.CONTEXT_MATCH_FILL Fill gaps with matched patches from the same series.

    parser = inputParser;
    parser.addParameter("Window", 24, @(v) isnumeric(v) && isscalar(v) && v >= 4);
    parser.addParameter("MinGapLength", 4, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("MaxGapLength", 80, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("TopK", 3, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("ObservedMask", [], @(v) isempty(v) || islogical(v) || isnumeric(v));
    parser.addParameter("MaxScore", 1.25, @(v) isnumeric(v) && isscalar(v) && v > 0);
    parser.addParameter("ScaleBounds", [0.35, 2.85], ...
        @(v) isnumeric(v) && numel(v) == 2 && all(isfinite(v)) && v(1) > 0 && v(2) >= v(1));
    parser.addParameter("BridgeWeight", 0.12, @(v) isnumeric(v) && isscalar(v) && v >= 0 && v <= 1);
    parser.parse(varargin{:});
    opts = parser.Results;

    xFilled = double(x(:));
    n = numel(xFilled);
    if isempty(opts.ObservedMask)
        observedMask = ~isnan(xFilled);
    else
        observedMask = logical(opts.ObservedMask(:));
        if numel(observedMask) ~= n
            error("gapfill:internal:context_match_fill:ObservedMaskSizeMismatch", ...
                "ObservedMask must have the same length as x.");
        end
    end

    missing = isnan(xFilled);
    [gapStarts, gapEnds, gapLengths] = gapfill.internal.find_gaps(missing);

    filledStarts = zeros(0, 1);
    filledEnds = zeros(0, 1);
    filledLengths = zeros(0, 1);
    bestScores = zeros(0, 1);
    bestCandidateStarts = zeros(0, 1);
    nCandidatesUsed = zeros(0, 1);

    for iGap = 1:numel(gapLengths)
        gapLength = gapLengths(iGap);
        if gapLength < opts.MinGapLength || gapLength > opts.MaxGapLength
            continue;
        end

        gapStart = gapStarts(iGap);
        gapEnd = gapEnds(iGap);

        if gapStart <= 2 || gapEnd >= n - 1
            continue;
        end

        contextWindow = min([opts.Window, gapStart - 1, n - gapEnd]);
        if contextWindow < 4
            continue;
        end

        targetLeft = xFilled(gapStart - contextWindow:gapStart - 1);
        targetRight = xFilled(gapEnd + 1:gapEnd + contextWindow);
        if any(isnan(targetLeft)) || any(isnan(targetRight))
            continue;
        end

        targetScale = max(std([targetLeft; targetRight], 0, 1), 1e-6);
        edgeBridge = bridge_profile(targetLeft(end), targetRight(1), gapLength);

        candidateValues = zeros(gapLength, 0);
        candidateScores = zeros(0, 1);
        candidateStarts = zeros(0, 1);

        firstCandidateStart = contextWindow + 1;
        lastCandidateStart = n - contextWindow - gapLength + 1;

        for candidateStart = firstCandidateStart:lastCandidateStart
            candidateEnd = candidateStart + gapLength - 1;
            region = candidateStart - contextWindow:candidateEnd + contextWindow;
            if any(~observedMask(region))
                continue;
            end

            candidateLeft = xFilled(candidateStart - contextWindow:candidateStart - 1);
            candidateBlock = xFilled(candidateStart:candidateEnd);
            candidateRight = xFilled(candidateEnd + 1:candidateEnd + contextWindow);
            if any(isnan(candidateLeft)) || any(isnan(candidateBlock)) || any(isnan(candidateRight))
                continue;
            end

            [transformedBlock, score, scale] = score_candidate( ...
                targetLeft, targetRight, candidateLeft, candidateBlock, candidateRight, ...
                targetScale, opts.ScaleBounds);
            if isnan(score) || score > opts.MaxScore
                continue;
            end

            transformedBlock = (1 - opts.BridgeWeight) * transformedBlock + ...
                opts.BridgeWeight * edgeBridge;

            candidateValues(:, end + 1) = transformedBlock; %#ok<AGROW>
            candidateScores(end + 1, 1) = score + 0.015 * abs(log(max(scale, 1e-6))); %#ok<AGROW>
            candidateStarts(end + 1, 1) = candidateStart; %#ok<AGROW>
        end

        if isempty(candidateScores)
            continue;
        end

        [candidateScores, order] = sort(candidateScores, 'ascend');
        candidateValues = candidateValues(:, order);
        candidateStarts = candidateStarts(order);

        useCount = min(opts.TopK, numel(candidateScores));
        topScores = candidateScores(1:useCount);
        topValues = candidateValues(:, 1:useCount);
        topStarts = candidateStarts(1:useCount);

        weights = 1 ./ max(topScores, 0.05) .^ 2;
        weights = weights / sum(weights);
        gapValues = topValues * weights;

        xFilled(gapStart:gapEnd) = gapValues;
        filledStarts(end + 1, 1) = gapStart; %#ok<AGROW>
        filledEnds(end + 1, 1) = gapEnd; %#ok<AGROW>
        filledLengths(end + 1, 1) = gapLength; %#ok<AGROW>
        bestScores(end + 1, 1) = topScores(1); %#ok<AGROW>
        bestCandidateStarts(end + 1, 1) = topStarts(1); %#ok<AGROW>
        nCandidatesUsed(end + 1, 1) = useCount; %#ok<AGROW>
    end

    report = struct;
    report.filled_gap_starts = filledStarts;
    report.filled_gap_ends = filledEnds;
    report.filled_gap_lengths = filledLengths;
    report.best_scores = bestScores;
    report.best_candidate_starts = bestCandidateStarts;
    report.n_candidates_used = nCandidatesUsed;
    report.n_filled_gaps = numel(filledLengths);
end

function bridge = bridge_profile(leftValue, rightValue, gapLength)
    bridge = linspace(leftValue, rightValue, gapLength + 2).';
    bridge = bridge(2:end - 1);
end

function [transformedBlock, score, scale] = score_candidate( ...
        targetLeft, targetRight, candidateLeft, candidateBlock, candidateRight, ...
        targetScale, scaleBounds)

    targetContext = [targetLeft; targetRight];
    candidateContext = [candidateLeft; candidateRight];

    design = [candidateContext, ones(numel(candidateContext), 1)];
    coeff = design \ targetContext;
    scale = coeff(1);
    offset = coeff(2);

    if ~isfinite(scale) || ~isfinite(offset) || ...
            scale < scaleBounds(1) || scale > scaleBounds(2)
        transformedBlock = NaN(size(candidateBlock));
        score = NaN;
        return;
    end

    transformedContext = scale * candidateContext + offset;
    transformedBlock = scale * candidateBlock + offset;

    contextRmse = sqrt(mean((transformedContext - targetContext) .^ 2)) / targetScale;

    leftTargetSlope = targetLeft(end) - targetLeft(end - 1);
    rightTargetSlope = targetRight(2) - targetRight(1);
    leftBoundaryStep = transformedBlock(1) - targetLeft(end);
    rightBoundaryStep = targetRight(1) - transformedBlock(end);
    boundarySlopeError = (abs(leftBoundaryStep - leftTargetSlope) + ...
        abs(rightBoundaryStep - rightTargetSlope)) / (2 * targetScale);

    candidateJumpLeft = transformedBlock(1) - transformedContext(numel(targetLeft));
    candidateJumpRight = transformedContext(numel(targetLeft) + 1) - transformedBlock(end);
    edgeConsistency = (abs(candidateJumpLeft - leftBoundaryStep) + ...
        abs(candidateJumpRight - rightBoundaryStep)) / (2 * targetScale);

    candidateStd = std(transformedBlock);
    targetStd = 0.5 * (std(targetLeft) + std(targetRight));
    variabilityError = abs(candidateStd - targetStd) / max(targetScale, 1e-6);

    score = contextRmse + 0.30 * boundarySlopeError + ...
        0.20 * edgeConsistency + 0.10 * variabilityError;
end
