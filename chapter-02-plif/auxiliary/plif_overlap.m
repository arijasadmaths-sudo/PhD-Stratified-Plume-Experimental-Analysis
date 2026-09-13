function frac = plif_overlap(m, y00,y10,y11,y01,yn0, yx0, yn1, yx1)
% Integrate the fractional overlap between a light tube and each pixel.
j0 = max(floor(yn0/m.dy), 0);
j1 = min(ceil(yx1/m.dy), m.ny);
frac = zeros(1, m.ny);
acumu = 0.0;
atot = 0.5 * (yn1 + yx1 - yn0 - yx0);
for j = j0:j1
    yn = min((j+1) * m.dy, yx1);
    acumu1 = 0.0;
    if yn < yx0
        acumu1 = 0.5 * (yn - yn0) * (yn - yn0) / (yx0 - yn0);
    else
        acumu1 = 0.5 * (yx0 - yn0) + (yn - yx0);
    end
    if yn > yn1
        acumu1 = acumu1 - 0.5 * (yn - yn1) * (yn - yn1) / (yx1 - yn1);
    end
    if j >= 0 && j < m.ny
        frac(j+1) = (acumu1 - acumu) / atot;
    end
    acumu = acumu1;
end
end
