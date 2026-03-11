function value = burstiness_index(x)
%GAPFILL.INTERNAL.BURSTINESS_INDEX Simple burstiness proxy from increments.

    x = double(x(:));
    x = x(~isnan(x));
    if numel(x) < 2
        value = NaN;
        return;
    end

    value = std(diff(x)) / max(std(x), eps);
end
