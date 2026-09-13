function frac = plif_overlap_polygon(m, y00,y10,y11,y01,yn0,yx0,yn1,yx1)
% Compare light-tube overlap with direct polygon intersection.
% The inherited image-grid convention uses unit square pixels.
if m.dy ~= 1
    error('PLIF:GridSpacing', 'This image-grid helper requires m.dy = 1.');
end
j0 = max(floor(yn0/m.dy), 0);
j1 = min(ceil(yx1/m.dy), m.ny-1);
frac = zeros(1, m.ny);
acumu = 0.0;
atot = 0.5 * (yn1 + yx1 - yn0 - yx0);
acumu = 0.0;
for j = j0:j1
    p=polyshape([y00,y10,y11,y01],[0,1,1,0]);
    pj=polyshape([j,j,j+m.dy,j+m.dy],[0,1,1,0]);
    pa=area(intersect(p,pj))/atot;
    frac(j+1)=pa;
end
end
