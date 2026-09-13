function [img3,den3,i03] = plif_trial_fan_image(a,b,c,d_img,theta,m)
% Auxiliary synthetic fan in a prescribed rectangular image.
% The source lies at the middle of the left edge; theta is in degrees.
% This trial forward model is separate from the ray-tube model used for validation.
    validateattributes(d_img, {'numeric'}, {'2d','real','finite','nonnegative','nonempty'});
    validateattributes(theta, {'numeric'}, {'scalar','finite','>',0,'<',90});
    validateattributes(a, {'numeric'}, {'scalar','finite','nonnegative'});
    validateattributes(b, {'numeric'}, {'scalar','finite','nonnegative'});
    validateattributes(c, {'numeric'}, {'scalar','finite','nonnegative'});
    [rows, cols] = size(d_img);
    if mod(rows,2) || mod(cols,2) || mod(m.ny,2) || m.ny > rows || m.nx > cols
        error('PLIF:TrialGrid', 'Use even image dimensions and an even output width within the image.');
    end
    [x, y] = meshgrid(1:cols, 1:rows);
    cx = 0;
    cy = rows / 2;
    r = sqrt((x - cx).^2 + (y - cy).^2);
    angle = atan2d(y - cy, x - cx);
    mask = abs(angle) <= theta;
    img=zeros(cols,rows);
    n_diff2=zeros(cols,rows);
    for i=1:cols
        for j =1:rows
            n_diff=max(abs(i-cx),abs(j-cy))*2;
            n_diff2(i,j)=n_diff;
            d_interp = interp2(d_img, linspace(cx,i,n_diff), linspace(cy,j,n_diff), 'linear', 0);
            r2 = sqrt((i - cx).^2 + (j - cy).^2)*[1:n_diff]/n_diff;
            r3 = sqrt((i - cx).^2 + (j - cy).^2);
            integral_term = trapz(r2, (b .* d_interp + c) .* r2, 2);
            img(i,j) = a/r3 .* exp(-integral_term);
        end
    end
    img = img.*mask';
    img2=img.*(1-exp(-(b.*d_img'+c).*r'./n_diff2));
    img3=img2(cols-m.nx+1:cols,rows/2-m.ny/2+1:rows/2+m.ny/2);
    den3=d_img(rows/2-m.ny/2+1:rows/2+m.ny/2,cols-m.nx+1:cols)';
    raylines=linspace(-theta*pi/180,theta*pi/180,m.ny+1);
    for i = 1:m.ny
        rl(i)=(raylines(i)+raylines(i+1))/2;
        i03(i)=a*(2*theta)/360*abs(raylines(i)-raylines(i+1))/(2*theta*pi/180)*exp(-((b*d_img(rows/2,cols/2)+c)*(cols/2-cx)*tan(abs(rl(i)))));
    end
end
