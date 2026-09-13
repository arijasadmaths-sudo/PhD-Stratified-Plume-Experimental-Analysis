function coordinates = plif_source_from_lines(lines)
% Average the pairwise intersections of measured laser lines.
% Each row is [x1 x2 z1 z2] in cropped, unresized image coordinates.
validateattributes(lines, {'numeric'}, {'2d','ncols',4,'real','finite','nonempty'});
if size(lines,1) < 2
    error('PLIF:SourceLines', 'Supply at least two measured lines.');
end
intersections = zeros(0,2);
for i = 1:size(lines,1)-1
    a = [lines(i,3)-lines(i,4), lines(i,2)-lines(i,1)];
    rhs1 = a*[lines(i,1);lines(i,3)];
    for j = i+1:size(lines,1)
        b = [lines(j,3)-lines(j,4), lines(j,2)-lines(j,1)];
        A = [a;b];
        if rcond(A) <= eps
            continue
        end
        rhs2 = b*[lines(j,1);lines(j,3)];
        intersection = A\[rhs1;rhs2];
        if all(isfinite(intersection))
            intersections(end+1,:) = intersection';
        end
    end
end
if isempty(intersections)
    error('PLIF:SourceLines', 'The measured lines have no finite pairwise intersections.');
end
coordinates = mean(intersections,1);
end
