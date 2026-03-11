function d = trend_distance(baseTrend, testTrend)
%GAPFILL.INTERNAL.TREND_DISTANCE Compare two trend summaries.

    if all(isnan([baseTrend.slope, testTrend.slope]))
        d = NaN;
        return;
    end

    slopeScale = max([abs(baseTrend.slope), abs(testTrend.slope), ...
        max(baseTrend.scale, testTrend.scale) / max(max(baseTrend.span, testTrend.span), 1), eps]);
    slopeTerm = abs(testTrend.slope - baseTrend.slope) / slopeScale;

    rsqBase = baseTrend.rsq;
    rsqTest = testTrend.rsq;
    if isnan(rsqBase) || isnan(rsqTest)
        rsqTerm = 0;
    else
        rsqTerm = abs(rsqTest - rsqBase);
    end

    d = 0.75 * slopeTerm + 0.25 * rsqTerm;
end
