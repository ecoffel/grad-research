type = 'multi-model';
years = [2070, 2080];
percentiles = [10 50 90];

plotRegion = 'world';
plotRange = [0 10];
plotXUnits = 'degrees C';

meanStr = 'extreme';   
rcpStr = 'rcp45';
var = 'wb';

varTitle = 'Temperature';
if strcmp(var, 'wb')
    varTitle = 'Wet bulb temperature';
end

% load lat/lon grid
load('e:\data\cmip5\output\access1-0\r1i1p1\historical\tasmax\regrid\world\19750101-19991231\tasmax_1975_01_01');
lat = tasmax_1975_01_01{1};
lon = tasmax_1975_01_01{2};
clear tasmax_1975_01_01;

load(['chg-data-' var '-' rcpStr '-' type '-' meanStr '-' num2str(years(1)) '-' num2str(years(2)) '.mat']);

% eliminate nonsense gridboxes (usually near poles)
%chgData(chgData > 10) = NaN;

% sort changes
for x = 1:size(chgData, 1)
    for y = 1:size(chgData, 2)
        chgData(x, y, :) = sort(chgData(x, y, :));
    end
end

data = [];

for p = 1:length(percentiles)
    prc = percentiles(p);
    
    prcInd = [round(size(chgData, 3) * (prc/100.0))];
    data = chgData(:, :, prcInd);
    
    plotTitle = [varTitle ' change, ' num2str(prc) 'th percentile, ' num2str(years(1)) '-' num2str(years(2))];
    fileTitle = [var 'Change-' rcpStr '-' type '-' meanStr '-' num2str(prc) 'p-' num2str(years(1)) '-' num2str(years(2))];
    
    result = {lat, lon, data};
    saveData = struct('data', {result}, ...
                      'plotRegion', plotRegion, ...
                      'plotRange', plotRange, ...
                      'plotTitle', plotTitle, ...
                      'fileTitle', fileTitle, ...
                      'plotXUnits', plotXUnits, ...
                      'plotCountries', false, ...
                      'plotStates', false, ...
                      'blockWater', true);
    plotFromDataFile(saveData);
end

% plot the mean of the change distribution
plotTitle = [varTitle ' change, mean, ' num2str(years(1)) '-' num2str(years(2))];
fileTitle = [var 'Change-' rcpStr '-' type '-' meanStr '-mean-' num2str(years(1)) '-' num2str(years(2))];

result = {lat, lon, nanmean(chgData, 3)};
saveData = struct('data', {result}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', plotRange, ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', plotXUnits, ...
                  'plotCountries', false, ...
                  'plotStates', false, ...
                  'blockWater', true);
plotFromDataFile(saveData);

