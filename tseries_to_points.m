%
% timeseries to points
%
%
% Perform tidal fits on timeseries (logger output)
% and output candidate points.

% Variables all in capital designate global. Do not change (e.g. NX=...).
global NX NY NT DT;
global LONGITUDE LATITUDE;
global M2PERIOD K1PERIOD;
global TOPOLON TOPOLAT TOPOZ;

global hout; % only exception to the above rule

M2PERIOD = 12.42 / 24.0; % principal lunar tide
K1PERIOD = 23.93 / 24.0; % luni-solar diurnal tide

%
% The following 3 parameters are specified by the output
% of the tidal model (e.g. identical to those in naomain.f).
%
NX = 49; NY = 121; NT = 83232;
%
% The following 3 parameters are also specified by the tidal model
%
LONGITUDE = 140 + ([1:NX] - 1) / 12.0; % xs in naomain.f
LATITUDE  =  35 + ([1:NY] - 1) / 12.0; % ys in naomain.f
DT = 10;                               % dt in naomain.f

params;

%%%IO
%%%IO Read output from tidal prediction model.
%%%IO
[fid, msg] = fopen(tidefile, 'r', 'native');
if fid < 0, error(msg); end
buf = fread(fid, NX*NY*NT, 'float32');
fclose(fid);
buf(find(abs(buf + 999.999) < 1)) = NaN;
buf = buf * 0.01; % cm -> m
hout = reshape(buf, [NX, NY, NT]); % why fread(fid[NX,NY,NT],'float32') fails?
clear buf;  % too big to survive

%%%IO
%%%IO Read output from bathymetry data.
%%%IO
load 'topo.mat' tlon tlat topo;
TOPOLON = tlon; clear tlon;
TOPOLAT = tlat; clear tlat;
TOPOZ   = topo; clear topo;


%%%IO
%%%IO Read logger output
%%%IO
[t, dep,temperature] = read_my_data(filename);
t = t - TIMEORIGIN;

inloop = true; % flag
nstart = 1;
nend = nstart + INITIAL - 1;
points = [];
while nend <= length(dep)
    % try to extend the time series as long as possible
    while nend <= length(dep) && inloop 
        %
        % For an N-point timeseries with an expected error of SIGMA, we fit tidal time series
        % to estimate M unknowns. The residual (not error) follows chi-square disribution with
        % a degree of freedom (N-M).
        %
        % （P.660, below (15.1.5), Numerical Recipes in C 2nd Edition

        x = t(nstart:nend);   % time
        y = dep(nstart:nend); % depth

        semidiurnal = [cos(x * 2 * pi / M2PERIOD), sin(x * 2 * pi / M2PERIOD)];
        diurnal     = [cos(x * 2 * pi / K1PERIOD), sin(x * 2 * pi / K1PERIOD)];

        X0 = [ones(size(x)), semidiurnal, diurnal]; % fit this
        %
        % a linear component X0 = [x, ...] was tested but it overfits. So removed.
        %
        a = X0 \ y;      % Matlab's least square fit
        yfit = X0 * a;   % Estimated time series
        res = (y - yfit) ./ SIGMA; % residual normalised by error

        % visualise
        %clf; hold on;
        %plot(x + TIMEORIGIN, y, 'b');
        %plot(x + TIMEORIGIN, yfit, 'r');
        %grid on; datetick('x');
        %pause

        rsum = sum(res.^2); % squared sum of residual

        % If this residual is within the 95 %-tile of the chi-square fit,
        % the fit is successful, i.e., our "model" X0 is correct.
        %
        % Here N >> M, then N-M ~ N. If X follows a chi-square with DoF N,
        % sqrt(2X) follows a Gaussian with a mean sqrt(2N-1) and std.dev. = 1 (Fischer, reference?)
        % 2 sigma is 95.45%-tile, so the following conditition can be used.
        N = length(x);
        % debug
        %fprintf(2, '[%d,%d] rsum=%g compared with %g\n', nstart, nend, rsum, (sqrt(2*N-1)+2)^2/2);
        if rsum < (sqrt(2 * N - 1) + 2)^2 / 2
            % "model" OK. Extend the time series.
            nend = nend + STEP;
        else
            % "model" NG. Stop here
            inloop = false;
        end
    end % while inloop
    inloop = true;

    % "model" failed
    if nend - nstart + 1 == INITIAL % no success
        nstart = nstart + STEP;
        nend = nstart + INITIAL - 1;
        % debug
        %fprintf(2, 'repeating with n=[%d,%d]\n', nstart, nend);
    else                            % at least one success
        nend = nend - STEP;
        x = t(nstart:nend);
        y = dep(nstart:nend);
        semidiurnal = [cos(x * 2 * pi / M2PERIOD), sin(x * 2 * pi / M2PERIOD)];
        diurnal     = [cos(x * 2 * pi / K1PERIOD), sin(x * 2 * pi / K1PERIOD)];
        X0 = [ones(size(x)), semidiurnal, diurnal];
        a = X0 \ y;
        % visualise
        %figure(1); clf; hold on;
        %yfit = X0 * a;
        %plot(x + TIMEORIGIN, y, 'b');
        %plot(x + TIMEORIGIN, yfit, 'r');
        %grid on; datetick('x');
        %fprintf(2, '%s <-> %s\n', datestr(x(1) + TIMEORIGIN), datestr(x(end) + TIMEORIGIN));
        %pause
        
        tempHere = mean(temperature(nstart:nend));

        % candidate points, use another script.
        p = findLocation(t(nstart), t(nend), a, tempHere);

        if ~isempty(p)
            points = [points, p];
        end
        tmp = a(2) + sqrt(-1) * a(3);
        % next step
        nstart = nend;
        nend = nstart + INITIAL - 1;
    end
end  % while
%
% Save the result here
%
command = ['mv /tmp/tmp.mat result/', ID, '_1.mat'];
save '/tmp/tmp.mat' points;
system(command);
