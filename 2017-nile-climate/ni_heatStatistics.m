timePeriod = [1980 2010];
numYears = (timePeriod(end)-timePeriod(1)+1);

if ~exist('tmaxNcepBase','var')
    tmaxNcepBase = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
    tmaxEraBase = loadDailyData('e:/data/era-interim/output/mx2t/regrid/world', 'yearStart', timePeriod(1), 'yearEnd', timePeriod(end));
end

coordPairs = csvread('ni-region.txt');

tmaxNcep = tmaxNcepBase{3}(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :, :);
tmaxNcep = tmaxNcep-273.15;

tmaxEra = tmaxEraBase{3}(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :, :);
tmaxEra = tmaxEra-273.15;

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

lat = lat(latInds, lonInds);
lon = lon(latInds, lonInds);

% number of days in a year (each month is 31 days)
numDays = 372;

% temperature: 
threshPrc = 99;
% duration (days)
threshDur = 5;

heatProbNcep = [];
heatProbEra = [];

% for all months, calculate the chance of there being a heatwave matching
% defined characteristics...
for month = 1:12
    % loop over all gridcells
    for xlat = 1:size(tmaxNcep, 1)
        for ylon = 1:size(tmaxNcep, 2)
            
            threshTempNcep = prctile(reshape(tmaxNcep(xlat,ylon,:,month,:), [numel(tmaxNcep(xlat,ylon,:,month,:)),1]), threshPrc);
            threshTempEra = prctile(reshape(tmaxEra(xlat,ylon,:,month,:), [numel(tmaxEra(xlat,ylon,:,month,:)),1]), threshPrc);
            
            for year = 1:range(timePeriod)
                % convert to 1D for current gridcell
                dNcep = reshape(tmaxNcep(xlat, ylon, year, month, :), [numel(tmaxNcep(xlat, ylon, year, month, :)), 1]);
                dEra = reshape(tmaxEra(xlat, ylon, year, month, :), [numel(tmaxEra(xlat, ylon, year, month, :)), 1]);

                % find all days above threshold temperature
                indTempNcep = find(dNcep > threshTempNcep);
                indTempEra = find(dEra > threshTempEra);

                % for how ever many days long wave we're looking for, take
                % difference of temp threshold indices - so if 1, that means
                % consequitive hot days
                % look for sub-arrays that contain X number of sequential ones
                indDurNcep = length(findstr(diff(indTempNcep)', ones(1,threshDur)));
                indDurEra = length(findstr(diff(indTempEra)', ones(1,threshDur)));

                % average number of events per year
                heatProbNcep(xlat, ylon, year, month) = indDurNcep;
                heatProbEra(xlat, ylon, year, month) = indDurEra;
            end
        end
    end
end

for xlat = 1:length(latInds)
    for ylon = 1:length(lonInds)
        if length(find(coordPairs(:,1) == latInds(xlat) & coordPairs(:,2) == lonInds(ylon))) == 0
            heatProbNcep(xlat, ylon, :, :) = NaN;
            heatProbNcep(xlat, ylon, :, :) = NaN;
        end
    end
end

% number of heat waves per year averaged across all regional grid cells
figure('Color',[1,1,1]);
hold on;
axis square;
grid on;
box on;
p1=plot(timePeriod(1):timePeriod(end)-1, squeeze(nansum(nansum(nansum(heatProbNcep,4),2),1)), 'k-', 'LineWidth', 2);
p2=plot(timePeriod(1):timePeriod(end)-1, squeeze(nansum(nansum(nansum(heatProbEra,4),2),1)), 'k--', 'LineWidth', 2);
legend([p1,p2],{'NCEP', 'Era'},'location','northwest');
title('5-day temperatures above local 99th percentile');
ylabel('Number of heat waves');
xlabel('Year');
set(gca, 'FontSize',24);
set(gcf, 'Position', get(0,'Screensize'));
export_fig('nile-annual-heat-waves-historical.png', '-m2');
close all;

result = {lat, lon, sum(sum(heatProbNcep, 4), 3)};

saveData = struct('data', {result}, ...
                  'plotRegion', 'nile', ...
                  'plotRange', [0 100], ...
                  'cbXTicks', [0 25 50 75 100], ...
                  'plotTitle', ['Total heat waves (1980-2010)'], ...
                  'fileTitle', ['nile-heat-waves-historical.png'], ...
                  'plotXUnits', ['Number'], ...
                  'blockWater', true, ...
                  'colormap', cmocean('thermal'), ...
                  'plotCountries', true, ...
                  'magnify', '2');
plotFromDataFile(saveData);
