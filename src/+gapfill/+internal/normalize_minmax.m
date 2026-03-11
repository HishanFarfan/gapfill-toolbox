function yNorm = normalize_minmax(y)
%GAPFILL.INTERNAL.NORMALIZE_MINMAX Normalize values to [0, 1].

    y = double(y(:));
    mask = ~isnan(y);
    yNorm = NaN(size(y));

    if ~any(mask)
        return;
    end

    yMin = min(y(mask));
    yMax = max(y(mask));
    if yMax == yMin
        yNorm(mask) = 0;
        return;
    end

    yNorm(mask) = (y(mask) - yMin) / (yMax - yMin);
end
