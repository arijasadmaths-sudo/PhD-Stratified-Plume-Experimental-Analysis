function area_matrix=plif_precompute_area(m,wf,brays0)
% Form the sparse map from light-tube contributions to image pixels.
% No image or geometry cache is reused between calls.
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
fmatch=zeros(m.nx,tnpi);
max_entries = 4 * m.nx * m.ny;
rows = zeros(max_entries, 1);
cols = zeros(max_entries, 1);
vals = zeros(max_entries, 1);
entry_count = 0;
    area_matrix=spalloc(m.ny*m.nx,tnpi*m.nx,4*m.nx*m.ny);
    area_matrix2=spalloc(m.ny*m.nx,tnpi*m.nx,4*m.nx*m.ny);
    for ix=1:m.nx
        rtmp1 = rtmp;
        rtmp2 = rtmp;
        iarea_x = m.ny * (ix - 1);
        iarea_y = (0:m.nx-1) * tnpi;
        for isrc=1:nsrc
            npi = numel(rtmp1{isrc}.r);
            for jp=1:npi
                r0 = rtmp1{isrc}.r{jp};
                y00 = min(r0.y_l, r0.y_r);
                y01 = max(r0.y_l, r0.y_r);
                y10 = min(r0.y_l + r0.dy_l, r0.y_r + r0.dy_r);
                y11 = max(r0.y_l + r0.dy_l, r0.y_r + r0.dy_r);
                y0 = 0.5 * (y00 + y01);
                y1 = 0.5 * (y10 + y11);
                yn0 = min(y00, y10);
                yx0 = max(y00, y10);
                yn1 = min(y01, y11);
                yx1 = max(y01, y11);
                j0 = max(floor(yn0/m.dy), 1);
                j1 = min(ceil(yx1/m.dy), m.ny);
                fracs2 = zeros(1, m.ny);
                fracs2 = plif_overlap(m, y00, y10, y11, y01, yn0, yx0, yn1, yx1);
                fracs = find(fracs2);
                if isrc == 1
                    irl = jp;
                else
                    irl = sum(tnpi2(1:isrc - 1)) + jp;
                end
                num_new_entries = numel(fracs);
                rows(entry_count + (1:num_new_entries)) = iarea_x + fracs;
                cols(entry_count + (1:num_new_entries)) = irl + iarea_y(ix);
                vals(entry_count + (1:num_new_entries)) = fracs2(fracs);
                entry_count = entry_count + num_new_entries;
                rtmp2{isrc}.r{jp}.y_l = r0.y_l + r0.dy_l;
                rtmp2{isrc}.r{jp}.dy_l = r0.dy_l;
                rtmp2{isrc}.r{jp}.y_r = r0.y_r + r0.dy_r;
                rtmp2{isrc}.r{jp}.dy_r = r0.dy_r;
                rtmp2{isrc}.r{jp}.inten = r0.inten;
                rtmp1{isrc}.r{jp}.inten = r0.inten;
            end
        end
        rtmp = rtmp2;
    end
    rows = rows(1:entry_count);
    cols = cols(1:entry_count);
    vals = vals(1:entry_count);
    area_matrix = sparse(rows, cols, vals, m.ny * m.nx, tnpi * m.nx);
end
