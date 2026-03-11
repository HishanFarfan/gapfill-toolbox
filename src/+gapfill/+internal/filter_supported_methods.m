function methods = filter_supported_methods(candidates)
%GAPFILL.INTERNAL.FILTER_SUPPORTED_METHODS Keep interpolation methods that work.

    if ischar(candidates) || isstring(candidates)
        candidates = cellstr(candidates);
    end

    methods = {};
    x = [1; 2; 3];
    xi = 2;
    for i = 1:numel(candidates)
        method = char(candidates{i});
        try
            interp1(x, x, xi, method);
            methods{end + 1} = method; %#ok<AGROW>
        catch
        end
    end
end
