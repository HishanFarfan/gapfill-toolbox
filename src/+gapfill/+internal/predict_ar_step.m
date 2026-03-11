function value = predict_ar_step(model, history)
%GAPFILL.INTERNAL.PREDICT_AR_STEP Deterministic one-step AR prediction.

    history = double(history(:));
    history = history(~isnan(history));

    if ~model.is_valid || isempty(history)
        value = NaN;
        return;
    end

    order = model.order;
    centered = history - model.mean;
    if numel(centered) >= order
        state = flipud(centered(end - order + 1:end));
    else
        state = [flipud(centered); zeros(order - numel(centered), 1)];
    end

    value = model.coeffs(:).' * state + model.mean;
end
