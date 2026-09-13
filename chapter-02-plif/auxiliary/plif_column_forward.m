function img=plif_column_forward(I0,den_array,kappa1,kappa0)
% Generate fluorescence in parallel columns, with unit row spacing.
validateattributes(den_array, {'numeric'}, {'real','finite','nonnegative','2d'});
validateattributes(kappa1, {'numeric'}, {'scalar','finite','nonnegative'});
validateattributes(kappa0, {'numeric'}, {'scalar','finite','nonnegative'});
[m.nx,m.ny]=size(den_array);
validateattributes(I0, {'numeric'}, {'real','finite','nonnegative','vector'});
if ~isscalar(I0) && numel(I0) ~= m.ny
    error('PLIF:IncidentIntensity', 'Supply a scalar or one intensity per column.');
end
I0=I0(:)';
im_row2old=I0;
img=zeros(m.nx,m.ny);
for i=1:m.nx
    im_row2new=im_row2old.*exp(-(kappa1.*den_array(i,:)+kappa0));
    img(i,:)=[im_row2old-im_row2new];
    im_row2old=im_row2new;
end
end
