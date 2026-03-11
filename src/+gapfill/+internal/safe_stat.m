function value = safe_stat(x, mode)
%GAPFILL.INTERNAL.SAFE_STAT Compute simple stats while tolerating empty inputs.

    x = x(~isnan(x));
    if isempty(x)
        value = NaN;
        return;
    end

    switch lower(mode)
        case "mean"
            value = mean(x);
        case "median"
            value = median(x);
        case "max"
            value = max(x);
        otherwise
            error("gapfill:internal:safe_stat:UnsupportedMode", ...
                "Unsupported statistic mode '%s'.", mode);
    end
end
