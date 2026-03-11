function xSeed = complete_seed_series(t, x, method)
%GAPFILL.INTERNAL.COMPLETE_SEED_SERIES Create a fully observed seed series.

    t = double(t(:));
    x = double(x(:));
    valid = ~isnan(x);
    xSeed = x;

    if sum(valid) < 2
        return;
    end

    xSeed(~valid) = interp1(t(valid), x(valid), t(~valid), method, 'extrap');
end
