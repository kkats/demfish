function [datetime, depth, temp] = read_my_data(filename)
%

[fid, msg] = fopen(filename, 'r');
%[fid, msg] = fopen(testfile, 'r');
if fid < 0, error(msg); end

buf = textscan(fid,'%s%s%f%f', 'Delimiter', ',', 'HeaderLines', 1);
% n        = buf{1};
datetime0 = buf{2};
depth     = buf{3};
temp      = buf{4};

datetime1 = cell2mat(datetime0);
datetime = datenum(datetime1(:,2:20), 'yyyy/mm/dd HH:MM:SS');
%clf;
%ig = find(datenum(2013,9,17,0,0,0) <= datetime & datetime <= datenum(2013,9,24,0,0,0));
%plot(datetime(ig), depth(ig)); datetick('x', 'HH:MM');
end % function
