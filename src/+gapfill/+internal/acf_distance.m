function d = acf_distance(a, b)
%GAPFILL.INTERNAL.ACF_DISTANCE Euclidean distance between two ACF vectors.

    a = a(:);
    b = b(:);
    n = min(numel(a), numel(b));
    a = a(1:n);
    b = b(1:n);
    mask = ~isnan(a) & ~isnan(b);

    if ~any(mask)
        d = NaN;
        return;
    end

    delta = a(mask) - b(mask);
    d = sqrt(mean(delta .^ 2));
end
