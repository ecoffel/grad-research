season = 'all';
basePeriod = 'past';

% add in base models and add to the base loading loop

baseDataset = 'cmip5';
baseVar = 'tasmax';

baseModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          %{'access1-0', 'access1-3'};
baseRcps = {'historical'};
baseEnsemble = 'r1i1p1';

futureDataset = 'cmip5';
futureVar = 'tasmax';

futureModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
%futureModels = {'access1-0', 'access1-3'};
futureRcps = {'rcp85'};
futureEnsemble = 'r1i1p1';

baseRegrid = true;
futureRegrid = true;

region = 'world';
plotRegion = 'world';

basePeriodYears = 1981:2004;
%basePeriodYears = 1980:1990;
futurePeriodYears = 2020:2080;
%futurePeriodYears = 2050:2060;

% compare the annual mean temperatures or the mean extreme temperatures
exportFormat = 'png';

% should we use a threshold for each gridcell or for the entire globe/land area
gridcellAverage = true;

baseDir = 'e:/data';
yearStep = 1;

if strcmp(season, 'summer')
    months = [6 7 8];
elseif strcmp(season, 'winter')
    months = [12 1 2];
elseif strcmp(season, 'all')
    months = 1:12;
end

latBounds = [-60 60];
lonBounds = [0 360];

lat = [];
lon = [];

% look at change above this base period temperature percentile
thresh = 90;

baseData = [];
futureData = [];

% cutoff for the nth percentile in the base period data for each gridcell
baseThres = [];

load waterGrid;
waterGrid = logical(waterGrid);

% find x/y grid points of land areas (1 = land, 0 = water)
[waterGridX, waterGridY] = ind2sub(size(waterGrid), find(~waterGrid));

['loading base: ' baseDataset]
for m = 1:length(baseModels)
    curModel = baseModels{m};
    
    ['loading base model ' curModel '...']
    
    for y = basePeriodYears(1):yearStep:basePeriodYears(end)
        ['year ' num2str(y) '...']

        baseDaily = loadDailyData([baseDir '/' baseDataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' baseVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

        if length(lat) == 0
            lat = baseDaily{1};
            lon = baseDaily{2};
        end

        if baseDaily{3}(1,1,1,1,1) > 100
            baseDaily{3} = baseDaily{3} - 273.15;
        end
        
        baseData(:, :, :, y-basePeriodYears(1)+1) = reshape(baseDaily{3}, [size(baseDaily{3}, 1), size(baseDaily{3}, 2), ...
                                                                          size(baseDaily{3}, 3)*size(baseDaily{3}, 4)*size(baseDaily{3}, 5)]);
        clear baseDaily;
    end
    
    if gridcellAverage
        for x = 1:size(baseData, 1)
            for y = 1:size(baseData, 2)
                curCellData = reshape(squeeze(baseData(x, y, :, :)), [size(baseData, 3)*size(baseData, 4), 1]);
                baseThresh(x, y, m) = prctile(curCellData, thresh);
                clear curCellData;
            end
        end
    else
        baseData1d = reshape(baseData, [numel(baseData), 1]);
        thresh1d = prctile(baseData1d, thresh);
        clear baseData1d;
        baseThresh(:, :, m) = ones(size(baseData, 1), size(baseData, 2)) .* thresh1d;
    end

    % find grid cells that exceed threshold
    selDataBase = ch_genSelData(baseData, baseThresh(:, :, m), false);

    % percentage of the year exceeding thresh in each grid cell
    selDataBase = selDataBase ./ 365;

    clear baseData;
end


% ------------ load future data -------------
selDataFuture = [];

['loading future: ' futureDataset]
for m = 1:length(futureModels)
        curModel = futureModels{m};
    
    ['loading future model ' curModel '...']
    
    for y = futurePeriodYears(1):yearStep:futurePeriodYears(end)
        ['year ' num2str(y) '...']

        futureDaily = loadDailyData([baseDir '/' futureDataset '/output/' curModel '/' futureEnsemble '/' futureRcps{1} '/' futureVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

        if futureDaily{3}(1,1,1,1,1) > 100
            futureDaily{3} = futureDaily{3} - 273.15;
        end
        
        futureData(:, :, :, y-futurePeriodYears(1)+1) = reshape(futureDaily{3}, [size(futureDaily{3}, 1), size(futureDaily{3}, 2), ...
                                                                          size(futureDaily{3}, 3)*size(futureDaily{3}, 4)*size(futureDaily{3}, 5)]);
        clear futureDaily;
    end
    
    % find grid cells that exceed threshold in the future
    selDataFuture(:, :, :, m) = ch_genSelData(futureData, baseThresh, false);

    % percentage of the year exceeding thresh in each grid cell
    selDataFuture(:, :, :, m) = selDataFuture(:, :, :, m) ./ 365;

    clear cmip5FutureData;
end

['done loading...']

% earth surface area
load earthSA;
totalSelGrid = ones(size(lat, 1), size(lat, 2));
earthTotalSA = ch_selDataSA(totalSelGrid);
earthLandSA = ch_selDataSA(~waterGrid);

% ------------ calculate trends for the base ----------------
areaGlobalTrendBase = [];
areaLandTrendBase = [];
for year = 1:length(basePeriodYears)
    selDataCurYear = selDataBase(:, :, year);
    selDataCurYearLand = selDataCurYear;
    selDataCurYearLand(waterGrid) = 0;
    
    areaGlobalTrendBase(year) = nansum(nansum(earthSA .* selDataCurYear));
    areaLandTrendBase(year) = nansum(nansum(earthSA .* selDataCurYearLand));
end

areaGlobalTrendBase = areaGlobalTrendBase ./ earthTotalSA .* 100;
areaLandTrendBase = areaLandTrendBase  ./ earthLandSA .* 100;


% ------------ calculate trends for the future ----------------
areaGlobalTrendFuture = [];
areaLandTrendFuture = [];
for m = 1:length(futureModels)
    for year = 1:length(futurePeriodYears)
        selDataCurYear = selDataFuture(:, :, year, m);
        selDataCurYearLand = selDataCurYear;
        selDataCurYearLand(waterGrid) = 0;

        areaGlobalTrendFuture(m, year) = nansum(nansum(earthSA .* selDataCurYear));
        areaLandTrendFuture(m, year) = nansum(nansum(earthSA .* selDataCurYearLand));
    end
end

areaGlobalTrendFuture = areaGlobalTrendFuture ./ earthTotalSA .* 100;
areaLandTrendFuture = areaLandTrendFuture  ./ earthLandSA .* 100;

areaGlobalTrendFuture = squeeze(nanmean(areaGlobalTrendFuture, 1))
areaLandTrendFuture = squeeze(nanmean(areaLandTrendFuture, 1))

fitLandBase = fitlm(1:length(areaLandTrendBase), areaLandTrendBase);
fitLandFuture = fitlm(1:length(areaLandTrendFuture), areaLandTrendFuture);

fitGlobalBase = fitlm(1:length(areaGlobalTrendBase), areaGlobalTrendBase);
fitGlobalFuture = fitlm(1:length(areaGlobalTrendFuture), areaGlobalTrendFuture);

figure('Color',[1,1,1]);
hold on;
p1 = plot(basePeriodYears, areaLandTrendBase, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 108/255.0, 71/255.0]);
plot(basePeriodYears, fitLandBase.Fitted, '--', 'Color', [255/255.0, 108/255.0, 71/255.0]);
p2 = plot(basePeriodYears, areaGlobalTrendBase, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [66/255.0, 134/255.0, 244/255.0]);
plot(basePeriodYears, fitGlobalBase.Fitted, '--', 'Color', [66/255.0, 134/255.0, 244/255.0]);

p3 = plot(futurePeriodYears, areaLandTrendFuture, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 108/255.0, 71/255.0]);
plot(futurePeriodYears, fitLandFuture.Fitted, '--', 'Color', [255/255.0, 108/255.0, 71/255.0]);
p4 = plot(futurePeriodYears, areaGlobalTrendFuture, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [66/255.0, 134/255.0, 244/255.0]);
plot(futurePeriodYears, fitGlobalFuture.Fitted, '--', 'Color', [66/255.0, 134/255.0, 244/255.0]);

plot(1:length(areaLandTrendBase), ones(length(areaLandTrendBase), 1) .* (100-thresh), 'k--');

title(['Area above ' num2str(thresh) 'th percentile'], 'FontSize', 32);

xTicks = basePeriodYears(1):10:futurePeriodYears(end);

set(gca, 'XTick', xTicks);
set(gca, 'XTickLabel', xTicks);
set(gca, 'FontSize', 26);
legend([p1, p2], 'land', 'global');
ylabel('Percent coverage');

fitLandStr = [sprintf('%.3f', roundn(fitLandBase.Coefficients.Estimate(2), -3)) char(176) '%/year ' char(177) sprintf('%.3f', roundn(fitLandBase.Coefficients.SE(2), -3))];
fitGlobalStr = [sprintf('%.3f', roundn(fitGlobalBase.Coefficients.Estimate(2), -3)) char(176) '%/year ' char(177) sprintf('%.3f', roundn(fitGlobalBase.Coefficients.SE(2), -3))];
text(2, 9.6, fitLandStr, 'FontSize', 26);
text(13.5, 11, fitGlobalStr, 'FontSize', 26);
xlim([xTicks(1) xTicks(end)]);
%ylim([6 10.5]);





