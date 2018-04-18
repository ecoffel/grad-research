base = 'cmip5';

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-historical-1980-2004.mat']);
hotDryHistorical = hotDryFuture(:, :, [1:9 11:23]);

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp45-2056-2080.mat']);
hotDryFutureLate45 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp85-2056-2080.mat']);
hotDryFutureLate85 = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp45-2031-2055.mat']);
hotDryFutureEarly45 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp85-2031-2055.mat']);
hotDryFutureEarly85 = hotDryFuture;

drawScatter = false;
drawMap = true;
north = false;
annual = true;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];
seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndsNorth = latIndsNorth - latInds(1) + 1;
lonIndsNorth = lonIndsNorth - lonInds(1) + 1;
latIndsSouth = latIndsSouth - latInds(1) + 1;
lonIndsSouth = lonIndsSouth - lonInds(1) + 1;
    
[regionInds, regions, regionNames] = ni_getRegions();
curInds = regionInds('nile');
latInds = curInds{1};
lonInds = curInds{2};

multSouth = squeeze(nanmean(nanmean(hotDryHistorical(latIndsSouth, lonIndsSouth, :), 2), 1)) ./ .01;
multNorth = squeeze(nanmean(nanmean(hotDryHistorical(latIndsNorth, lonIndsNorth, :), 2), 1)) ./ .01;

figure('Color', [1,1,1]);
hold on;
box on;
grid on;
axis square;

b = boxplot([multSouth multNorth], 'positions', [1 2]);

set(b(:, 1), {'LineWidth', 'Color'}, {2, [239, 168, 55]./255.0})
lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 

set(b(:, 2), {'LineWidth', 'Color'}, {2, [247, 92, 81]./255.0})
lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 

ylim([0 4]);
xlim([.5 2.5]);
set(gca, 'YTick', 0:.5:4);
ylabel('Multiplier');
set(gca, 'XTick', [1,2], 'XTickLabels', {'South', 'North'});
set(gca, 'FontSize', 40);
xtickangle(45);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['hot-dry-corr-mult-historical.eps']);
close all;




