% should we load pre-computed files
preload = true;

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
%baseModels = {''};
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
futureRcps = {'rcp45'};
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

load lat;
load lon;

% look at change above this base period temperature percentile
thresh = 99;

% should we show the uniformly shifted temp distribution for comparison
showShifted = false;

numDays = 372;

baseData = zeros(size(lat, 1), size(lat, 2), numDays, length(basePeriodYears));
baseData(baseData == 0) = NaN;

futureData = zeros(size(lat, 1), size(lat, 2), numDays, length(futurePeriodYears));
futureData(futureData == 0) = NaN;

% cutoff for the nth percentile in the base period data for each gridcell
baseThres = [];

load waterGrid;
waterGrid = logical(waterGrid);

% find x/y grid points of land areas (1 = land, 0 = water)
[waterGridX, waterGridY] = ind2sub(size(waterGrid), find(~waterGrid));

if ~preload

    ['loading base: ' baseDataset]
    for m = 1:length(baseModels)
        curModel = baseModels{m};

        ['loading base model ' curModel '...']

        for y = basePeriodYears(1):yearStep:basePeriodYears(end)
            ['year ' num2str(y) '...']

            baseDaily = loadDailyData([baseDir '/' baseDataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' baseVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

            if baseDaily{3}(1,1,1,1,1) > 100
                baseDaily{3} = baseDaily{3} - 273.15;
            end

            baseDaily3d = reshape(baseDaily{3}, [size(baseDaily{3}, 1), size(baseDaily{3}, 2), ...
                                                 size(baseDaily{3}, 3)*size(baseDaily{3}, 4)*size(baseDaily{3}, 5)]);

            baseData(1:size(baseDaily3d, 1), 1:size(baseDaily3d, 2), 1:size(baseDaily3d, 3), y-basePeriodYears(1)+1) = baseDaily3d;
            clear baseDaily baseDaily3d;
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
        selDataBase(:, :, :, m) = ch_genSelData(baseData, baseThresh(:, :, m), false);

        % percentage of the year exceeding thresh in each grid cell
        selDataBase(:, :, :, m) = selDataBase(:, :, :, m) ./ 365;

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

            futureDaily3d = reshape(futureDaily{3}, [size(futureDaily{3}, 1), size(futureDaily{3}, 2), ...
                                                     size(futureDaily{3}, 3)*size(futureDaily{3}, 4)*size(futureDaily{3}, 5)]);
            futureData(1:size(futureDaily3d, 1), 1:size(futureDaily3d, 2), 1:size(futureDaily3d, 3), y-futurePeriodYears(1)+1) = futureDaily3d;

            clear futureDaily futureDaily3d;
        end

        % find grid cells that exceed threshold in the future
        selDataFuture(:, :, :, m) = ch_genSelData(futureData, baseThresh, false);

        % percentage of the year exceeding thresh in each grid cell
        selDataFuture(:, :, :, m) = selDataFuture(:, :, :, m) ./ 365;

        clear cmip5FutureData;
    end
else
    load(['selData-cmip5-' num2str(thresh) '-historical']);
    selDataBase = selData;
    
    % rcp85
    load(['selData-cmip5-' num2str(thresh) '-rcp85']);
    selDataRcp85 = selData;
    
    % rcp45
    load(['selData-cmip5-' num2str(thresh) '-rcp45']);    
    selDataRcp45 = selData;
    
    if showShifted
        % uniformly shifted dist
        load(['selData-cmip5-' num2str(thresh) '-shifted-1.5-1.5.mat']);
        selDataShifted = selData;
    end
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
for m = 1:length(baseModels)
    for year = 1:length(basePeriodYears)
        selDataCurYear = selDataBase(:, :, year, m);
        selDataCurYearLand = selDataCurYear;
        selDataCurYearLand(waterGrid) = 0;

        areaGlobalTrendBase(m, year) = nansum(nansum(earthSA .* selDataCurYear));
        areaLandTrendBase(m, year) = nansum(nansum(earthSA .* selDataCurYearLand));
    end
end

areaGlobalTrendBase = areaGlobalTrendBase ./ earthTotalSA .* 100;
areaLandTrendBase = areaLandTrendBase  ./ earthLandSA .* 100;


% ------------ calculate trends for the future ----------------
areaGlobalTrendRcp45 = [];
areaLandTrendRcp45 = [];
areaGlobalTrendRcp85 = [];
areaLandTrendRcp85 = [];
areaGlobalTrendShifted = [];
areaLandTrendRcpShifted = [];

for m = 1:length(futureModels)
    for year = 1:length(futurePeriodYears)
        % rcp45
        selDataCurYear = selDataRcp45(:, :, year, m);
        selDataCurYearLand = selDataCurYear;
        selDataCurYearLand(waterGrid) = 0;
        areaGlobalTrendRcp45(m, year) = nansum(nansum(earthSA .* selDataCurYear));
        areaLandTrendRcp45(m, year) = nansum(nansum(earthSA .* selDataCurYearLand));
        
        % rcp85
        selDataCurYear = selDataRcp85(:, :, year, m);
        selDataCurYearLand = selDataCurYear;
        selDataCurYearLand(waterGrid) = 0;
        areaGlobalTrendRcp85(m, year) = nansum(nansum(earthSA .* selDataCurYear));
        areaLandTrendRcp85(m, year) = nansum(nansum(earthSA .* selDataCurYearLand));
        
        if showShifted
            % shifted by uniform amount
            selDataCurYear = selDataShifted(:, :, year, m);
            selDataCurYearLand = selDataCurYear;
            selDataCurYearLand(waterGrid) = 0;
            areaGlobalTrendShifted(m, year) = nansum(nansum(earthSA .* selDataCurYear));
            areaLandTrendShifted(m, year) = nansum(nansum(earthSA .* selDataCurYearLand));
        end
    end
end

areaGlobalTrendRcp45 = areaGlobalTrendRcp45 ./ earthTotalSA .* 100;
areaLandTrendRcp45 = areaLandTrendRcp45  ./ earthLandSA .* 100;

areaGlobalTrendRcp85 = areaGlobalTrendRcp85 ./ earthTotalSA .* 100;
areaLandTrendRcp85 = areaLandTrendRcp85  ./ earthLandSA .* 100;

fitLandBase = fitlm(1:size(areaLandTrendBase, 2), squeeze(nanmean(areaLandTrendBase, 1)));
fitLandRcp45 = fitlm(1:size(areaLandTrendRcp45, 2), squeeze(nanmean(areaLandTrendRcp45, 1)));
fitLandRcp85 = fitlm(1:size(areaLandTrendRcp85, 2), squeeze(nanmean(areaLandTrendRcp85, 1)));

fitGlobalBase = fitlm(1:size(areaGlobalTrendBase, 2), squeeze(nanmean(areaGlobalTrendBase, 1)));
fitGlobalRcp45 = fitlm(1:size(areaGlobalTrendRcp45, 2), squeeze(nanmean(areaGlobalTrendRcp45, 1)));
fitGlobalRcp85 = fitlm(1:size(areaGlobalTrendRcp85, 2), squeeze(nanmean(areaGlobalTrendRcp85, 1)));

if showShifted
    areaGlobalTrendShifted = areaGlobalTrendShifted ./ earthTotalSA .* 100;
    areaLandTrendShifted = areaLandTrendShifted  ./ earthLandSA .* 100;

    fitLandShifted = fitlm(1:size(areaLandTrendShifted, 2), squeeze(nanmean(areaLandTrendShifted, 1)));
    fitGlobalShifted = fitlm(1:size(areaGlobalTrendShifted, 2), squeeze(nanmean(areaGlobalTrendShifted, 1)));
end

figure('Color',[1,1,1]);
hold on;
%p1 = plot(basePeriodYears, areaLandTrendBase, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [96/255.0, 188/255.0, 100/255.0]);
p1 = shadedErrorBar(basePeriodYears, squeeze(nanmean(areaLandTrendBase, 1)), std(areaLandTrendBase), 'o', 1);
set(p1.mainLine,  'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [96/255.0, 188/255.0, 100/255.0]);
set(p1.patch, 'FaceColor', [96/255.0, 188/255.0, 100/255.0]);
set(p1.edge, 'Color', 'k');
plot(basePeriodYears, fitLandBase.Fitted, '--', 'Color', [96/255.0, 188/255.0, 100/255.0]);

%p2 = plot(basePeriodYears, areaGlobalTrendBase, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [66/255.0, 134/255.0, 244/255.0]);
%plot(basePeriodYears, fitGlobalBase.Fitted, '--', 'Color', [66/255.0, 134/255.0, 244/255.0]);

%p3 = plot(futurePeriodYears, areaLandTrendRcp45, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [66/255.0, 134/255.0, 244/255.0]);
p3 = shadedErrorBar(futurePeriodYears, squeeze(nanmean(areaLandTrendRcp45, 1)), std(areaLandTrendRcp45), 'o', 1);
set(p3.mainLine, 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [66/255.0, 134/255.0, 244/255.0]);
set(p3.patch, 'FaceColor', [66/255.0, 134/255.0, 244/255.0]);
set(p3.edge, 'Color', 'k');

plot(futurePeriodYears, fitLandRcp45.Fitted, '--', 'Color', [66/255.0, 134/255.0, 244/255.0]);

%p5 = plot(futurePeriodYears, areaLandTrendRcp85, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 108/255.0, 71/255.0]);
p5 = shadedErrorBar(futurePeriodYears, squeeze(nanmean(areaLandTrendRcp85, 1)), std(areaLandTrendRcp85), 'o', 1);
set(p5.mainLine, 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 108/255.0, 71/255.0]);
set(p5.patch, 'FaceColor', [255/255.0, 108/255.0, 71/255.0]);
set(p5.edge, 'Color', 'k');

plot(futurePeriodYears, fitLandRcp85.Fitted, '--', 'Color', [255/255.0, 108/255.0, 71/255.0]);

if showShifted
    p6 = shadedErrorBar(futurePeriodYears, squeeze(nanmean(areaLandTrendShifted, 1)), std(areaLandTrendShifted), 'o', 1);
    set(p6.mainLine, 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [244/255.0, 152/255.0, 66/255.0]);
    set(p6.patch, 'FaceColor', [244/255.0, 152/255.0, 66/255.0]);
    set(p6.edge, 'Color', 'k');
    plot(futurePeriodYears, fitLandShifted.Fitted, '--', 'Color', [244/255.0, 152/255.0, 66/255.0]);
end

%p4 = plot(futurePeriodYears, areaGlobalTrendRcp45, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [66/255.0, 134/255.0, 244/255.0]);
%plot(futurePeriodYears, fitGlobalRcp45.Fitted, '--', 'Color', [66/255.0, 134/255.0, 244/255.0]);

title(['Area above ' num2str(thresh) 'th percentile'], 'FontSize', 32);

xTicks = basePeriodYears(1):10:futurePeriodYears(end)+1;

plot(xTicks(1):xTicks(end), ones(length(xTicks(1):xTicks(end)), 1) .* (100-thresh), 'k--');

set(gca, 'XTick', xTicks);
set(gca, 'XTickLabel', xTicks);
set(gca, 'FontSize', 26);
if showShifted
    legend([p1.mainLine, p3.mainLine, p5.mainLine, p6.mainLine], 'historical', 'rcp45', 'rcp85', ['3' char(176) 'C shift by 2080']);
else
    legend([p1.mainLine, p3.mainLine, p5.mainLine], 'historical', 'rcp45', 'rcp85');
end
    
ylabel('Percent coverage');

fitLandStr = [sprintf('%.3f', roundn(fitLandBase.Coefficients.Estimate(2), -3)) char(176) '%/year ' char(177) sprintf('%.3f', roundn(fitLandBase.Coefficients.SE(2), -3))];
fitGlobalStr = [sprintf('%.3f', roundn(fitGlobalBase.Coefficients.Estimate(2), -3)) char(176) '%/year ' char(177) sprintf('%.3f', roundn(fitGlobalBase.Coefficients.SE(2), -3))];
text(2, 9.6, fitLandStr, 'FontSize', 26);
text(13.5, 11, fitGlobalStr, 'FontSize', 26);
xlim([xTicks(1) xTicks(end)]);
%ylim([6 10.5]);





