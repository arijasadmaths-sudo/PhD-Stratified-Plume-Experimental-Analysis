function result = plif_reconstruct(image_in, cali, cfg)
% Reconstruct a dimensionless field from one image and its calibration.
% The method uses one source, straight rays in the fluid and a field in [0,1].
% Rows follow the light propagation direction; distances are in image pixels.

validateattributes(cfg.resizeScale, {'numeric'}, {'scalar','finite','positive'});
validateattributes(cfg.intensityDivisor, {'numeric'}, {'scalar','finite','positive'});
validateattributes(cfg.calibrationScaleFactor, {'numeric'}, {'scalar','finite','positive'});
validateattributes(cfg.kappa0, {'numeric'}, {'scalar','finite','nonnegative'});

img0 = imageIntensity(image_in, cfg.intensityDivisor);
calibration = imageIntensity(cali, cfg.intensityDivisor) * cfg.calibrationScaleFactor;
if ~isequal(size(img0), size(calibration))
    error('PLIF:ImageSize', 'The calibration and image must have the same cropped dimensions.');
end
img = imresize(img0, cfg.resizeScale);
img_cs = imresize(calibration, cfg.resizeScale);
m.nx = size(img,1);
m.ny = size(img,2);
m.dx = 1;
m.dy = 1;
m.jcell = @(y) round(y / m.dy);

if isa(cfg.calibrationField, 'function_handle')
    den_array = cfg.calibrationField([m.nx m.ny]);
else
    den_array = cfg.calibrationField;
end
validateattributes(den_array, {'numeric'}, ...
    {'real','finite','size',[m.nx m.ny],'>=',0,'<=',1});

[ray_y, ray_dy] = generate_ray_initial(cfg.geometry, img0, m, m.ny);
ray_paths_all = {ray_y};
ray_path_dy_all = {ray_dy};
wf.brays = {struct('r', {cell(1,m.ny)})};
wf.tracks = {struct('i',1)};
for iray = 1:m.ny
    wf.brays{1}.r{iray} = struct('y_l',ray_y(iray), 'dy_l',ray_dy(iray), ...
        'y_r',ray_y(iray+1), 'dy_r',ray_dy(iray+1), 'inten',1);
end
brays0 = wf.brays;

den_array_lt = imageToLightTube(den_array,m,brays0,wf,0);
img_lt2 = imageToLightTube(img_cs,m,brays0,wf,1);
ds_array = generate_ds_array(ray_y,ray_dy,m);

% Keep the row/ds coordinate used in the supplied calibration fit.
% This is a fitting convention, not cumulative distance along the ray.
fitCoefficients = [NaN NaN];
if isempty(cfg.kappa1)
    validateattributes(cfg.attenuationFitRows, {'numeric'}, ...
        {'real','finite','integer','numel',2,'>=',1,'<=',m.nx});
    if cfg.attenuationFitRows(2) < cfg.attenuationFitRows(1)
        error('PLIF:FitRows', 'The last calibration row must follow the first.');
    end
    valid_cs = imageToLightTube(ones(size(img_cs)),m,brays0,wf,1) > 0;
    valid_cs(:,valid_cs(end,:) == 0) = false;
    fitRows = (1:m.nx)';
    valid_cs(fitRows < cfg.attenuationFitRows(1),:) = false;
    valid_cs(fitRows > cfg.attenuationFitRows(2),:) = false;
    range_csx = repmat(fitRows,1,m.ny) ./ ds_array;
    valid_cs = valid_cs & isfinite(img_lt2) & img_lt2 > 0 & isfinite(range_csx);
    fitX = range_csx(valid_cs);
    fitY = log(img_lt2(valid_cs));
    if numel(fitX) < 2 || max(fitX) == min(fitX)
        error('PLIF:CalibrationFit', 'The selected rows contain too few calibration points.');
    end
    fitCoefficients = polyfit(fitX,fitY,1);
    kappa1 = -fitCoefficients(1);
else
    kappa1 = cfg.kappa1;
end
validateattributes(kappa1, {'numeric'}, {'scalar','finite','positive'});
kappa0 = cfg.kappa0;
rig.dmin = 0;
rig.dmax = 1;
rig.refindex = @() cfg.geometry.refractiveIndices(3);
rig.sigma = @(d) kappa1*d+kappa0;
rig.dsigma = @() kappa1;

% Each row provides an estimate of the same incident ray intensity.
I0 = reCalcI0(img_lt2,den_array_lt,ds_array,m,kappa1,kappa0);
I0_val = zeros(1,m.ny);
for iray = 1:m.ny
    finiteValues = I0(isfinite(I0(:,iray)),iray);
    if ~isempty(finiteValues)
        I0_val(iray) = mean(finiteValues);
    end
    wf.brays{1}.r{iray}.inten = I0_val(iray);
end
if any(~isfinite(I0_val)) || any(I0_val < 0) || ~any(I0_val > 0)
    error('PLIF:IncidentIntensity', 'The calibration did not give usable incident intensities.');
end
brays0 = wf.brays;
imageVector = reshape(img',[],1);
dens = ones(m.nx*m.ny,1);
dens = rtrace(m,rig,imageVector,dens,wf,brays0);
density = reshape(dens',[m.ny,m.nx])';

% Forward projection can use the calibration estimate or supplied intensities.
forwardRays = brays0;
if ischar(cfg.forwardIncidentIntensity) || isstring(cfg.forwardIncidentIntensity)
    if ~strcmp(cfg.forwardIncidentIntensity,'calibration')
        error('PLIF:ForwardIntensity', 'Use ''calibration'' or numeric incident intensities.');
    end
    forwardI0 = I0_val;
else
    forwardI0 = cfg.forwardIncidentIntensity;
    validateattributes(forwardI0, {'numeric'}, {'real','finite','nonnegative','nonempty','vector'});
    if isscalar(forwardI0)
        forwardI0 = repmat(forwardI0,1,m.ny);
    end
    if numel(forwardI0) ~= m.ny
        error('PLIF:ForwardIntensity', 'Supply one incident intensity per reconstructed column.');
    end
end
for iray = 1:m.ny
    forwardRays{1}.r{iray}.inten = forwardI0(iray);
end
den_lt = imageToLightTube(density,m,brays0,wf,0);
[img_new,~,~] = generate_angled_image(m,den_lt,kappa1,kappa0, ...
    wf,forwardRays,ray_paths_all,ray_path_dy_all);
result = struct('reconstructedField',density, 'measuredFluorescence',img, ...
    'syntheticFluorescence',img_new, 'calibrationField',den_array, ...
    'incidentIntensityEstimates',I0, 'incidentIntensity',I0_val, ...
    'forwardIncidentIntensity',forwardI0, 'kappa0',kappa0, 'kappa1',kappa1, ...
    'attenuationFitCoefficients',fitCoefficients, 'gridSize',[m.nx m.ny]);
end

function img = imageIntensity(raw, divisor)
% Keep the channel average used in the original image processing.
validateattributes(raw, {'numeric','logical'}, {'real','finite','nonempty','nonnegative'});
if ndims(raw) == 2
    img = double(raw)/divisor;
elseif size(raw,3) == 3 || size(raw,3) == 4
    img = mean(double(raw(:,:,1:3))/divisor,3);
else
    error('PLIF:ImageChannels', 'Use a greyscale, RGB or RGBA image.');
end
end

function [ray_y,ray_dy] = generate_ray_initial(geometry,img,m,nrays)
% Refract the source fan through the wall and the unseen fluid above the crop.
validateattributes(geometry.sourceCoordinates, {'numeric'}, {'real','finite','numel',2});
validateattributes(geometry.refractiveIndices, {'numeric'}, {'real','finite','positive','numel',3});
validateattributes(geometry.wallThickness, {'numeric'}, {'scalar','finite','nonnegative'});
validateattributes(geometry.unseenFluidDepth, {'numeric'}, {'scalar','finite','nonnegative'});
validateattributes(geometry.fanHalfAngleDegrees, {'numeric'}, {'scalar','finite','>',0,'<',90});
x_pos = geometry.sourceCoordinates(1);
z_pos = geometry.sourceCoordinates(2);
n_air = geometry.refractiveIndices(1);
n_wall = geometry.refractiveIndices(2);
n_fluid = geometry.refractiveIndices(3);
d_wall = geometry.wallThickness;
d_fluid_unseen = geometry.unseenFluidDepth;
theta_fan_air = geometry.fanHalfAngleDegrees*pi/180;
if abs(n_air/n_wall*sin(theta_fan_air)) > 1 || abs(n_air/n_fluid*sin(theta_fan_air)) > 1
    error('PLIF:Refraction', 'The supplied fan does not give real refracted angles.');
end
theta_fan_wall = asin(n_air/n_wall*sin(theta_fan_air));
theta_fan_fluid = asin(n_air/n_fluid*sin(theta_fan_air));
d_air = ((-z_pos-d_fluid_unseen)*tan(theta_fan_fluid) ...
    - d_wall*tan(theta_fan_wall))/tan(theta_fan_air);
if d_air < 0
    error('PLIF:SourceGeometry', 'The source and layer depths imply a negative air path.');
end
theta_angle_air = linspace(-theta_fan_air,theta_fan_air,nrays+1)';
theta_angle_wall = asin(n_air/n_wall*sin(theta_angle_air));
theta_angle_fluid = asin(n_air/n_fluid*sin(theta_angle_air));
ray_y = (x_pos+d_air*tan(theta_angle_air)+d_wall*tan(theta_angle_wall) ...
    +d_fluid_unseen*tan(theta_angle_fluid))*m.nx/size(img,1);
ray_dy = tan(theta_angle_fluid);
end

function [dens]=rtrace(m, rig, image, dens, wf, brays0)
% March through the image and solve each row by bounded Newton iteration.
dens(:) = 0.5 ;
nsrc = numel(wf.brays);
rtmp = brays0;
rtmp1 = brays0;
ttmp = wf.tracks;
ttmp1 = wf.tracks;
rdv = 1.0 / (m.dx * m.dy);
im1 = zeros(1, m.ny);
dim1 = zeros(1, m.ny);
dfrac = zeros(1, m.ny);
ref0 = zeros(m.nx * m.ny, 1);
tnpi=0;
for isrc=1:nsrc
    npi = numel(rtmp1{isrc}.r);
    tnpi=tnpi+npi;
    tnpi2(isrc)=npi;
end
for i = 1:m.nx
    for it = 1:20
        rtmp1 = rtmp;
        rtmp2 = rtmp;
        ttmp1 = ttmp;
        for j = 1:m.ny
            icell = (i-1)*m.ny + j;
            ref0(icell) = rig.refindex();
        end
        im1(:) = 0;
        dim1(:) = 0;
        for isrc = 1:nsrc
            npi = numel(rtmp1{isrc}.r);
            for jp = 1:npi
                r0 = rtmp1{isrc}.r{jp};
                y00 = min(r0.y_l, r0.y_r);
                y01 = max(r0.y_l, r0.y_r);
                y10 = min(r0.y_l+r0.dy_l, r0.y_r+r0.dy_r);
                y11 = max(r0.y_l+r0.dy_l, r0.y_r+r0.dy_r);
                y0 = 0.5 * (y00 + y01);
                y1 = 0.5 * (y10 + y11);
                yn0 = min(y00, y10);
                yx0 = max(y00, y10);
                yn1 = min(y01, y11);
                yx1 = max(y01, y11);
                j0 = max(floor(yn0/m.dy), 1);
                j1 = min(ceil(yx1/m.dy), m.ny);
                if j1 < 0 || j0 > m.ny
                    continue;
                end
                [fracs2] = calcbfracs2a(m,y00,y10,y11,y01,yn0, yx0, yn1, yx1);
                fracs=fracs2;
                dyt = (y1 - y0);
                ds = sqrt(dyt^2 + m.dx^2);
                dtau = 0.0;
                for j = j0:j1
                    icell = (i-1)*m.ny + j;
                    fds = fracs(j) .* ds;
                    fracs(j) = rig.sigma(dens(icell)) * fds;
                    dfrac(j) = rig.dsigma() * fds;
                    dtau = dtau + fracs(j);
                end
                if dtau > 0.0
                    i1 = r0.inten * exp(-dtau);
                    loss = (r0.inten - i1) * rdv/ dtau;
                    dloss = (rdv * i1- loss)/dtau;
                    r0.inten = i1;
                    for j = j0:j1
                        im1(j) = im1(j) + loss * fracs(j);
                        dim1(j) = dim1(j) + (loss+fracs(j) * dloss)*dfrac(j);
                    end
                end
                rtmp2{isrc}.r{jp}.y_l=r0.y_l+r0.dy_l;
                rtmp2{isrc}.r{jp}.dy_l=r0.dy_l;
                rtmp2{isrc}.r{jp}.y_r=r0.y_r+r0.dy_r;
                rtmp2{isrc}.r{jp}.dy_r=r0.dy_r;
                rtmp2{isrc}.r{jp}.inten=r0.inten;
                rtmp1{isrc}.r{jp}.inten=r0.inten;
                ray_end(i,jp)=r0.inten;
            end
        end
        relativeError = 0.0;
        for j = 1:m.ny
            if im1(j) ~= 0.0
                icell = (i-1)*m.ny + j;
                scale = image(icell) / im1(j);
                d = dens(icell) - (im1(j) - image(icell)) / dim1(j);
                d = max(min(d, rig.dmax), rig.dmin);
                dens(icell) = d;
                relerr = abs(scale - 1.0);
                relativeError = max(relativeError, relerr);
            end
        end
        if relativeError < 1e-6
            break;
        end
    end
    rtmp = rtmp2;
    ttmp = ttmp1;
end
end

function frac = calcbfracs2a(m, y00,y10,y11,y01,yn0, yx0, yn1, yx1)
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

function img_lt=imageToLightTube(img,m,brays0,wf,isIM)
% Average over each light tube; fluorescence also includes its cross-section.
    nsrc = numel(wf.brays);
    rtmp = brays0;
    rtmp1 = brays0;
    rdv = 1.0 / (m.dx * m.dy);
    tnpi=0;
    for isrc=1:nsrc
        npi = numel(rtmp1{isrc}.r);
        tnpi=tnpi+npi;
        tnpi2(isrc)=npi;
    end
    img_lt=zeros(m.nx,tnpi);
    fmatch=zeros(m.nx,tnpi);
    for ix=1:m.nx
        rtmp1 = rtmp;
        rtmp2 = rtmp;
        for isrc=1:nsrc
            npi = numel(rtmp1{isrc}.r);
            for jp=1:npi
                r0 = rtmp1{isrc}.r{jp};
                    y00 = min(r0.y_l, r0.y_r);
                    y01 = max(r0.y_l, r0.y_r);
                    y10 = min(r0.y_l+r0.dy_l, r0.y_r+r0.dy_r);
                    y11 = max(r0.y_l+r0.dy_l, r0.y_r+r0.dy_r);
                    y0 = 0.5 * (y00 + y01);
                    y1 = 0.5 * (y10 + y11);
                    yn0 = min(y00, y10);
                    yx0 = max(y00, y10);
                    yn1 = min(y01, y11);
                    yx1 = max(y01, y11);
                    j0 = max(floor(yn0/m.dy), 1);
                    j1 = min(ceil(yx1/m.dy), m.ny);
                    fracs2=zeros(1,m.ny);
                    [fracs2] = calcbfracs2a(m,y00,y10,y11,y01,yn0, yx0, yn1, yx1);
                    atot = 0.5 * (yn1 + yx1 - yn0 - yx0);
                    if isrc==1
                        irl=jp;
                    else
                        irl=sum(tnpi2(isrc-1))+jp;
                    end
                    dyt = (y1 - y0);
                    ds = sqrt(dyt^2 + m.dx^2);
                    if isIM==0
                        atot=1;
                    end
                    sum_fracs = sum(fracs2(j0:j1));
                    if sum_fracs > 0
                        img_lt(ix, irl) = sum(fracs2(j0:j1) .* img(ix, j0:j1))*atot / sum_fracs;
                    else
                        img_lt(ix, irl) = 0;
                    end
                    rtmp2{isrc}.r{jp}.y_l=r0.y_l+r0.dy_l;
                    rtmp2{isrc}.r{jp}.dy_l=r0.dy_l;
                    rtmp2{isrc}.r{jp}.y_r=r0.y_r+r0.dy_r;
                    rtmp2{isrc}.r{jp}.dy_r=r0.dy_r;
                    rtmp2{isrc}.r{jp}.inten=r0.inten;
                    rtmp1{isrc}.r{jp}.inten=r0.inten;
            end
        end
        rtmp = rtmp2;
    end
end

function [img,img_lt,I0]=generate_angled_image(m,den_array_lt,kappa1,kappa0,wf,brays0,ray_paths_all,ray_path_dy_all)
% Attenuate each ray, then distribute its fluorescence across the image.
    ds_array=[];
    for isrc=1:numel(ray_paths_all)
    ray_paths = ray_paths_all{isrc};
    ray_path_dy = ray_path_dy_all{isrc};
    ray_paths4=ray_paths;
    ds_array=horzcat(ds_array,generate_ds_array(ray_paths,ray_path_dy,m));
    end
    nsrc = numel(wf.brays);
    rtmp = brays0;
    rtmp1 = brays0;
    rdv = 1.0 / (m.dx * m.dy);
    tnpi=0;
    for isrc=1:nsrc
        npi = numel(rtmp1{isrc}.r);
        tnpi=tnpi+npi;
        tnpi2(isrc)=npi;
    end
    I0=zeros(1,tnpi);
    rayCounter=0;
    for isrc=1:nsrc
        for jp=1:numel(brays0{isrc}.r)
            rayCounter=rayCounter+1;
            I0(rayCounter)=brays0{isrc}.r{jp}.inten;
        end
    end
    if any(~isfinite(I0)) || all(I0==0)
        error(['Invalid incident-intensity array in forward reconstruction. ' ...
            'Check the calibration-derived I0 values.'])
    end
    in_lt=zeros(m.nx+1,tnpi);
    in_lt(1,:)=I0;
    img_lt=zeros(m.nx,tnpi);
    for i = 2:m.nx+1
        in_lt(i,:)=in_lt(i-1,:).*exp(-(kappa1*den_array_lt(i-1,:)+kappa0).*ds_array(i-1,:));
    end
    for i= 1:m.nx
        img_lt(i,:)=(in_lt(i,:)-in_lt(i+1,:));
    end
    img=zeros(m.nx,m.ny);
    for ix=1:m.nx
        rtmp1 = rtmp;
        rtmp2 = rtmp;
        imsum=zeros(1,m.ny);
        for isrc=1:nsrc
            npi = numel(rtmp1{isrc}.r);
            for jp=1:npi
                r0 = rtmp1{isrc}.r{jp};
                    y00 = min(r0.y_l, r0.y_r);
                    y01 = max(r0.y_l, r0.y_r);
                    y10 = min(r0.y_l+r0.dy_l, r0.y_r+r0.dy_r);
                    y11 = max(r0.y_l+r0.dy_l, r0.y_r+r0.dy_r);
                    y0 = 0.5 * (y00 + y01);
                    y1 = 0.5 * (y10 + y11);
                    yn0 = min(y00, y10);
                    yx0 = max(y00, y10);
                    yn1 = min(y01, y11);
                    yx1 = max(y01, y11);
                j0 = max(floor(yn0/m.dy), 1);
                j1 = min(ceil(yx1/m.dy), m.ny);
                fracs2a=zeros(1,m.ny);
                [fracs2a] = calcbfracs2a(m,y00,y10,y11,y01,yn0, yx0, yn1, yx1);
                if isrc==1
                        irl=jp;
                    else
                        irl=sum(tnpi2(isrc-1))+jp;
                end
                atot = 0.5 * (yn1 + yx1 - yn0 - yx0);
                for j = j0:j1
                    img(ix,j)=img(ix,j)+fracs2a(j)*img_lt(ix,irl);
                    imsum(j)=imsum(j)+fracs2a(j);
                end
                rtmp2{isrc}.r{jp}.y_l=r0.y_l+r0.dy_l;
                rtmp2{isrc}.r{jp}.dy_l=r0.dy_l;
                rtmp2{isrc}.r{jp}.y_r=r0.y_r+r0.dy_r;
                rtmp2{isrc}.r{jp}.dy_r=r0.dy_r;
                rtmp2{isrc}.r{jp}.inten=r0.inten;
                rtmp1{isrc}.r{jp}.inten=r0.inten;
            end
        end
        rtmp = rtmp2;
    end
end

function ds_array=generate_ds_array(ray_paths,ray_path_dy,m)
% Find the distance travelled by the centre of each tube in one image row.
    ray_paths4=ray_paths;
    for i = 1:m.nx
    ray_cols=[ray_paths4(1:end-1)';ray_paths4(2:end)';ray_paths4(1:end-1)'+ray_path_dy(1:end-1)';ray_paths4(2:end)'+ray_path_dy(2:end)']';
    y00=min(ray_cols(:,[1;2]),[],2);
    y01=max(ray_cols(:,[1,2]),[],2);
    y10=min(ray_cols(:,[3,4]),[],2);
    y11=max(ray_cols(:,[3,4]),[],2);
    y0 = 0.5 * (y00 + y01);
    y1 = 0.5 * (y10 + y11);
    dyt = (y1 - y0);
    ds2 = (dyt.^2 + m.dx.^2).^0.5;
    ds_array(i,:)=ds2';
    yn0= min([y00,y10],[],2);
    yx0= max([y00,y10],[],2);
    yn1= min([y01,y11],[],2);
    yx1= max([y01,y11],[],2);
    atot = 0.5 * (yn1 + yx1 - yn0 - yx0);
    atot_array(i,:)=atot';
    ray_path2(i,:)=ray_paths4;
    ray_paths4=ray_paths4+ray_path_dy;
    end
end

function I0=reCalcI0(img_lt,den_array_lt,ds_array,m,kappa1,kappa0)
% Recover the incident intensity from the known calibration field.
    I0_guess=zeros(size(img_lt));
    atten_products=ones(size(img_lt));
    attenuation=(exp(-(kappa1.*den_array_lt+kappa0).*ds_array));
    for ix=2:m.nx
        atten_products(ix,:)=atten_products(ix-1,:).*attenuation(ix-1,:);
    end
    for ix=1:m.nx
        if ix>1
            I0_guess(ix,:)=img_lt(ix,:)./(atten_products(ix,:).*(1-attenuation(ix,:)));
        else
            I0_guess(ix,:)=img_lt(ix,:)./(1-attenuation(ix,:));
        end
    end
    I0=I0_guess;
end
