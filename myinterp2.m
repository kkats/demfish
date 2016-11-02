function z0 = myinterp2(xi, yi, zi, x0, y0)
%
% Matlab's interp2() returns NaN if any input is NaN.
% This interp2 does its best to avoid NaN.
%
% Unlike interp2(), (x0, y0) must be scalar, NOT vector.
%
if size(zi) ~= [length(xi), length(yi)]
    error('myinterp2: size inconsistent');
end

% out of range
if x0 < min(xi) || x0 > max(xi) || y0 < min(yi) || y0 > max(yi)
    z0 = NaN;
    return;
end

dx = xi(2) - xi(1);
if max(abs(diff(xi) - dx)) / abs(dx) > 0.1
    error('uneven xi grid');
end

dy = yi(2) - yi(1);
if max(abs(diff(yi) - dy)) / abs(dy) > 0.1
    error('uneven yi grid');
end

m = floor((x0 - xi(1)) / dx) + 1;
n = floor((y0 - yi(1)) / dy) + 1;

alpha = (x0 - xi(m)) / dx;
beta  = (y0 - yi(n)) / dy;

if alpha < 0 || alpha > 1.0 || beta < 0 || beta > 1.0
    error('bug in myinterp2.m');
end

znw = zi(m,n+1); zne = zi(m+1,n+1);
zsw = zi(m,n);   zse = zi(m+1,n);

if ~isnan(znw + zne + zsw + zse)
    % all four data are not NaN
    z0 = zsw * (1 - alpha) * (1 - beta) ...
       + zse * alpha * (1 - beta) ...
       + znw * (1 - alpha) * beta ...
       + zne * alpha * beta;
else
    % if any NaN exist, take average without NaN
    z0 = nanmean([znw, zne, zsw, zse]);
end
end % function
