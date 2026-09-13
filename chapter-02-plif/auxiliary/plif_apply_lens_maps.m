function corrected = plif_apply_lens_maps(img,mappingStore,refractX,refractZ,compensateArea,cropRect,outputRows)
% Apply supplied lens and refraction maps to a greyscale image.
% Map construction requires a separate optical calibration for the system.
% cropRect uses [x y width height] after refraction; [] keeps the whole image.
validateattributes(img, {'numeric'}, {'2d','real','nonempty'});
validateattributes(refractX, {'numeric'}, {'2d','real','nonempty'});
validateattributes(refractZ, {'numeric'}, {'2d','real','size',size(refractX)});
validateattributes(compensateArea, {'logical'}, {'scalar'});
I = double(img);
for i = 1:numel(mappingStore)
    I = interp2(I,mappingStore(i).G_hori,mappingStore(i).G_vert);
end
[dxX,dzX] = gradient(refractX);
[dxZ,dzZ] = gradient(refractZ);
detJ = abs(dxX.*dzZ-dzX.*dxZ);
detJ(detJ < 1e-6) = 1;
corrected = interp2(I,refractX,refractZ);
if compensateArea
    corrected = corrected./detJ;
end
if ~isempty(cropRect)
    validateattributes(cropRect, {'numeric'}, {'numel',4,'integer','positive'});
    x = cropRect(1);
    y = cropRect(2);
    xEnd = x+cropRect(3)-1;
    yEnd = y+cropRect(4)-1;
    if xEnd > size(corrected,2) || yEnd > size(corrected,1)
        error('PLIF:LensCrop', 'The crop extends beyond the corrected image.');
    end
    corrected = corrected(y:yEnd,x:xEnd);
end
if ~isempty(outputRows)
    validateattributes(outputRows, {'numeric'}, {'scalar','integer','positive'});
    corrected = imresize(corrected,[outputRows NaN]);
end
end
