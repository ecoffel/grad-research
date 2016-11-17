decade = 2070;
rcp = 'rcp85';
thresh = 35;

baseDir = 'selGrid/';

load lat;
load lon;

mapData = [];

numScenarios = 34;
if strcmp(rcp, 'rcp85') || strcmp(rcp, 'rcp45')
    numScenarios = 18;
end

% loop through all scenarios
for s = 1:numScenarios
    load([baseDir 'selGrid-' num2str(decade) 's-' rcp '-' num2str(thresh) 'C-scenario-' num2str(s)]);
    
    mapData(:, :, s) = selGrid;
    
    clear selGrid;
end

ind10 = round(0.1 * size(mapData, 3));
ind90 = round(0.9 * size(mapData, 3));

mapData(mapData == 0) = NaN;
result = {lat, lon, mapData(:, :, ind10)};
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [0 30], ...
                  'plotTitle', [num2str(thresh) 'C wet bulb events, 2070s, 10th percentile'], ...
                  'fileTitle', ['exceedenceMap-' num2str(thresh) 'C-' rcp '-' num2str(thresh) 'c-' num2str(decade) '-10p.pdf'], ...
                  'plotXUnits', 'Occurrences per year', ...
                  'blockWater', true);
plotFromDataFile(saveData);


result = {lat, lon, round(nanmean(mapData, 3))};
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [0 30], ...
                  'plotTitle', [num2str(thresh) 'C wet bulb events, 2070s, mean'], ...
                  'fileTitle', ['exceedenceMap-' num2str(thresh) 'C-' rcp '-' num2str(thresh) 'c-' num2str(decade) '-mean.pdf'], ...
                  'plotXUnits', 'Occurrences per year', ...
                  'blockWater', true);
plotFromDataFile(saveData);


result = {lat, lon, mapData(:, :, ind90)};
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [0 30], ...
                  'plotTitle', [num2str(thresh) 'C wet bulb events, 2070s, 90th percentile'], ...
                  'fileTitle', ['exceedenceMap-' num2str(thresh) 'C-' rcp '-' num2str(thresh) 'c-' num2str(decade) '-90p.pdf'], ...
                  'plotXUnits', 'Occurrences per year', ...
                  'blockWater', true);
plotFromDataFile(saveData);


