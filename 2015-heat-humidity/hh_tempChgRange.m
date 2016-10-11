type = 'multi-model';
years = [2070, 2080];
percentiles = [10 25 75 90];

plotRegion = 'world';
plotRange = [0 10];
plotXUnits = 'degrees C';

% load lat/lon grid
load('e:\data\cmip5\output\access1-0\r1i1p1\historical\tasmax\regrid\world\19750101-19991231\tasmax_1975_01_01');
lat = tasmax_1975_01_01{1};
lon = tasmax_1975_01_01{2};
clear tasmax_1975_01_01;

load(['chg-data-tmax-' type '-' num2str(years(1)) '-' num2str(years(2)) '.mat']);

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
    
    plotTitle = ['Temperature change, ' num2str(prc) 'th percentile, ' num2str(years(1)) '-' num2str(years(2))];
    fileTitle = ['tasmaxChange-' type '-' num2str(prc) 'p-' num2str(years(1)) '-' num2str(years(2))];
    
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

