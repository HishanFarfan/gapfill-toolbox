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
    plot(t, xMissing, "k.");
    plot(t, xFilled, "r-", "LineWidth", 1.2);
    title("Original, missing, and filled series");
    legend("Original", "Observed", "Filled", "Location", "best");
    xlabel("Index");
    ylabel("Value");

    nexttile
    stem(report.profile.gap_lengths, "filled");
    title("Gap lengths");
    xlabel("Gap id");
    ylabel("Length");
end
