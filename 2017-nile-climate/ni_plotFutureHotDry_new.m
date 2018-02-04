base = 'cmip5';

load(['2017-nile-climate\output\hotDryFuture-' base '-historical-1980-2004.mat']);
hotDryHistorical = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-' base '-rcp85-2056-2080.mat']);
hotDryFutureLate = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-' base '-rcp85-2031-2055.mat']);
hotDryFutureEarly = hotDryFuture;

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
    
    for s = 1:size(seasons, 1)
        if annual
            months = 1:12;
            if s > 1
                break;
            end
        else
            months = seasons(s,:);
        end
        
        hotdryHistorical = squeeze(nanmean(hotDryHistorical(:,:,months,:),3));
        hotdryHistorical = hotdryHistorical(curLatInds, curLonInds, :);
        hotdryHistorical = squeeze(nanmean(nanmean(hotdryHistorical,2),1));
        hotdryEarly = squeeze(nanmean(hotDryFutureEarly(:,:,months,:),3));
        hotdryEarly = hotdryEarly(curLatInds, curLonInds, :);
        hotdryEarly = squeeze(nanmean(nanmean(hotdryEarly,2),1));
        hotdryLate = squeeze(nanmean(hotDryFutureLate(:,:,months,:),3));
        hotdryLate = hotdryLate(curLatInds, curLonInds, :);
        hotdryLate = squeeze(nanmean(nanmean(hotdryLate,2),1));

        figure('Color', [1,1,1]);
        hold on;
        box on;
        axis square;
        grid on;

        b = boxplot([hotdryHistorical.*100 hotdryEarly.*100 hotdryLate.*100], ...
                     'colors', repmat('br', 1, 3), 'positions', [1 2 3]);

        for bind = 1:size(b, 2)
            if bind == 1
                set(b(:,bind), {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
                lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
                set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
            else
                set(b(:, bind), {'LineWidth', 'Color'}, {2, [247, 92, 81]./255.0})
                lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
                set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
            end
        end

        ylim([0 40]);
        xlim([0 4]);
        set(gca, 'YTick', [0 5 10 20 30 40]);
        ylabel('% of years');
        set(gca, 'XTick', [1,2,3], 'XTickLabels', {'1980 - 2004', '2031 - 2055', '2056 - 2080'});
        set(gca, 'FontSize', 36);
        xtickangle(45);
        %title([seasonNames{s}]);
        set(gcf, 'Position', get(0,'Screensize'));
        
        seasonStr = seasonNames{s};
        if annual
            seasonStr = 'annual';
        end
        if north
            export_fig(['hot-dry-fraction-' seasonStr '-' base '-north.eps']);
        else
            export_fig(['hot-dry-fraction-' seasonStr '-' base '-south.eps']);
        end
        close all;
    end
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

