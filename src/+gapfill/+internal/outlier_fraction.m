function fraction = outlier_fraction(x)
%GAPFILL.INTERNAL.OUTLIER_FRACTION Robust outlier fraction estimate.

    x = double(x(:));
    x = x(~isnan(x));
    if isempty(x)
        fraction = NaN;
        return;
    end

    medx = median(x);
    madx = median(abs(x - medx));
    scale = max(1.4826 * madx, eps);
    z = abs((x - medx) / scale);
    fraction = mean(z > 3.5);
end
