% 1, 1000 mb
% 7, 850 mb
% 17, 500 mb
% 21, 300 mb
% 25, 200 mb

function [pressureIndex] = narrPlevIndex(pressure)
    pressureLevels = [1000 850 500 300 200];
    pressureIndex = find(pressureLevels == pressure);
end
    