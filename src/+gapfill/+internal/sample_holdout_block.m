function idx = sample_holdout_block(validMask, holdoutFraction, minSegmentLength)
%GAPFILL.INTERNAL.SAMPLE_HOLDOUT_BLOCK Sample a contiguous validation block.

    [segmentStarts, segmentEnds] = gapfill.internal.find_segments(validMask);
    segmentLengths = segmentEnds - segmentStarts + 1;
    candidates = find(segmentLengths >= minSegmentLength);

    if isempty(candidates)
        idx = zeros(0, 1);
        return;
    end

    selected = candidates(randi(numel(candidates)));
    segmentLength = segmentLengths(selected);
    blockLength = max(2, round(holdoutFraction * segmentLength));
    blockLength = min(blockLength, segmentLength - 1);
    startOffset = randi(segmentLength - blockLength + 1) - 1;
    idx = (segmentStarts(selected) + startOffset : ...
        segmentStarts(selected) + startOffset + blockLength - 1).';
end
