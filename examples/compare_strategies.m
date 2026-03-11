function compare_strategies()
%COMPARE_STRATEGIES Compare automatic gap filling on two synthetic regimes.

    here = fileparts(mfilename("fullpath"));
    addpath(fullfile(here, "..", "src"));

    seasonalCase();
    regimeSwitchingCase();
end

function seasonalCase()
    rng(21);
    n = 720;
    t = (1:n).';
    x = 0.01 * t + sin(2 * pi * t / 48) + 0.35 * sin(2 * pi * t / 12) + 0.15 * randn(n, 1);
    xMissing = x;
    xMissing(80:92) = NaN;
    xMissing(220:255) = NaN;
    xMissing(520:535) = NaN;

    [xFilled, report] = gapfill.auto_fill(xMissing, "NumReplicates", 6, "Seed", 21);
    fprintf("\n=== Seasonal Case ===\n");
    fprintf("Class: %s\n", report.strategy.series_class);
    fprintf("Interpolation method: %s\n", report.strategy.interpolation_method);
    fprintf("Seasonal backend fills: %d\n", report.seasonal.n_filled_gaps);
    fprintf("Rolling AR fills: %d\n", report.rolling_ar.n_filled_gaps);
    fprintf("Local AR fills: %d\n", report.ar.n_filled_gaps);
    disp(report.evaluation(:, {'Method','RMSE','SpectralDistance','SeasonalityDistance','Score'}));

    figure("Name", "Seasonal case");
    tiledlayout(2, 1);
    nexttile
    plot(t, x, "Color", [0.75 0.75 0.75], "LineWidth", 1);
    hold on
    plot(t, xMissing, "k.");
    plot(t, xFilled, "r-", "LineWidth", 1.2);
    title(sprintf("Seasonal case | class=%s", report.strategy.series_class));
    legend("Original", "Observed", "Filled", "Location", "best");
    xlabel("Index");
    ylabel("Value");

    nexttile
    stem(report.profile.gap_lengths, "filled");
    title("Gap lengths");
    xlabel("Gap id");
    ylabel("Length");
end

function regimeSwitchingCase()
    rng(22);
    x = [ ...
        0.08 * randn(220, 1); ...
        1.8 + filter(1, [1, -0.82], 0.55 * randn(220, 1)); ...
        -1.2 + 0.20 * randn(220, 1)];
    t = (1:numel(x)).';
    xMissing = x;
    xMissing(100:118) = NaN;
    xMissing(305:330) = NaN;
    xMissing(500:512) = NaN;

    [xFilled, report] = gapfill.auto_fill(xMissing, "NumReplicates", 6, "Seed", 22);
    fprintf("\n=== Regime-Switching Case ===\n");
    fprintf("Class: %s\n", report.strategy.series_class);
    fprintf("Interpolation method: %s\n", report.strategy.interpolation_method);
    fprintf("Seasonal backend fills: %d\n", report.seasonal.n_filled_gaps);
    fprintf("Rolling AR fills: %d\n", report.rolling_ar.n_filled_gaps);
    fprintf("Local AR fills: %d\n", report.ar.n_filled_gaps);
    disp(report.evaluation(:, {'Method','RMSE','TrendDistance','SpectralDistance','Score'}));

    figure("Name", "Regime-switching case");
    tiledlayout(2, 1);
    nexttile
    plot(t, x, "Color", [0.75 0.75 0.75], "LineWidth", 1);
    hold on
    plot(t, xMissing, "k.");
    plot(t, xFilled, "b-", "LineWidth", 1.2);
    title(sprintf("Regime-switching case | class=%s", report.strategy.series_class));
    legend("Original", "Observed", "Filled", "Location", "best");
    xlabel("Index");
    ylabel("Value");

    nexttile
    stem(report.profile.gap_lengths, "filled");
    title("Gap lengths");
    xlabel("Gap id");
    ylabel("Length");
end
