function run_smoke_tests()
%RUN_SMOKE_TESTS Basic smoke tests for gapfill-toolbox.

    rootDir = fileparts(fileparts(mfilename("fullpath")));
    addpath(fullfile(rootDir, "src"));

    rng(11);
    x = cumsum(randn(600, 1));
    x(50:54) = NaN;
    x(150:180) = NaN;
    x(350:360) = NaN;

    profileReport = gapfill.profile(x);
    assert(profileReport.n_missing == 47);
    assert(profileReport.n_gaps == 3);
    assert(isfield(profileReport, "classification"));
    assert(isfield(profileReport.stats, "spectral_entropy"));
    assert(isfield(profileReport.stats, "seasonality_strength"));
    assert(isfield(profileReport.stats, "regime_change_score"));

    evaluation = gapfill.evaluate_methods(x, "NumReplicates", 4, "Seed", 11);
    assert(istable(evaluation.results));
    assert(~isempty(evaluation.best_method));
    assert(any(strcmp(evaluation.results.Properties.VariableNames, 'SpectralDistance')));
    assert(isfield(evaluation, "backend"));

    [xFilled, report] = gapfill.auto_fill(x, "NumReplicates", 4, "Seed", 11);
    assert(numel(xFilled) == numel(x));
    assert(sum(isnan(xFilled)) <= sum(isnan(x)));
    assert(isfield(report, "strategy"));
    assert(isfield(report.strategy, "series_class"));
    assert(isfield(report, "rolling_ar"));

    t = (1:720).';
    xSeasonal = sin(2 * pi * t / 48) + 0.25 * sin(2 * pi * t / 12) + 0.1 * randn(size(t));
    pSeasonal = gapfill.profile(xSeasonal);
    assert(strcmp(pSeasonal.classification.primary_label, 'seasonal'));

    xRegime = [0.1 * randn(240, 1); 3 + filter(1, [1, -0.8], randn(240, 1)); -2 + 0.5 * randn(240, 1)];
    pRegime = gapfill.profile(xRegime);
    assert(pRegime.classification.flags.has_regime_changes);

    fprintf("All gapfill smoke tests passed.\n");
end
