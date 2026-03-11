function render_readme_figures()
%RENDER_README_FIGURES Generate static figures used by the README.

    here = fileparts(mfilename("fullpath"));
    rootDir = fullfile(here, "..");
    addpath(fullfile(rootDir, "src"));

    assetDir = fullfile(rootDir, "docs", "assets");
    if ~exist(assetDir, "dir")
        mkdir(assetDir);
    end

    renderSeasonalFigure(fullfile(assetDir, "readme_case_seasonal.png"));
    renderRegimeFigure(fullfile(assetDir, "readme_case_regime.png"));
end

function renderSeasonalFigure(outputPath)
    rng(31);
    n = 720;
    t = (1:n).';
    x = 0.01 * t + sin(2 * pi * t / 48) + 0.35 * sin(2 * pi * t / 12) + 0.15 * randn(n, 1);
    xMissing = x;
    xMissing(80:92) = NaN;
    xMissing(220:255) = NaN;
    xMissing(520:535) = NaN;

    [xFilled, report] = gapfill.auto_fill(xMissing, "NumReplicates", 6, "Seed", 31);

    fig = figure("Visible", "off", "Color", "w", "Position", [100 100 1100 640]);
    tiledlayout(2, 1, "Padding", "compact", "TileSpacing", "compact");

    nexttile
    plot(t, x, "Color", [0.82 0.82 0.82], "LineWidth", 1.0);
    hold on
    plot(t, xMissing, "k.", "MarkerSize", 6);
    plot(t, xFilled, "Color", [0.85 0.2 0.2], "LineWidth", 1.4);
    title(sprintf("Seasonal case | class=%s | method=%s", ...
        report.strategy.series_class, report.strategy.interpolation_method));
    legend("Original", "Observed", "Filled", "Location", "best");
    xlabel("Index");
    ylabel("Value");
    grid on

    nexttile
    bar(categorical(report.evaluation.Method), report.evaluation{:, "Score"}, ...
        "FaceColor", [0.18 0.45 0.75]);
    ylabel("Score");
    title(sprintf("Scoring summary | seasonal backend fills=%d", report.seasonal.n_filled_gaps));
    grid on

    exportgraphics(fig, outputPath, "Resolution", 160);
    close(fig);
end

function renderRegimeFigure(outputPath)
    rng(32);
    x = [ ...
        0.08 * randn(220, 1); ...
        1.8 + filter(1, [1, -0.82], 0.55 * randn(220, 1)); ...
        -1.2 + 0.20 * randn(220, 1)];
    t = (1:numel(x)).';
    xMissing = x;
    xMissing(100:118) = NaN;
    xMissing(305:330) = NaN;
    xMissing(500:512) = NaN;

    [xFilled, report] = gapfill.auto_fill(xMissing, "NumReplicates", 6, "Seed", 32);

    fig = figure("Visible", "off", "Color", "w", "Position", [100 100 1100 640]);
    tiledlayout(2, 1, "Padding", "compact", "TileSpacing", "compact");

    nexttile
    plot(t, x, "Color", [0.82 0.82 0.82], "LineWidth", 1.0);
    hold on
    plot(t, xMissing, "k.", "MarkerSize", 6);
    plot(t, xFilled, "Color", [0.15 0.4 0.85], "LineWidth", 1.4);
    title(sprintf("Regime-switching case | class=%s | method=%s", ...
        report.strategy.series_class, report.strategy.interpolation_method));
    legend("Original", "Observed", "Filled", "Location", "best");
    xlabel("Index");
    ylabel("Value");
    grid on

    nexttile
    bar(categorical(report.evaluation.Method), report.evaluation{:, "Score"}, ...
        "FaceColor", [0.1 0.6 0.45]);
    ylabel("Score");
    title(sprintf("Scoring summary | rolling AR fills=%d | local AR fills=%d", ...
        report.rolling_ar.n_filled_gaps, report.ar.n_filled_gaps));
    grid on

    exportgraphics(fig, outputPath, "Resolution", 160);
    close(fig);
end
