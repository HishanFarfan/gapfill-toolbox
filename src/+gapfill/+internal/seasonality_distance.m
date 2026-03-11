function d = seasonality_distance(baseInfo, testInfo)
%GAPFILL.INTERNAL.SEASONALITY_DISTANCE Compare two seasonality summaries.

    basePeriod = baseInfo.period;
    testPeriod = testInfo.period;
    baseStrength = baseInfo.strength;
    testStrength = testInfo.strength;

    if (isnan(basePeriod) || baseStrength <= 0) && (isnan(testPeriod) || testStrength <= 0)
        d = 0;
        return;
    end

    if isnan(basePeriod) || isnan(testPeriod)
        d = 1 + abs(gapfill.internal.nan_to_zero(baseStrength) - gapfill.internal.nan_to_zero(testStrength));
        return;
    end

    periodTerm = abs(testPeriod - basePeriod) / max(basePeriod, 1);
    strengthTerm = abs(gapfill.internal.nan_to_zero(testStrength) - gapfill.internal.nan_to_zero(baseStrength));
    d = 0.6 * periodTerm + 0.4 * strengthTerm;
end
