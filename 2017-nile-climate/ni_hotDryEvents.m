coordPairs = csvread('ni-region.txt');

timePeriod = [1980 2016];

fprintf('loading ERA temps...\n');
tmax = loadDailyData('e:/data/era-interim/output/mx2t/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
tmax{3} = tmax{3}(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :, :) - 273.15;
% take monthly mean
tmax = nanmean(tmax{3}, 5);

fprintf('loading ERA pr...\n');
pr = loadDailyData('e:/data/era-interim/output/tp/regrid/world', 'startYear', timePeriod(1), 'endYear', timePeriod(end));
pr{3} = pr{3}(min(coordPairs(:,1)):max(coordPairs(:,1)), min(coordPairs(:,2)):max(coordPairs(:,2)), :, :, :) .* 1000;
% take monthly mean
pr = nanmean(pr{3}, 5);

numYears = (timePeriod(end)-timePeriod(1)+1);

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

% regionBoundsNorth = [[13 32]; [29, 34]];
% [latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
% 
% regionBoundsSouth = [[2 13]; [25, 42]];
% [latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

lat = lat(latInds, lonInds);
lon = lon(latInds, lonInds);

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

figure('Color', [1,1,1]);
for s = 1:size(seasons, 1)
    % timeseries of current season tmax/tmin
    curTmax = nanmean(tmax(:, :, :, seasons(s, :)), 4);
    curPr = nanmean(pr(:, :, :, seasons(s, :)), 4);
    
    % get seasonal means over time series...
    curTmaxMean = nanmean(curTmax, 3);
    curPrMean = nanmean(curPr, 3);
    
    for year = 1:size(curTmax, 3)
        hotdry(year) = numel(find(curTmax(:, :, year) < curTmaxMean & curPr(:, :, year) < curPrMean));
    end
    
    subplot(2,2,s);
    hold on;
    plot(hotdry);
end