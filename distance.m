function dr = distance(longitudes, latitudes)
%
% calculate distance between 2 points specified by lat-lon (in degrees)
%
dy = latitudes(2) - latitudes(1);
dx = (longitudes(2) - longitudes(1)) * cos(mean(latitudes) * 3.14159 / 180.0);

dr = 111.1e3 * sqrt(dx^2 + dy^2);
end
