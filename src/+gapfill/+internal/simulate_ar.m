function y = simulate_ar(model, history, nSteps)
%GAPFILL.INTERNAL.SIMULATE_AR Simulate forward from an AR model and history.

    history = double(history(:));
    history = history(~isnan(history));
    if ~model.is_valid || isempty(history) || nSteps < 1
        y = NaN(nSteps, 1);
        return;
    end

    order = model.order;
    centered = history - model.mean;
    if numel(centered) >= order
        state = flipud(centered(end - order + 1:end));
    else
        state = [flipud(centered); zeros(order - numel(centered), 1)];
    end

    y = zeros(nSteps, 1);
    for i = 1:nSteps
        innovation = model.sigma * randn;
        nextValue = model.coeffs(:).' * state + innovation;
        y(i) = nextValue + model.mean;
        state = [nextValue; state(1:end - 1)];
    end
end
