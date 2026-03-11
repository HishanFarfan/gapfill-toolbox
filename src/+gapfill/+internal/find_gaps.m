function [starts, ends_, lengths] = find_gaps(mask)
%GAPFILL.INTERNAL.FIND_GAPS Return contiguous true-runs in a logical mask.

    mask = logical(mask(:));
    if isempty(mask)
        starts = zeros(0, 1);
        ends_ = zeros(0, 1);
        lengths = zeros(0, 1);
        return;
    end

    delta = diff([false; mask; false]);
    starts = find(delta == 1);
    ends_ = find(delta == -1) - 1;
    lengths = ends_ - starts + 1;
end
