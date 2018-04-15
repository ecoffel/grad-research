base = 'cmip5';

load(['2017-nile-climate\output\hotDryFuture-' base '-historical-1980-2004.mat']);
hotDryHistorical = hotDryFuture(:, :, :, [1:9 11:23]);

load(['2017-nile-climate\output\hotDryFuture-' base '-rcp45-2056-2080.mat']);
hotDryFutureLate45 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-' base '-rcp85-2056-2080.mat']);
hotDryFutureLate85 = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-' base '-rcp45-2031-2055.mat']);
hotDryFutureEarly45 = hotDryFuture;
load(['2017-nile-climate\output\hotDryFuture-' base '-rcp85-2031-2055.mat']);
hotDryFutureEarly85 = hotDryFuture;

drawScatter = true;
drawMap = false;
north = true;
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

if drawScatter
    
    if north
        curLatInds = latIndsNorth;
        curLonInds = lonIndsNorth;
    else
        curLatInds = latIndsSouth;
        curLonInds = lonIndsSouth;
    end
    
    figure('Color', [1,1,1]);
    hold on;
    box on;
    grid on;
    axis square;
    
    for month = 1:12
        
        hotdryHistorical = squeeze(hotDryHistorical(:,:,month,:));
        hotdryHistorical = hotdryHistorical(curLatInds, curLonInds, :);
        hotdryHistorical = squeeze(nanmean(nanmean(hotdryHistorical,2),1));
        hotdryHistorical(end+1) = NaN;
        hotdryEarly45 = squeeze(hotDryFutureEarly45(:,:,month,:));
        hotdryEarly45 = hotdryEarly45(curLatInds, curLonInds, :);
        hotdryEarly45 = squeeze(nanmean(nanmean(hotdryEarly45,2),1));
        hotdryEarly45(end+1) = NaN;
        
        hotdryEarly85 = squeeze(hotDryFutureEarly85(:,:,month,:));
        hotdryEarly85 = hotdryEarly85(curLatInds, curLonInds, :);
        hotdryEarly85 = squeeze(nanmean(nanmean(hotdryEarly85,2),1));
        
        hotdryLate45 = squeeze(hotDryFutureLate45(:,:,month,:));
        hotdryLate45 = hotdryLate45(curLatInds, curLonInds, :);
        hotdryLate45 = squeeze(nanmean(nanmean(hotdryLate45,2),1));
        hotdryLate45(end+1) = NaN;
        
        hotdryLate85 = squeeze(hotDryFutureLate85(:,:,month,:));
        hotdryLate85 = hotdryLate85(curLatInds, curLonInds, :);
        hotdryLate85 = squeeze(nanmean(nanmean(hotdryLate85,2),1));

        b = boxplot([hotdryHistorical.*100 hotdryEarly45.*100 hotdryLate45.*100], ...
                     'colors', 'gbrbr', 'positions', [month month+.25 month+.5]);

        for bind = 1:size(b, 2)
            if bind == 1
                set(b(:,bind), {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
                lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
                set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
            elseif bind == 2
                set(b(:, bind), {'LineWidth', 'Color'}, {2, [239, 168, 55]./255.0})
                lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
                set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
            elseif bind == 3
                set(b(:, bind), {'LineWidth', 'Color'}, {2, [247, 92, 81]./255.0})
                lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
                set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
            end
        end
    end

    ylim([0 50]);
    xlim([0 13.25]);
    set(gca, 'YTick', [0 5 10 20 30 40 50]);
    ylabel('% of years');
    set(gca, 'XTick', 1.25:1:12.25, 'XTickLabels', {'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'});
    set(gca, 'FontSize', 40);
    %title([seasonNames{s}]);
    set(gcf, 'Position', get(0,'Screensize'));

    if north
        export_fig(['hot-dry-fraction-monthly-' base '-rcp45-north.eps']);
    else
        export_fig(['hot-dry-fraction-monthly-' base '-rcp45-south.eps']);
    end
    close all;
end

if drawMap
    curInds = regionInds('nile');
    latInds = curInds{1};
    lonInds = curInds{2};
    
    result = {lat(latInds,lonInds), lon(latInds,lonInds), 100 .* nanmedian(squeeze(nanmean(hotDryHistorical, 3)), 3)}; 
    
    saveData = struct('data', {result}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [0 15], ...
                      'cbXTicks', 0:5:15, ...
                      'plotTitle', [''], ...
                      'fileTitle', ['hot-dry-historical-annual.eps'], ...
                      'plotXUnits', ['% of years'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([], 'Oranges'), ...
                      'plotCountries', true, ...
                      'statData', sig <= .67*length(models), ...
                      'boxCoords', {[[13 32], [29, 34];
                                     [2 13], [25 42]]});
    plotFromDataFile(saveData);
end

