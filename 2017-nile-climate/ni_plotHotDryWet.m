base = 'cmip5';

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-historical-1981-2005-t90-p10.mat']);
hotDryHistorical = hotDryFuture(:, :, [1:9 11:23]);
load(['2017-nile-climate\output\dryFuture-annual-' base '-historical-1981-2005-t90-p10.mat']);
dryHistorical = dryFuture(:, :, [1:9 11:23]);
load(['2017-nile-climate\output\wetFuture-annual-' base '-historical-1981-2005-t90-p10.mat']);
wetHistorical = wetFuture(:, :, [1:9 11:23]);


load(['2017-nile-climate\output\dryFuture-annual-cmip5-rcp85-2025-2049-t90-p10-tfull-pfull.mat']);
dryFuture25 = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-cmip5-rcp85-2025-2049-t90-p10-tfull-pfull.mat']);
wetFuture25 = wetFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp85-2025-2049-t90-p10-tfull-pfull.mat']);
hotDryFuture25 = hotDryFuture;

load(['2017-nile-climate\output\dryFuture-annual-cmip5-rcp85-2050-2074-t90-p10-tfull-pfull.mat']);
dryFuture50 = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-cmip5-rcp85-2050-2074-t90-p10-tfull-pfull.mat']);
wetFuture50 = wetFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp85-2050-2074-t90-p10-tfull-pfull.mat']);
hotDryFuture50 = hotDryFuture;

load(['2017-nile-climate\output\dryFuture-annual-cmip5-rcp85-2075-2099-t90-p10-tfull-pfull.mat']);
dryFuture75 = dryFuture;
load(['2017-nile-climate\output\wetFuture-annual-cmip5-rcp85-2075-2099-t90-p10-tfull-pfull.mat']);
wetFuture75 = wetFuture;
load(['2017-nile-climate\output\hotDryFuture-annual-cmip5-rcp85-2075-2099-t90-p10-tfull-pfull.mat']);
hotDryFuture75 = hotDryFuture;

drawScatter = true;
drawMap = false;
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

regionBoundsNorth = [[15 32]; [29, 34]];
regionBoundsBlue = [[8 14]; [34, 40]];
regionBoundsWhite = [[3 14]; [27, 33.5]];

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsBlue, lonIndsBlue] = latLonIndexRange({lat,lon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhite, lonIndsWhite] = latLonIndexRange({lat,lon,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));

latIndsNorth = latIndsNorth - latInds(1) + 1;
lonIndsNorth = lonIndsNorth - lonInds(1) + 1;
latIndsBlue = latIndsBlue - latInds(1) + 1;
lonIndsBlue = lonIndsBlue - lonInds(1) + 1;
latIndsWhite = latIndsWhite - latInds(1) + 1;
lonIndsWhite = lonIndsWhite - lonInds(1) + 1;

if drawScatter
        
    curLatInds = latIndsWhite;
    curLonInds = lonIndsWhite;
    
%     curLatInds = latIndsBlue;
%     curLonInds = lonIndsBlue;
% 
%     curLatInds = latIndsNorth;
%     curLonInds = lonIndsNorth;

    hotdryHistorical = hotDryHistorical;
    hotdryHistorical = hotdryHistorical(curLatInds, curLonInds, :);
    hotdryHistorical = squeeze(nanmean(nanmean(hotdryHistorical,2),1));
    hotdryHistorical(end+1) = NaN;
    
    wetHistorical = wetHistorical;
    wetHistorical = wetHistorical(curLatInds, curLonInds, :);
    wetHistorical = squeeze(nanmean(nanmean(wetHistorical,2),1));
    wetHistorical(end+1) = NaN;
    
    dryHistorical = dryHistorical;
    dryHistorical = dryHistorical(curLatInds, curLonInds, :);
    dryHistorical = squeeze(nanmean(nanmean(dryHistorical,2),1));
    dryHistorical(end+1) = NaN;

    hotdry85_25 = hotDryFuture25;
    hotdry85_25 = hotdry85_25(curLatInds, curLonInds, :);
    hotdry85_25 = squeeze(nanmean(nanmean(hotdry85_25,2),1));
    
    hotdry85_50 = hotDryFuture50;
    hotdry85_50 = hotdry85_50(curLatInds, curLonInds, :);
    hotdry85_50 = squeeze(nanmean(nanmean(hotdry85_50,2),1));
    
    hotdry85_75 = hotDryFuture75;
    hotdry85_75 = hotdry85_75(curLatInds, curLonInds, :);
    hotdry85_75 = squeeze(nanmean(nanmean(hotdry85_75,2),1));

    wet85_25 = wetFuture25;
    wet85_25 = wet85_25(curLatInds, curLonInds, :);
    wet85_25 = squeeze(nanmean(nanmean(wet85_25,2),1));
    
    wet85_50 = wetFuture50;
    wet85_50 = wet85_50(curLatInds, curLonInds, :);
    wet85_50 = squeeze(nanmean(nanmean(wet85_50,2),1));
    
    wet85_75 = wetFuture75;
    wet85_75 = wet85_75(curLatInds, curLonInds, :);
    wet85_75 = squeeze(nanmean(nanmean(wet85_75,2),1));

    dry85_25 = dryFuture25;
    dry85_25 = dry85_25(curLatInds, curLonInds, :);
    dry85_25 = squeeze(nanmean(nanmean(dry85_25,2),1));
    
    dry85_50 = dryFuture50;
    dry85_50 = dry85_50(curLatInds, curLonInds, :);
    dry85_50 = squeeze(nanmean(nanmean(dry85_50,2),1));
    
    dry85_75 = dryFuture75;
    dry85_75 = dry85_75(curLatInds, curLonInds, :);
    dry85_75 = squeeze(nanmean(nanmean(dry85_75,2),1));


    figure('Color', [1,1,1]);
    hold on;
    box on;
    grid on;
    axis square;

    b = boxplot([wetHistorical.*100 dryHistorical.*100 hotdryHistorical.*100 wet85_25.*100 dry85_25.*100 hotdry85_25.*100 ... 
                                       wet85_50.*100 dry85_25.*100 hotdry85_50.*100 ... 
                                       wet85_75.*100 dry85_25.*100 hotdry85_75.*100], ...
                 'colors', 'k', 'positions', [1 2 3 5 6 7 9 10 11 13 14 15]);

    for bind = 1:size(b, 2)
        if ismember(bind, [1 4 7 10])
            set(b(:,bind), {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
            lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
            set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
        elseif ismember(bind, [2 5 8 11])
            set(b(:, bind), {'LineWidth', 'Color'}, {2, [145, 86, 46]./255.0})
            lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
            set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
        elseif ismember(bind, [3 6 9 12])
            set(b(:, bind), {'LineWidth', 'Color'}, {2, [247, 92, 81]./255.0})
            lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
            set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
        end
    end

    ylim([0 100]);
    xlim([0 16]);
    plot([0 16], [10 10], '--k', 'LineWidth', 2);
    set(gca, 'YTick', 0:20:100);
    ylabel('% of years');
    set(gca, 'XTick', [2 6 10 14], 'XTickLabels', {'1981-2005', '2025-2049', '2050-2075', '2075-2099'});
    set(gca, 'FontSize', 40);
    xtickangle(45);
    %title([seasonNames{s}]);
    set(gcf, 'Position', get(0,'Screensize'));

    export_fig(['hot-dry-fraction-annual-' base '-white.eps']);

    close all;
end

if drawMap
    
    [regionInds, regions, regionNames] = ni_getRegions();
    curInds = regionInds('nile');
    latInds = curInds{1};
    lonInds = curInds{2};
    
    result = {lat(latInds,lonInds), lon(latInds,lonInds), 100 .* nanmedian(hotDryHistorical, 3)}; 
    
    saveData = struct('data', {result}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [0 30], ...
                      'cbXTicks', 0:5:30, ...
                      'plotTitle', [''], ...
                      'fileTitle', ['hot-dry-rcp85-1981-2005.eps'], ...
                      'plotXUnits', ['% of years'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([], 'Oranges'), ...
                      'plotCountries', true, ...
                      'boxCoords', {[[15 32], [29, 34];
                                     [8 14], [34, 40];
                                     [3 14], [27, 33.5]]});
    plotFromDataFile(saveData);
    
    result = {lat(latInds,lonInds), lon(latInds,lonInds), 100 .* nanmedian(hotDryFuture25, 3)}; 
    
    saveData = struct('data', {result}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [0 30], ...
                      'cbXTicks', 0:5:30, ...
                      'plotTitle', [''], ...
                      'fileTitle', ['hot-dry-rcp85-2025-2049.eps'], ...
                      'plotXUnits', ['% of years'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([], 'Oranges'), ...
                      'plotCountries', true, ...
                      'boxCoords', {[[15 32], [29, 34];
                                     [8 14], [34, 40];
                                     [3 14], [27, 33.5]]});
    plotFromDataFile(saveData);
    
    result = {lat(latInds,lonInds), lon(latInds,lonInds), 100 .* nanmedian(hotDryFuture50, 3)}; 
    
    saveData = struct('data', {result}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [0 30], ...
                      'cbXTicks', 0:5:30, ...
                      'plotTitle', [''], ...
                      'fileTitle', ['hot-dry-rcp85-2050-2074.eps'], ...
                      'plotXUnits', ['% of years'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([], 'Oranges'), ...
                      'plotCountries', true, ...
                      'boxCoords', {[[15 32], [29, 34];
                                     [8 14], [34, 40];
                                     [3 14], [27, 33.5]]});
    plotFromDataFile(saveData);
    
    result = {lat(latInds,lonInds), lon(latInds,lonInds), 100 .* nanmedian(hotDryFuture75, 3)}; 
    
    saveData = struct('data', {result}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [0 30], ...
                      'cbXTicks', 0:5:30, ...
                      'plotTitle', [''], ...
                      'fileTitle', ['hot-dry-rcp85-2075-2099.eps'], ...
                      'plotXUnits', ['% of years'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([], 'Oranges'), ...
                      'plotCountries', true, ...
                      'boxCoords', {[[15 32], [29, 34];
                                     [8 14], [34, 40];
                                     [3 14], [27, 33.5]]});
    plotFromDataFile(saveData);
end

