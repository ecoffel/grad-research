decade = [2060 2070];
rcp = 'rcp85';
thresh = 32;

baseDir = '2015-heat-humidity/selGrid/';

load lat;
load lon;

mapData = [];

numScenarios = 34;
if strcmp(rcp, 'rcp85') || strcmp(rcp, 'rcp45')
    numScenarios = 18;
end

% loop through all scenarios
for s = 1:numScenarios
    for d = 1:length(decade)
        load([baseDir 'selGrid-' num2str(decade(d)) 's-' rcp '-' num2str(thresh) 'C-scenario-' num2str(s)]);

        mapData(:, :, d, s) = selGrid;

        clear selGrid;
    end
end

ind10 = round(0.1 * size(mapData, 3));
ind90 = round(0.9 * size(mapData, 3));

mapData(mapData == 0) = NaN;
% result = {lat, lon, mapData(:, :, ind10)};
% saveData = struct('data', {result}, ...
%                   'plotRegion', 'world', ...
%                   'plotRange', [0 30], ...
%                   'plotTitle', [num2str(thresh) 'C wet bulb events, 2070s, 10th percentile'], ...
%                   'fileTitle', ['exceedenceMap-' num2str(thresh) 'C-' rcp '-' num2str(thresh) 'c-' num2str(decade) '-10p.pdf'], ...
%                   'plotXUnits', 'Occurrences per year', ...
%                   'blockWater', true);
% plotFromDataFile(saveData);


result = {lat, lon, nanmean(nanmean(mapData, 3), 4)};
result{3}(result{3} >= .5) = round(result{3}(result{3} >= .5) .* 2) ./ 2;
result{3}(result{3} < .5) = round(result{3}(result{3} < .5) .* 5) ./ 5;
result{3}(result{3}==0)=NaN;
data=result{3};
saveData = struct('data', {result}, ...
                  'plotRegion', 'north america', ...
                  'plotRange', [0 1], ...
                  'cbXTicks',  [0 .1 .2 .3 .4 .5 1], ...
                  'plotTitle', [], ...
                  'fileTitle', ['exceedenceMap-' num2str(thresh) 'C-' rcp '-' num2str(thresh) 'c-' num2str(decade(1)) '-' num2str(decade(end)) '-usa.pdf'], ...
                  'plotXUnits', 'Days per year', ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'Reds'), ...
                  'plotCountries', true, ...
                  'plotStates', true);
plotFromDataFile(saveData);




% result = {lat, lon, mapData(:, :, ind90)};
% saveData = struct('data', {result}, ...
%                   'plotRegion', 'world', ...
%                   'plotRange', [0 30], ...
%                   'plotTitle', [num2str(thresh) 'C wet bulb events, 2070s, 90th percentile'], ...
%                   'fileTitle', ['exceedenceMap-' num2str(thresh) 'C-' rcp '-' num2str(thresh) 'c-' num2str(decade) '-90p.pdf'], ...
%                   'plotXUnits', 'Occurrences per year', ...
%                   'blockWater', true);
% plotFromDataFile(saveData);


