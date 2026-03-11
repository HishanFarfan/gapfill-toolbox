function [xFilled, report] = wavelet_context_fill(x, varargin)
%GAPFILL.INTERNAL.WAVELET_CONTEXT_FILL Fill gaps using Haar-wavelet context matching.

    parser = inputParser;
    parser.addParameter("Window", 64, @(v) isnumeric(v) && isscalar(v) && v >= 8);
    parser.addParameter("MinGapLength", 4, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("MaxGapLength", 96, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("TopK", 3, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("ObservedMask", [], @(v) isempty(v) || islogical(v) || isnumeric(v));
    parser.addParameter("MaxScore", 0.78, @(v) isnumeric(v) && isscalar(v) && v > 0);
    parser.addParameter("ScaleBounds", [0.30, 3.20], ...
        @(v) isnumeric(v) && numel(v) == 2 && all(isfinite(v)) && v(1) > 0 && v(2) >= v(1));
    parser.addParameter("BridgeWeight", 0.08, @(v) isnumeric(v) && isscalar(v) && v >= 0 && v <= 1);
    parser.parse(varargin{:});
    opts = parser.Results;

    xFilled = double(x(:));
    n = numel(xFilled);
    if isempty(opts.ObservedMask)
        observedMask = ~isnan(xFilled);
    else
        observedMask = logical(opts.ObservedMask(:));
        if numel(observedMask) ~= n
            error("gapfill:internal:wavelet_context_fill:ObservedMaskSizeMismatch", ...
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
        contextLength = 2 ^ floor(log2(contextWindow));
        if contextLength < 8
            continue;
        end

        targetLeft = xFilled(gapStart - contextLength:gapStart - 1);
        targetRight = xFilled(gapEnd + 1:gapEnd + contextLength);
        if any(isnan(targetLeft)) || any(isnan(targetRight))
            continue;
        end

        targetScale = max(std([targetLeft; targetRight], 0, 1), 1e-6);
        targetDescriptor = wavelet_descriptor(targetLeft, targetRight);
        edgeBridge = linspace(targetLeft(end), targetRight(1), gapLength + 2).';
        edgeBridge = edgeBridge(2:end - 1);

        candidateValues = zeros(gapLength, 0);
        candidateScores = zeros(0, 1);
        candidateStarts = zeros(0, 1);

        firstCandidateStart = contextLength + 1;
        lastCandidateStart = n - contextLength - gapLength + 1;
        for candidateStart = firstCandidateStart:lastCandidateStart
            candidateEnd = candidateStart + gapLength - 1;
            region = candidateStart - contextLength:candidateEnd + contextLength;
            if any(~observedMask(region))
                continue;
            end

            candidateLeft = xFilled(candidateStart - contextLength:candidateStart - 1);
            candidateBlock = xFilled(candidateStart:candidateEnd);
            candidateRight = xFilled(candidateEnd + 1:candidateEnd + contextLength);
            if any(isnan(candidateLeft)) || any(isnan(candidateBlock)) || any(isnan(candidateRight))
                continue;
            end

            [transformedBlock, score, scale] = score_candidate( ...
                targetLeft, targetRight, targetDescriptor, ...
                candidateLeft, candidateBlock, candidateRight, ...
                targetScale, opts.ScaleBounds);
            if isnan(score) || score > opts.MaxScore
                continue;
            end

            transformedBlock = (1 - opts.BridgeWeight) * transformedBlock + ...
                opts.BridgeWeight * edgeBridge;

            candidateValues(:, end + 1) = transformedBlock; %#ok<AGROW>
            candidateScores(end + 1, 1) = score + 0.01 * abs(log(max(scale, 1e-6))); %#ok<AGROW>
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

function descriptor = wavelet_descriptor(leftContext, rightContext)
    descriptor = [side_descriptor(leftContext, true); side_descriptor(rightContext, false)];
end

function descriptor = side_descriptor(context, useTail)
    if useTail
        x = context(:);
    else
        x = flipud(context(:));
    end

    x = x - mean(x);
    scale = std(x);
    if ~isfinite(scale) || scale < 1e-6
        x = zeros(size(x));
    else
        x = x / scale;
    end

    energies = zeros(0, 1);
    absMeans = zeros(0, 1);
    current = x;
    while numel(current) >= 2
        oddPart = current(1:2:end);
        evenPart = current(2:2:end);
        approx = (oddPart + evenPart) / sqrt(2);
        detail = (oddPart - evenPart) / sqrt(2);
        energies(end + 1, 1) = log2(mean(detail .^ 2) + eps); %#ok<AGROW>
        absMeans(end + 1, 1) = mean(abs(detail)); %#ok<AGROW>
        current = approx;
    end

    coarseTail = current(1:min(4, numel(current)));
    descriptor = [energies; absMeans; coarseTail];
end

function [transformedBlock, score, scale] = score_candidate( ...
        targetLeft, targetRight, targetDescriptor, ...
        candidateLeft, candidateBlock, candidateRight, ...
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

    transformedLeft = scale * candidateLeft + offset;
    transformedRight = scale * candidateRight + offset;
    transformedBlock = scale * candidateBlock + offset;
    transformedDescriptor = wavelet_descriptor(transformedLeft, transformedRight);

    waveletDistance = sqrt(mean((transformedDescriptor - targetDescriptor) .^ 2));
    rawContextRmse = sqrt(mean(([transformedLeft; transformedRight] - targetContext) .^ 2)) / targetScale;

    leftBoundary = abs(transformedBlock(1) - targetLeft(end)) / targetScale;
    rightBoundary = abs(targetRight(1) - transformedBlock(end)) / targetScale;

    leftSlope = abs((transformedBlock(1) - targetLeft(end)) - (targetLeft(end) - targetLeft(end - 1))) / targetScale;
    rightSlope = abs((targetRight(1) - transformedBlock(end)) - (targetRight(2) - targetRight(1))) / targetScale;

    score = 0.58 * waveletDistance + 0.20 * rawContextRmse + ...
        0.12 * (leftBoundary + rightBoundary) / 2 + ...
        0.10 * (leftSlope + rightSlope) / 2;
end
