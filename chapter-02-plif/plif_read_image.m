function img = plif_read_image(filename, cropRect)
% Read the image without choosing its intensity scale from the file type.
% Indexed images are expanded to the same 8-bit RGB form as the supplied code.
[img,map] = imread(filename);
if ~isempty(map)
    img = im2uint8(ind2rgb(img,map));
end
if ndims(img) > 2 && size(img,3) == 4
    img = img(:,:,1:3);
end
if isempty(cropRect)
    return
end
validateattributes(cropRect, {'numeric'}, {'real','finite','integer','numel',4,'positive'});
x = cropRect(1);
y = cropRect(2);
xEnd = x+cropRect(3)-1;
yEnd = y+cropRect(4)-1;
if xEnd > size(img,2) || yEnd > size(img,1)
    error('PLIF:Crop', 'The crop extends outside %s.',filename);
end
img = img(y:yEnd,x:xEnd,:);
end
