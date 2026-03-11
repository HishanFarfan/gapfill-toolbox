function [xFilled, report] = roughness_bridge_fill(x, varargin)
%GAPFILL.INTERNAL.ROUGHNESS_BRIDGE_FILL Fill gaps with a roughness-preserving texture bridge.

    parser = inputParser;
    parser.addParameter("Window", 48, @(v) isnumeric(v) && isscalar(v) && v >= 8);
    parser.addParameter("MinGapLength", 3, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("MaxGapLength", 80, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("TopK", 3, @(v) isnumeric(v) && isscalar(v) && v >= 1);
    parser.addParameter("ObservedMask", [], @(v) isempty(v) || islogical(v) || isnumeric(v));
    parser.addParameter("MaxScore", 0.95, @(v) isnumeric(v) && isscalar(v) && v > 0);
    parser.parse(varargin{:});
    opts = parser.Results;

    xFilled = double(x(:));
    n = numel(xFilled);
    if isempty(opts.ObservedMask)
        observedMask = ~isnan(xFilled);
    else
        observedMask = logical(opts.ObservedMask(:));
        if numel(observedMask) ~= n
            error("gapfill:internal:roughness_bridge_fill:ObservedMaskSizeMismatch", ...
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
        if contextWindow < 6
            continue;
        end

        targetLeft = xFilled(gapStart - contextWindow:gapStart - 1);
        targetRight = xFilled(gapEnd + 1:gapEnd + contextWindow);
        if any(isnan(targetLeft)) || any(isnan(targetRight))
            continue;
        end

        targetRoughness = local_roughness([targetLeft; targetRight]);
        targetScale = max(std([targetLeft; targetRight]), 1e-6);
        baseBridge = bridge_values(targetLeft(end), targetRight(1), gapLength);
        targetSignature = context_signature(targetLeft, targetRight);

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

            [candidateFill, score] = build_candidate_fill( ...
                targetLeft, targetRight, targetSignature, targetRoughness, targetScale, ...
                candidateLeft, candidateBlock, candidateRight, baseBridge);
            if isnan(score) || score > opts.MaxScore
                continue;
            end

            candidateValues(:, end + 1) = candidateFill; %#ok<AGROW>
            candidateScores(end + 1, 1) = score; %#ok<AGROW>
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

function [candidateFill, score] = build_candidate_fill( ...
        targetLeft, targetRight, targetSignature, targetRoughness, targetScale, ...
        candidateLeft, candidateBlock, candidateRight, baseBridge)

    candidateSignature = context_signature(candidateLeft, candidateRight);
    signatureDistance = sqrt(mean((candidateSignature - targetSignature) .^ 2));

    candidateTexture = candidateBlock - bridge_values(candidateBlock(1), candidateBlock(end), numel(candidateBlock));
    textureRoughness = local_roughness(candidateTexture);
    if textureRoughness < 1e-6
        candidateFill = NaN(size(candidateBlock));
        score = NaN;
        return;
    end

    scaledTexture = candidateTexture * (targetRoughness / textureRoughness);
    scaledTexture = scaledTexture - mean(scaledTexture);
    scaledTexture = scaledTexture - line_between(scaledTexture(1), scaledTexture(end), numel(scaledTexture));
    candidateFill = baseBridge + scaledTexture;

    leftBoundaryError = abs(candidateFill(1) - targetLeft(end)) / targetScale;
    rightBoundaryError = abs(targetRight(1) - candidateFill(end)) / targetScale;
    fillRoughness = local_roughness(candidateFill);
    roughnessError = abs(fillRoughness - targetRoughness) / max(targetRoughness, 1e-6);

    candidateVm = gapfill.internal.gap_visual_metrics(baseBridge, candidateFill);
    score = 0.42 * signatureDistance + 0.22 * roughnessError + ...
        0.14 * leftBoundaryError + 0.14 * rightBoundaryError + ...
        0.08 * candidateVm.visual_distance;
end

function values = bridge_values(leftValue, rightValue, gapLength)
    values = line_between(leftValue, rightValue, gapLength + 2);
    values = values(2:end - 1);
end

function values = line_between(leftValue, rightValue, nPoints)
    values = linspace(leftValue, rightValue, nPoints).';
end

function signature = context_signature(leftContext, rightContext)
    leftDiff = diff(leftContext);
    rightDiff = diff(rightContext);
    signature = [ ...
        safe_mean(leftDiff); ...
        safe_std(leftDiff); ...
        safe_mean(abs(leftDiff)); ...
        safe_std(diff(leftDiff)); ...
        safe_mean(rightDiff); ...
        safe_std(rightDiff); ...
        safe_mean(abs(rightDiff)); ...
        safe_std(diff(rightDiff))];
    signature = normalize_signature(signature);
end

function value = local_roughness(x)
    x = x(:);
    if numel(x) < 2
        value = 0;
    else
        value = std(diff(x));
    end
end

function value = safe_mean(x)
    if isempty(x)
        value = 0;
    else
        value = mean(x);
    end
end

function value = safe_std(x)
    if numel(x) < 2
        value = 0;
    else
        value = std(x);
    end
end

function signature = normalize_signature(signature)
    scale = std(signature);
    if ~isfinite(scale) || scale < 1e-6
        signature = zeros(size(signature));
    else
        signature = (signature - mean(signature)) / scale;
    end
end
