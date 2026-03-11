function [starts, ends_] = find_segments(mask)
%GAPFILL.INTERNAL.FIND_SEGMENTS Return contiguous true-runs in a logical mask.

    mask = logical(mask(:));
    if isempty(mask)
        starts = zeros(0, 1);
        ends_ = zeros(0, 1);
        return;
    end

    delta = diff([false; mask; false]);
    starts = find(delta == 1);
    ends_ = find(delta == -1) - 1;
end
