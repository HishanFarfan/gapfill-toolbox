function demo_gapfill()
%DEMO_GAPFILL Minimal reproducible demo for gapfill-toolbox.

    here = fileparts(mfilename("fullpath"));
    addpath(fullfile(here, "..", "src"));

    rng(7);
    n = 1200;
    t = (1:n).';
    x = 0.003 * t + sin(2 * pi * t / 90) + filter(1, [1, -0.85], 0.2 * randn(n, 1));
    x = x + 0.4 * randn(n, 1);

    xMissing = x;
    xMissing(120:128) = NaN;
    xMissing(260:290) = NaN;
    xMissing(500:508) = NaN;
    xMissing(720:760) = NaN;
    xMissing(950:965) = NaN;

    [xFilled, report] = gapfill.auto_fill(xMissing, ...
        "NumReplicates", 8, ...
        "FillRemaining", false, ...
        "Seed", 7);

    disp(report.profile.classification)
    disp(report.strategy)
    disp(report.evaluation)
    disp(report.seasonal)
    disp(report.rolling_ar)

    figure("Name", "gapfill demo");
    tiledlayout(2, 1);

    nexttile
    plot(t, x, "Color", [0.75, 0.75, 0.75], "LineWidth", 1);
    hold on
    highlightGapRegions(t, x, isnan(xMissing), [1.0 0.85 0.85], 0.35);
    plot(t(~isnan(xMissing)), xMissing(~isnan(xMissing)), "k.", "MarkerSize", 5);
    plotFilledSegments(t, xFilled, isnan(xMissing), [0.85 0.2 0.2], 1.8);
    title("Original, missing, and filled series");
    legend("Original", "Observed", "Filled only", "Location", "best");
    xlabel("Index");
    ylabel("Value");

    nexttile
    stem(report.profile.gap_lengths, "filled");
    title("Gap lengths");
    xlabel("Gap id");
    ylabel("Length");
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
