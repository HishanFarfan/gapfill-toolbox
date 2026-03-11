function d = spectral_distance(baseSignature, testSignature)
%GAPFILL.INTERNAL.SPECTRAL_DISTANCE Compare compact spectral signatures.

    d = gapfill.internal.acf_distance(baseSignature, testSignature);
end
