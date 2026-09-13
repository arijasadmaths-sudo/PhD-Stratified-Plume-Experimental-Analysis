function i0=plif_ray_incident_estimates(img,dens,m,wf,brays0,rig)
% Auxiliary ray-based incident-intensity estimate.
% The input image must have one column per ray; this is not the main estimator.
dens2(:)=reshape(dens',[],1);
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
ray_loss=zeros(m.nx,tnpi);
for i = 1:m.nx
    rtmp1 = rtmp;
    rtmp2 = rtmp;
    for isrc=1:nsrc
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
            fracs2a=zeros(1,m.ny);
            [fracs2a] = plif_overlap(m,y00,y10,y11,y01,yn0, yx0, yn1, yx1);
            fracs=fracs2a;
            dyt = (y1 - y0);
            ds = sqrt(dyt^2 + m.dx^2);
            dtau = 0.0;
            for j = j0:j1
                icell = (i-1)*m.ny + j;
                fds = fracs(j) .* ds;
                fracs(j) = rig.sigma(dens2(icell)) * fds;
                dfrac(j) = rig.dsigma() * fds;
                dtau = dtau + fracs(j);
            end
            if isrc==1
                irl=jp;
            else
                irl=sum(tnpi2(1:isrc-1))+jp;
            end
            if dtau > 0.0
                rig_retained=0;
                rr2=1;
                for j = j0:j1
                    rr2=rr2*exp(-fracs(j));
                end
                rig_retained=rr2;
                ray_loss(i,irl)=rig_retained.^(1/ds);
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
i0 = zeros(size(ray_loss));
prods = zeros(size(ray_loss));
den_array2=1-ray_loss;
product_terms = ones(size(den_array2));
den_array3=ray_loss;
product_terms(1,:)=(den_array3(1,:))*0+1;
for i = 2:m.nx
    product_terms(i,:)=product_terms(i-1,:).*(den_array3(i,:));
end
product_terms2=product_terms;
i0(1,:)=img(1,:)./(den_array2(1,:));
for row = 2:m.nx
    for col= 1:tnpi
        i0(row,col)=img(row,col)./(den_array2(row,col).*product_terms2(row,col));
        prods(row,col)=(den_array2(row,col).*product_terms2(row,col));
    end
end
end
