%
% parameters
%
ID = 'ON2013J07';

% logger output
filename = ['/home/work/data/', ID, '_cutdata.csv'];

% tidal prediction model out
tidefile = ['/home/work/tide/hout.bin'];

% Release and recover points
% [longitude, latitude, datenum(year, month, day [, hour, minute, second])]
%
% Use NaN if unknown.
RELEASE = [141.13, 38.24, datenum(2014, 6, 4)];
RECOVER  = [NaN, NaN, datenum(NaN, NaN, NaN)]; 

%
% parameters for tide fits
%
INITIAL = 13 * 60 * 60 / 5; % initial length of time series (13 hours)
STEP    = 3.25 * 60 * 60 / 5; % how long to extend when success (3.25 hours)
SIGMA   = 0.1 + 0.3;  % measurement error of the pressure gauge + surface wave (in meters)
TIMEORIGIN = datenum(2014,3,2,9,0,0);


%
% parameters for filteing
%
DEPTH_DIFF = 30; % m
MAX_DISTANCE_IN_DAY = 100; % m
NORTHERN_LIMIT = 44;
NORTHERN_LIMIT_PENALTY = 0;
TOO_BAD = 0.25; 
TEMP_DIF = 1;
PHASE_DIF= 0.087;
M2AMP_DIF= 100000;
TOO_FAST = 1.0; % m/s


%
% parameters for scoring
% if scoreA > scoreB then A is better than B
% see XXXX for detail.
%
WEIGHT = [(-1.0), ...  % speed
          (-1.0),  ... % time series length
          (-1.0), ...  % depth
          (-1.0), ...  % M2amp
          (-1.0), ...  % K1amp
          (-1.0/(2*pi)), ... % K1phase
          (-1.0), ...        % Temp
          (-0)               % Northern latitudes are worse
        ];


