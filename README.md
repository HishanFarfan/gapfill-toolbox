# gapfill-toolbox

MATLAB toolbox for exploratory analysis of missing-data patterns and automatic gap filling in time series.

`gapfill-toolbox` is aimed at transparent, structure-aware imputation rather than one-shot black-box filling. The library profiles the observed series, chooses a strategy based on structural diagnostics, and returns both the filled signal and a report explaining why a method was chosen.

Current scope:

- Profile missing-data structure and basic time-series diagnostics
- Estimate Hurst exponent with a DFA-based internal estimator
- Detect coarse series regimes: `smooth`, `persistent`, `antipersistent`, `seasonal`, `bursty`
- Detect regime changes and multiscale heterogeneity
- Score interpolation candidates with blocked cross-validation
- Penalize methods that distort spectrum, trend, or seasonal structure
- Penalize methods that look structurally wrong inside hidden gaps
- Fill short gaps with the best interpolation method
- Fill repeatable gaps by matching left/right context against observed patches from the same series
- Fill seasonal gaps with a trend + seasonal-template backend when appropriate
- Fill medium gaps with a deterministic rolling-AR backend
- Fill longer internal gaps with local autoregressive simulation
- Return a transparent report with metrics and chosen strategy

## Public API

- `gapfill.profile(data)`
- `gapfill.evaluate_methods(data)`
- `gapfill.auto_fill(data)`

## Repository Layout

- `src/+gapfill`: public API
- `src/+gapfill/+internal`: internal diagnostics, classification, and filling backends
- `examples`: runnable demos
- `tests`: smoke tests

## Pipeline Architecture

```mermaid
flowchart TD
    A["Input Series<br/>with NaNs"] --> B["Profile<br/>missingness, trend, ACF, spectrum,<br/>seasonality, regime changes"]
    B --> C["Classify Series<br/>smooth / persistent / seasonal / bursty / regime_switching"]
    C --> D["Evaluate Interpolation Methods<br/>blocked CV + structural penalties"]
    D --> E["Choose Adaptive Backend<br/>weights, interpolation span, backends"]
    E --> F["Short Gaps<br/>best interpolation"]
    E --> G["Context-Matched Gaps<br/>patch search inside the same series"]
    E --> H["Seasonal Gaps<br/>trend + seasonal template"]
    E --> I["Medium Gaps<br/>rolling AR"]
    E --> K["Difficult Gaps<br/>local bidirectional AR"]
    F --> J["Filled Series + Report"]
    G --> J
    H --> J
    I --> J
    K --> J
```

## Quick Start

```matlab
addpath("src");

x = cumsum(randn(1000, 1));
x(120:130) = NaN;
x(400:430) = NaN;

[xFilled, report] = gapfill.auto_fill(x);
disp(report.strategy)
```

## Visual Examples

In the figures below:

- gray: original signal
- black: observed samples
- red: filled values only inside the amputated gaps

These examples are useful for inspecting behavior, but they should be read together with the gap-level metrics. A low global error can still hide a visually implausible reconstruction inside the missing interval.

### 1. Seasonal signal with medium gaps

The toolbox identifies the series as `seasonal`, keeps interpolation conservative, and now tries context-matched patches before any model-based fallback. In this specific case, the repeated local structure is strong enough that the context backend resolves the larger gaps directly.

![Seasonal case](docs/assets/readme_case_seasonal.png)

What happens here:

- the profiler detects strong periodic structure and a stable dominant period
- method ranking penalizes seasonal distortion, not only pointwise error
- the filling plan uses interpolation for short gaps and context-matched patches for the larger internal gaps
- the seasonal backend stays available, but it does not need to fire when the patch match is strong enough

### 2. Regime-switching signal with structural breaks

The toolbox identifies this as `regime_switching`, lowers the allowed interpolation span, and tests context matching before falling back to local models. In this case the neighborhood match is not reliable enough, so the backend rejects the patch candidates and lets the rolling AR layer handle the gaps.

![Regime-switching case](docs/assets/readme_case_regime.png)

What happens here:

- the profiler detects heterogeneity across windows and change-like behavior
- the selector reduces aggressive interpolation across long gaps
- the context-match backend is available, but it only fills if it finds a genuinely compatible left/right neighborhood elsewhere in the series
- rolling/local AR backends preserve local dynamics better than a single smooth interpolant

### 3. Persistent-memory signal with Hurst exponent above 0.5

The toolbox now estimates H explicitly with a simple DFA-based routine. When `H > 0.5`, persistence contributes directly to the class decision and increases the weight of correlation and spectral preservation.

![Persistent case](docs/assets/readme_case_persistent.png)

What happens here:

- the profiler estimates an effective Hurst exponent above `0.5`
- persistence is treated as evidence of long-memory behavior, not just high lag-1 correlation
- the selector becomes more conservative with interpolation and gives more weight to spectral/ACF preservation
- context-matched patches are tested first, but the backend backs off if the series does not contain a trustworthy repeated neighborhood

## Gap-Level Visual Metrics

The toolbox now measures similarity inside each hidden validation gap, not only over the observed series as a whole.

Current structural metrics include:

- `ShapeDistance`: penalizes mismatch in normalized shape
- `DerivativeDistance`: penalizes mismatch in first-order local changes
- `CurvatureDistance`: penalizes mismatch in second-order bending
- `TVDistance`: penalizes mismatch in total variation
- `TurningPointDistance`: penalizes mismatch in number of local direction changes
- `VisualDistance`: weighted summary of the previous metrics

Why this matters:

- a fill can have decent `RMSE` and still look obviously wrong
- a smooth bridge across the gap may be numerically acceptable but structurally implausible
- these metrics try to capture the kind of failure that becomes obvious in plots

At the moment, the toolbox uses these metrics during method ranking, but they should still be treated as an evolving part of the evaluation layer.

## What The Automatic Analysis Does

`gapfill.auto_fill` runs a staged analysis before filling anything:

1. Profiles the observed part of the series.
   It measures missing-data geometry, trend strength, persistence, Hurst exponent, seasonality, spectral shape, burstiness, and regime-change indicators.
2. Classifies the series.
   The current coarse labels are `smooth`, `persistent`, `antipersistent`, `seasonal`, `bursty`, and `regime_switching`.
3. Benchmarks interpolation candidates.
   It hides observed blocks on purpose, reconstructs them, and scores each method using pointwise error plus penalties for structure distortion.
4. Builds an adaptive filling plan.
   The chosen class modifies interpolation span, metric weights, and which backends are enabled.
5. Fills by layers.
   Short gaps are interpolated first, then context-matched patches are attempted when the neighborhood match is strong enough, then seasonal gaps, then rolling AR, and finally local AR for harder residual gaps.

The evaluation layer now checks two different questions:

- does the fill reduce numerical error?
- does the fill look like a plausible continuation of the hidden segment?

## Design Notes

This first version is intentionally conservative:

- Interpolation is used only up to a selected gap length threshold
- Local AR filling is used only for internal gaps with enough context
- Very large or poorly supported gaps can remain unresolved unless a final fallback is requested

The goal is to keep the library inspectable and statistically defensible before expanding to more aggressive models.

The method selector is now adaptive:

- `smooth`: favors shape-preserving interpolation and larger interpolation spans
- `persistent`: emphasizes autocorrelation, Hurst-aware memory, and spectral preservation
- `antipersistent`: is stricter with long interpolation spans and favors more local reconstruction
- `seasonal`: emphasizes seasonal consistency and trend preservation
- `bursty`: is more conservative with long interpolation spans
- `regime_switching`: reduces aggressive interpolation and leans more on local adaptive models

## Examples

Basic demo:

```matlab
run("examples/demo_gapfill.m")
```

Comparative example with seasonal and regime-switching cases:

```matlab
run("examples/compare_strategies.m")
```

Generate the README images again:

```matlab
run("examples/render_readme_figures.m")
```

## Smoke Test

```matlab
run("tests/run_smoke_tests.m")
```

## Output Contract

`gapfill.auto_fill` returns:

- `xFilled`: filled series
- `report.profile`: exploratory diagnostics
- `report.evaluation`: method comparison table
- `report.strategy`: selected class, interpolation policy, and enabled backends
- `report.seasonal`, `report.rolling_ar`, `report.ar`: backend-level fill summaries
- `report.context_match`: patch-match fill summary

`report.evaluation` now also includes gap-level structural metrics such as `ShapeDistance`, `DerivativeDistance`, `CurvatureDistance`, `TVDistance`, `TurningPointDistance`, and `VisualDistance`.

## Current Limitations

- The classifier is heuristic, not probabilistic.
- The seasonal backend assumes approximately stable periodicity.
- The AR backends are local and univariate; they do not use exogenous covariates.
- Extremely long edge gaps still require care or stronger domain assumptions.
- Some fills can still look visually implausible even when standard numerical metrics appear acceptable.
- The visual metrics are a first attempt to capture this problem; they are not yet a final quality criterion.
