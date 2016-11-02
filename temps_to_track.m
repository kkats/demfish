function temps_to_track

params;

% constants
ONESECOND = 1.0 / 24.0 / 3600.0;
RELEASE(3) = RELEASE(3) - TIMEORIGIN;
RECOVER(3) = RECOVER(3) - TIMEORIGIN;

eval(['load ''', inputfile, '''']); % read output from points_with_temps.m
%
% STEP 1
% Group all points according to time stamps
%
ngroup = 1;
timestamp = [NaN, NaN]; now = [];
ndata = length(points);
group = NaN(1,ndata); % This is group. Serves as flag as well. Bad points have group < 0.
for n = 1:ndata
    % fist step
    if any(isnan(timestamp))
        timestamp = [points(n).since, points(n).until];
        group(n) = ngroup;
    % same time when difference is less than 1 second
    elseif abs(points(n).since - timestamp(1)) < ONESECOND ...
        && abs(points(n).until - timestamp(2)) < ONESECOND
        group(n) = ngroup;
    else
        % if not same time, it's the next points
        timestamp = [points(n).since, points(n).until];
        ngroup = ngroup + 1;
        group(n) = ngroup;
    end
end 
ngroup = max(group);
%
% STEP 2
% Filtering
%
for n = 1:ndata
    d = examine(points(n));

    % bad if any of below is met
    if   abs(d(4)) > M2AMP_DIF ... % M2 amp
      || abs(d(5)) > K1AMP_DIF ... % K1 amp
      || abs(d(6)) > PHASE_DIF ... % K1 phase
      || abs(d(7)) > TEMP_DIF  ... % temperature
         group(n) = -1;  % BAD
    end
end
%
% STEP 3
% Speed filtering
%
prev = [];
start_from_release = 1; % flags
for m = 1:(ngroup+1)
    now = find(group == m);
    all_bad = 1;
    % from RELEASE
    if start_from_release
        for k = 1:length(now)
            kk = now(k);
            sp = speed([RELEASE(1), points(kk).longitude], ...
                       [RELEASE(2), points(kk).latitude], ...
                       [RELEASE(3), points(kk).since]);
            % NaN is "good"
            if ~isnan(sp) && abs(sp) > TOO_FAST
                group(kk) = -2; % BAD
            else
                all_bad = 0;
            end
        end
    % to RECOVER
    elseif m == (ngroup + 1)
        for q = 1:length(prev)
            qq = prev(q);
            sp = speed([points(qq).longitude, RECOVER(1)], ...
                       [points(qq).latitude, RECOVER(2)], ...
                       [points(qq).until, RECOVER(3)]);
            if ~isnan(sp) && abs(sp) > TOO_FAST
                group(qq) = -2; % BAD
            end
        end
    % from every member of prev to every member of now
    else
        for k = 1:length(now)
            kk = now(k);
            good = 0;
            for q = 1:length(prev)
                qq = prev(q);
                sp = speed([points(qq).longitude, points(kk).longitude], ...
                           [points(qq).latitude, points(kk).latitude], ...
                           [points(qq).until, points(kk).since]);
                if isnan(sp) || (~isnan(sp) && abs(sp) <= TOO_FAST)
                    good = 1;
                end
            end
            if good == 0 % kk unreachable from all points in prev with speed <= TOO_FAST
                group(kk) = -2;
            else         % kk reachable from some point(s) in prev with speed <= TOO_FAST
                all_bad = 0;
            end
        end
    end
    if all_bad == 0
        prev = now;
        start_from_release = 0;
    end
end
%
% STEP 4
% Scoring
%
prev = [];
start_from_release = 1;
goodpoints = [];
badpoints = [];
for m = 1:ngroup
    now = find(group == m);
    if isempty(now)
        continue;
    end
    if start_from_release
        ig = [];
        for k = 1:length(now)
            kk = now(k);
            sp = speed([RELEASE(1), points(kk).longitude], ...
                       [RELEASE(2), points(kk).latitude], ...
                       [RELEASE(3), points(kk).since]);
            if isnan(sp) || abs(sp) < TOO_FAST
                ig = [ig, kk];
            end
        end
        if length(ig) > 1 % scoring with multiple points
            sc = [];
            for k = 1:length(ig)
                sc = [sc, score(points(ig(k)), WEIGHT, SCORE_SIGMA)];
            end
            [dummy, idx] = max(sc);
            goodpoints = [goodpoints, points(ig(idx))];
            for k = 1:length(ig)
                if k ~= idx
                    badpoints = [badpoints, points(ig(k))];
                end
            end
            prev = points(ig(idx));
            start_from_release = 0;
        else             % no scoring
            goodpoints = [goodpoints, points(ig(1))];
            prev = points(ig(1));
            start_from_release = 0;
        end
    else
        ig = [];
        for k = 1:length(now)
            kk = now(k);
            sp = speed([prev.longitude, points(kk).longitude], ...
                       [prev.latitude, points(kk).latitude], ...
                       [prev.until, points(kk).since]);
            if isnan(sp) || abs(sp) < TOO_FAST
                ig = [ig, kk];
            end
        end
        if length(ig) > 1 % scoring
            sc = [];
            for k = 1:length(ig)
                sc = [sc, score(points(ig(k)), WEIGHT, SCORE_SIGMA)];
            end
            [dummy, idx] = max(sc);
            goodpoints = [goodpoints, points(ig(idx))];
            for k = 1:length(ig)
                if k ~= idx
                    badpoints = [badpoints, points(ig(k))];
                end
            end
            prev = points(ig(idx));
        else              % no scoring
            goodpoints = [goodpoints, points(ig(1))];
            prev = points(ig(1));
        end
    end
end
%
% output
%
[fid, msg] = fopen(outputfile, 'w');
if fid < 0, error(msg); end

fprintf(fid,'No,date1,time1,date2,time2,lon,lat,sp,Fitlength,Depth,M2amp,K1amp,K1phase,Temp,Score\n');

% simle figure
clf; hold on;
load '/home/yusuke/work/topo.mat';
contour(tlon, tlat, topo',[10,20,30,40,50,100,200,300,400,500,1000]);
if ~any(isnan(RELEASE))
    label = datestr(RELEASE(3) + TIMEORIGIN, 'mm/dd');
    plot(RELEASE(1), RELEASE(2), 'x', 'MarkerSize', 12);
    text(RELEASE(1), RELEASE(2), label);
end
%
% candidates
%
for m = 1:(length(goodpoints)+1)
    if m == 1
        p = goodpoints(m);
        sp = speed([RELEASE(1), p.longitude], ...
                   [RELEASE(2), p.latitude], ...
                   [RELEASE(3), p.since]);
    elseif m == length(goodpoints)+1
        p = goodpoints(m-1);
        sp = speed([p.longitude, RECOVER(1)], ...
                   [p.latitude, RECOVER(2)], ...
                   [p.until, RECOVER(3)]);
    else
        p = goodpoints(m);
        sp = speed([goodpoints(m-1).longitude, p.longitude], ...
                   [goodpoints(m-1).latitude, p.latitude], ...
                   [goodpoints(m-1).until, p.since]);
    end
    if m == length(goodpoints)+1
        if ~isnan(sp)
            [y0, m0, d0, h0, mi0 s0] = datevec(RECOVER(3) + TIMEORIGIN);
            fprintf(fid, '%d,%4d/%2d/%2d,%2.0f:%2.0f:%2.0f,9999/99/99,99:99:99,%10.3f,%10.3f,%10.3f,9.999,9.999,9.999,9.999,9.999,9.999,9.999\n',...
                        m, ...
                        y0, m0, d0, h0, mi0, s0, ...
                        REVOER(1), RECOVER(2), sp);
        end
    else
        sc = score(p, WEIGHT, SCORE_SIGMA);
        df = examine(p);

        [y0, m0, d0, h0, mi0 s0] = datevec(p.since + TIMEORIGIN);
        [y1, m1, d1, h1, mi1,s1] = datevec(p.until + TIMEORIGIN);
        fprintf(fid, '%d,%4d/%2d/%2d,%2.0f:%2.0f:%2.0f,%4d/%2d/%2d,%2.0f:%2.0f:%2.0f,%10.3f,%10.3f,%10.3f,%8.3f,%8.3f,%8.3f,%8.3f,%8.3f,%8.3f,%12.3f\n',...
                        m, ...
                        y0, m0, d0, h0, mi0, s0, ...
                        y1, m1, d1, h1, mi1, s1, ...
                        p.longitude, p.latitude, sp,...
                        df(2), df(3), df(4), df(5), df(6), df(7), sc);
        label = sprintf('(%d) %02d/%02d-%02d/%02d', m, m0, d0, m1, d1);
        plot(p.longitude, p.latitude, 'o');
        text(p.longitude, p.latitude, label);
    end
end
%
% points with good speed but bad score
%
fprintf(fid, '99999,9999/99/99,99:99:99,9999/99/99,99:99:99,999.999,999.999,999.999,9.999,9.999,9.999,9.999,9.999,9.999,9.999\n');
for m = 1:length(badpoints)
    p = badpoints(m);
    sc = score(p, WEIGHT, SCORE_SIGMA);
    df = examine(p);
    [y0, m0, d0, h0, mi0 s0] = datevec(p.since + TIMEORIGIN);
    [y1, m1, d1, h1, mi1,s1] = datevec(p.until + TIMEORIGIN);
    fprintf(fid, '%d,%4d/%2d/%2d,%2.0f:%2.0f:%2.0f,%4d/%2d/%2d,%2.0f:%2.0f:%2.0f,%10.3f,%10.3f,%10.3f,%8.3f,%8.3f,%8.3f,%8.3f,%8.3f,%8.3f,%12.3f\n',...
                        m, ...
                        y0, m0, d0, h0, mi0, s0, ...
                        y1, m1, d1, h1, mi1, s1, ...
                        p.longitude, p.latitude, NaN,...
                        df(2), df(3), df(4), df(5), df(6), df(7), sc);
end
%
% points with bad speed
%
fprintf(fid, '99999,9999/99/99,99:99:99,9999/99/99,99:99:99,999.999,999.999,999.999,9.999,9.999,9.999,9.999,9.999,9.999,9.999\n');
now = find(group == -2);
for m = 1:length(now)
    p = points(now(m));
    sc = score(p, WEIGHT, SCORE_SIGMA);
    df = examine(p);
    [y0, m0, d0, h0, mi0 s0] = datevec(p.since + TIMEORIGIN);
    [y1, m1, d1, h1, mi1,s1] = datevec(p.until + TIMEORIGIN);
    fprintf(fid, '%d,%4d/%2d/%2d,%2.0f:%2.0f:%2.0f,%4d/%2d/%2d,%2.0f:%2.0f:%2.0f,%10.3f,%10.3f,%10.3f,%8.3f,%8.3f,%8.3f,%8.3f,%8.3f,%8.3f,%12.3f\n',...
                        m, ...
                        y0, m0, d0, h0, mi0, s0, ...
                        y1, m1, d1, h1, mi1, s1, ...
                        p.longitude, p.latitude, NaN,...
                        df(2), df(3), df(4), df(5), df(6), df(7), sc);
end
%
% points removed by filtering
%
fprintf(fid, '99999,9999/99/99,99:99:99,9999/99/99,99:99:99,999.999,999.999,999.999,9.999,9.999,9.999,9.999,9.999,9.999,9.999\n');
now = find(group == -1);
for m = 1:length(now)
    p = points(now(m));
    sc = score(p, WEIGHT, SCORE_SIGMA);
    df = examine(p);
    [y0, m0, d0, h0, mi0 s0] = datevec(p.since + TIMEORIGIN);
    [y1, m1, d1, h1, mi1,s1] = datevec(p.until + TIMEORIGIN);
    fprintf(fid, '%d,%4d/%2d/%2d,%2.0f:%2.0f:%2.0f,%4d/%2d/%2d,%2.0f:%2.0f:%2.0f,%10.3f,%10.3f,%10.3f,%8.3f,%8.3f,%8.3f,%8.3f,%8.3f,%8.3f,%12.3f\n',...
                        m, ...
                        y0, m0, d0, h0, mi0, s0, ...
                        y1, m1, d1, h1, mi1, s1, ...
                        p.longitude, p.latitude, NaN,...
                        df(2), df(3), df(4), df(5), df(6), df(7), sc);
end

fclose(fid);
end % function
%
%
% diffrence between our "model" and logger data
%
function diff = examine(p)
    diff = NaN(1,7);
    phasediff = p.k1phsmodel - p.k1phsfish;
    if phasediff < -pi
        phasediff = phasediff + 2.0 * pi;
    else
        if phasediff > pi
            phasediff = phasediff - 2.0 * pi;
        end
    end
    % diff(1) = w(1) * speed; % not used now
    diff(2) = p.until - p.since;
    diff(3) = p.datadepth - p.depthfish;
    diff(4) = p.m2ampmodel - p.m2ampfish;
    diff(5) = p.k1ampmodel - p.k1ampfish;
    diff(6) = phasediff;
    diff(7) = p.tempfish - p.tempmodel;
end % function						
function sc = score(p, w, s)
    df = examine(p);
    sc =  nansum(w(2:7) .* df(2:7) ./ s(2:7));
end % function
% lons = [lon1, lon2]
% lats = [lat1, lat2]
% tims = [tim1, tim2] in "day"
% s is speed in "m/s"
function s = speed(lons, lats, tims)
    distance = mydistance(lons, lats);
    s = distance / ((tims(2) - tims(1)) * 24.0 * 3600.0);
end
