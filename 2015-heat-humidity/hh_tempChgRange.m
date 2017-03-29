type = 'multi-model';
years = [2070, 2080];
%percentiles = [10 50 90];
percentiles = [];

plotRegion = 'world';
plotRange = [0 8];
plotXUnits = 'Degrees C';

meanStr = 'extreme';   
rcpStr = 'rcp85';
var = 'wb';

varTitle = 'Temperature';
if strcmp(var, 'wb')
    varTitle = 'Wet bulb temperature';
end

% load lat/lon grid
load lat;
load lon;

load(['chg-data/chg-data-' var '-' rcpStr '-' type '-' meanStr '-' num2str(years(1)) '-' num2str(years(2)) '.mat']);

% remove bad grid cells
chgData(chgData > 10 | chgData < -5) = NaN;

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
                      'blockWater', false);
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
                  'blockWater', true, ...
                  'magnify', '2');
plotFromDataFile(saveData);

