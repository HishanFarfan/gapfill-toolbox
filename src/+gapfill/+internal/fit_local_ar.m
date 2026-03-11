function model = fit_local_ar(x, maxOrder)
%GAPFILL.INTERNAL.FIT_LOCAL_AR Fit a local AR model by least squares and AIC.

    x = double(x(:));
    x = x(~isnan(x));

    model = struct("is_valid", false, "order", NaN, "coeffs", [], ...
        "sigma", NaN, "mean", NaN);

    if numel(x) < 6
        return;
    end

    xMean = mean(x);
    xc = x - xMean;
    usableMaxOrder = min(maxOrder, max(1, floor((numel(xc) - 1) / 3)));
    if usableMaxOrder < 1
        return;
    end

    bestAIC = Inf;
    bestOrder = NaN;
    bestCoeffs = [];
    bestSigma = NaN;

    for order = 1:usableMaxOrder
        [X, y] = build_lag_matrix(xc, order);
        if size(X, 1) <= order
            continue;
        end

        coeffs = X \ y;
        residuals = y - X * coeffs;
        sigma2 = mean(residuals .^ 2);
        sigma2 = max(sigma2, eps);
        aic = numel(y) * log(sigma2) + 2 * order;

        if aic < bestAIC
            bestAIC = aic;
            bestOrder = order;
            bestCoeffs = coeffs;
            bestSigma = sqrt(sigma2);
        end
    end

    if ~isempty(bestCoeffs)
        model.is_valid = true;
        model.order = bestOrder;
        model.coeffs = bestCoeffs(:);
        model.sigma = bestSigma;
        model.mean = xMean;
    end
end

function [X, y] = build_lag_matrix(x, order)
    n = numel(x);
    rows = n - order;
    X = zeros(rows, order);
    y = zeros(rows, 1);

    for i = 1:rows
        target = order + i;
        X(i, :) = x(target - 1:-1:target - order).';
        y(i) = x(target);
    end
end
