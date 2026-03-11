function y = nan_to_zero(x)
%GAPFILL.INTERNAL.NAN_TO_ZERO Replace NaN with zero.

    y = x;
    y(isnan(y)) = 0;
end
