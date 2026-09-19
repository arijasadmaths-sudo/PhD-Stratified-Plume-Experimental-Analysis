function test_detect_stratification_depth
%TEST_DETECT_STRATIFICATION_DEPTH Synthetic regression checks.

    rhoS = 1000;
    epsilon = 0.125;
    z = (0:4)' * 0.001;

    % Direct transition: the lower row of the first qualifying pair is kept.
    p1 = [1000; 1000; 999.75; 999.50; 999.25];
    r1 = detect_stratification_depth(p1, z, rhoS, epsilon, 0.004);
    assert(r1.detected);
    assert(abs(r1.z_b_m - 0.001) < 1e-15);
    assert(abs(r1.h_m - 0.003) < 1e-15);
    assert(r1.candidateLowerRow == 2 && r1.candidateUpperRow == 3);

    % An early candidate is rejected because a higher row returns exactly
    % to the ambient value. The later persistent transition is retained.
    p2 = [1000; 999.75; 1000; 999.50; 999.25];
    r2 = detect_stratification_depth(p2, z, rhoS, epsilon);
    assert(r2.detected);
    assert(abs(r2.z_b_m - 0.002) < 1e-15);
    assert(r2.candidateLowerRow == 3 && r2.candidateUpperRow == 4);

    % Equality with epsilon is not enough because the thesis criterion is >.
    p3 = [1000; 999.875; 999.750; 999.625; 999.500];
    r3 = detect_stratification_depth(p3, z, rhoS, epsilon);
    assert(~r3.detected);

    % The ambient-return check is exact. A near-ambient value is not a return.
    p4 = [1000; 999.75; 999.999999; 999.50; 999.25];
    r4 = detect_stratification_depth(p4, z, rhoS, epsilon);
    assert(r4.detected);
    assert(abs(r4.z_b_m - 0.000) < 1e-15);

    % Input image rows may run from top to bottom; physical z controls the scan.
    r5 = detect_stratification_depth(flipud(p1), flipud(z), rhoS, epsilon);
    assert(r5.detected);
    assert(abs(r5.z_b_m - 0.001) < 1e-15);
    assert(r5.candidateLowerRow == 4 && r5.candidateUpperRow == 3);

    fprintf('Stratification-height detector regression checks passed.\n');
end
