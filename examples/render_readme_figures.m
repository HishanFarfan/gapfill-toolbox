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
    renderPersistentFigure(fullfile(assetDir, "readme_case_persistent.png"));
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
    highlightGapRegions(t, x, isnan(xMissing), [1.0 0.85 0.85], 0.38);
    plot(t(~isnan(xMissing)), xMissing(~isnan(xMissing)), "k.", "MarkerSize", 5);
    plotFilledSegments(t, xFilled, isnan(xMissing), [0.82 0.12 0.12], 2.4);
    title(sprintf("Seasonal case | class=%s | method=%s", ...
        report.strategy.series_class, report.strategy.interpolation_method));
    legend("Original", "Observed", "Filled only", "Location", "best");
    xlabel("Index");
    ylabel("Value");
    grid on

    nexttile
    bar(categorical(report.evaluation.Method), report.evaluation{:, "Score"}, ...
        "FaceColor", [0.18 0.45 0.75]);
    ylabel("Score");
    title(sprintf("Scoring summary | context fills=%d | seasonal fills=%d", ...
        report.context_match.n_filled_gaps, report.seasonal.n_filled_gaps));
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
    highlightGapRegions(t, x, isnan(xMissing), [1.0 0.85 0.85], 0.38);
    plot(t(~isnan(xMissing)), xMissing(~isnan(xMissing)), "k.", "MarkerSize", 5);
    plotFilledSegments(t, xFilled, isnan(xMissing), [0.82 0.12 0.12], 2.4);
    title(sprintf("Regime-switching case | class=%s | method=%s", ...
        report.strategy.series_class, report.strategy.interpolation_method));
    legend("Original", "Observed", "Filled only", "Location", "best");
    xlabel("Index");
    ylabel("Value");
    grid on

    nexttile
    bar(categorical(report.evaluation.Method), report.evaluation{:, "Score"}, ...
        "FaceColor", [0.1 0.6 0.45]);
    ylabel("Score");
    title(sprintf("Scoring summary | context fills=%d | rolling AR fills=%d | local AR fills=%d", ...
        report.context_match.n_filled_gaps, report.rolling_ar.n_filled_gaps, report.ar.n_filled_gaps));
    grid on

    exportgraphics(fig, outputPath, "Resolution", 160);
    close(fig);
end

function renderPersistentFigure(outputPath)
    rng(33);
    n = 900;
    t = (1:n).';
    x = filter(1, [1, -0.88], 0.10 * randn(n, 1));
    x = x - mean(x);
    x = x / std(x);
    xMissing = x;
    xMissing(120:132) = NaN;
    xMissing(310:340) = NaN;
    xMissing(610:628) = NaN;

    [xFilled, report] = gapfill.auto_fill(xMissing, "NumReplicates", 6, "Seed", 33);

    fig = figure("Visible", "off", "Color", "w", "Position", [100 100 1100 640]);
    tiledlayout(2, 1, "Padding", "compact", "TileSpacing", "compact");

    nexttile
    plot(t, x, "Color", [0.82 0.82 0.82], "LineWidth", 1.0);
    hold on
    highlightGapRegions(t, x, isnan(xMissing), [1.0 0.85 0.85], 0.38);
    plot(t(~isnan(xMissing)), xMissing(~isnan(xMissing)), "k.", "MarkerSize", 5);
    plotFilledSegments(t, xFilled, isnan(xMissing), [0.82 0.12 0.12], 2.4);
    title(sprintf("Persistent-memory case | class=%s | H=%.2f", ...
        report.strategy.series_class, report.profile.stats.hurst_effective));
    legend("Original", "Observed", "Filled only", "Location", "best");
    xlabel("Index");
    ylabel("Value");
    grid on

    nexttile
    bar(categorical(report.evaluation.Method), report.evaluation{:, "Score"}, ...
        "FaceColor", [0.45 0.25 0.75]);
    ylabel("Score");
    title(sprintf("Scoring summary | context fills=%d | rolling AR fills=%d | local AR fills=%d", ...
        report.context_match.n_filled_gaps, report.rolling_ar.n_filled_gaps, report.ar.n_filled_gaps));
    grid on

    exportgraphics(fig, outputPath, "Resolution", 160);
    close(fig);
end

function highlightGapRegions(t, yReference, fillMask, colorValue, faceAlpha)
    [gapStarts, gapEnds, ~] = gapfill.internal.find_gaps(fillMask);
    yMin = min(yReference) - 0.05 * range(yReference);
    yMax = max(yReference) + 0.05 * range(yReference);
    for i = 1:numel(gapStarts)
        x0 = t(gapStarts(i));
        x1 = t(gapEnds(i));
        patch([x0 x1 x1 x0], [yMin yMin yMax yMax], colorValue, ...
            "FaceAlpha", faceAlpha, "EdgeColor", "none");
    end
end

function plotFilledSegments(t, xFilled, fillMask, colorValue, lineWidth)
    [gapStarts, gapEnds, ~] = gapfill.internal.find_gaps(fillMask);
    for i = 1:numel(gapStarts)
        idx = gapStarts(i):gapEnds(i);
        plot(t(idx), xFilled(idx), "-", "Color", colorValue, "LineWidth", lineWidth);
    end
end
