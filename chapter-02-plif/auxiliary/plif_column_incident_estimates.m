function [i0,attenuatedFraction]=plif_column_incident_estimates(img,den_array,kappa)
% Auxiliary incident-intensity estimate for parallel columns.
% This recurrence includes the current row in its cumulative attenuation.
% The main reconstruction uses reCalcI0, with attenuation from preceding rows.
validateattributes(kappa, {'numeric'}, {'scalar','finite','nonnegative'});
validateattributes(den_array, {'numeric'}, {'real','finite','nonnegative','size',size(img)});
[m.nx,m.ny]=size(img);
i0 = zeros(size(img));
attenuatedFraction = zeros(size(img));
den_array2=1-exp(-kappa*den_array);
product_terms = ones(size(den_array2));
den_array3=exp(-kappa*(den_array));
product_terms(1,:)=(den_array3(1,:))*0+1;
for i = 2:m.nx
    product_terms(i,:)=product_terms(i-1,:).*(den_array3(i,:));
end
for row = 1:m.nx
    for col= 1:m.ny
        i0(row,col)=img(row,col)./(den_array2(row,col).*product_terms(row,col));
        attenuatedFraction(row,col)=(den_array2(row,col).*product_terms(row,col));
    end
end
end
