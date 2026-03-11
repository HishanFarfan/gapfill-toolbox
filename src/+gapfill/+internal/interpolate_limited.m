function xInterp = interpolate_limited(t, x, method, maxGapLength)
%GAPFILL.INTERNAL.INTERPOLATE_LIMITED Fill only NaN runs up to maxGapLength.

    t = double(t(:));
    x = double(x(:));
    xInterp = x;
    valid = ~isnan(x);
    if sum(valid) < 2
        return;
    end

    missing = ~valid;
    [gapStarts, gapEnds, gapLengths] = gapfill.internal.find_gaps(missing);
    if isempty(gapLengths)
        return;
    end

    fillMask = false(size(x));
    for i = 1:numel(gapLengths)
        if gapLengths(i) <= maxGapLength
            fillMask(gapStarts(i):gapEnds(i)) = true;
        end
    end

    targetIdx = find(fillMask);
    if isempty(targetIdx)
        return;
    end

    inRange = t(targetIdx) >= min(t(valid)) & t(targetIdx) <= max(t(valid));
    targetIdx = targetIdx(inRange);
    if isempty(targetIdx)
        return;
    end

    xInterp(targetIdx) = interp1(t(valid), x(valid), t(targetIdx), method);
end
