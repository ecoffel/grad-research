season = 'all';
basePeriod = 'past';

baseDataset = 'ncep-reanalysis';
baseVar = 'tmax';

baseRegrid = true;

region = 'world';
chgType = 'multi-model';

plotRegion = 'world';
plotTitle = ['CMIP5 annual maximum wet-bulb'];

basePeriodYears = 1980:2010;
testPeriodYears = 2020:30:2080;

% compare the annual mean temperatures or the mean extreme temperatures
exportFormat = 'png';

% should we use a threshold for each gridcell or for the entire globe/land area
gridcellAverage = true;

blockWater = true;

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

ncepBaseData = [];
cmip5FutureData = [];

% cutoff for the nth percentile in the base period data for each gridcell
baseThres = [];

['loading base: ' baseDataset]
for y = basePeriodYears(1):yearStep:basePeriodYears(end)
    ['year ' num2str(y) '...']

    baseDaily = loadDailyData([baseDir '/' baseDataset '/output/' baseVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

    if length(lat) == 0
        lat = baseDaily{1};
        lon = baseDaily{2};
    end

    if ~strcmp(baseVar, 'rh') && baseDaily{3}(1,1,1,1,1) > 100
        baseDaily{3} = baseDaily{3} - 273.15;
    end
    
    ncepBaseData(:, :, :, y-basePeriodYears(1)+1) = reshape(baseDaily{3}, [size(baseDaily{3}, 1), size(baseDaily{3}, 2), ...
                                                                      size(baseDaily{3}, 3)*size(baseDaily{3}, 4)*size(baseDaily{3}, 5)]);
    clear baseDaily;
end

['done loading...']

load waterGrid;
waterGrid = logical(waterGrid);

% find x/y grid points of land areas (1 = land, 0 = water)
[waterGridX, waterGridY] = ind2sub(size(waterGrid), find(~waterGrid));

if gridcellAverage
    for x = 1:size(ncepBaseData, 1)
        for y = 1:size(ncepBaseData, 2)
            curCellData = reshape(squeeze(ncepBaseData(x, y, :, :)), [size(ncepBaseData, 3)*size(ncepBaseData, 4), 1]);
            baseThresh(x, y) = prctile(curCellData, thresh);
            clear curCellData;
        end
    end
else
    ncepBase1d = reshape(ncepBaseData, [numel(ncepBaseData), 1]);
    thresh1d = prctile(ncepBase1d, thresh);
    clear ncepBase1d;
    baseThresh = ones(size(ncepBaseData, 1), size(ncepBaseData, 2)) .* thresh1d;
end

% earth surface area
load earthSA;
totalSelGrid = ones(size(lat, 1), size(lat, 2));
earthTotalSA = ch_selDataSA(totalSelGrid);
earthLandSA = ch_selDataSA(~waterGrid);

% find grid cells that exceed threshold
selData = ch_genSelData(ncepBaseData, baseThresh, false);

% percentage of the year exceeding thresh in each grid cell
selData = selData ./ 365;

areaGlobalTrend = [];
areaLandTrend = [];
for year = 1:size(ncepBaseData, 4)
    selDataCurYear = selData(:, :, year);
    selDataCurYearLand = selDataCurYear;
    selDataCurYearLand(waterGrid) = 0;
    
    areaGlobalTrend(year) = nansum(nansum(earthSA .* selDataCurYear));
    areaLandTrend(year) = nansum(nansum(earthSA .* selDataCurYearLand));
end

clear ncepBaseData;

areaGlobalTrend = areaGlobalTrend ./ earthTotalSA .* 100;
areaLandTrend = areaLandTrend  ./ earthLandSA .* 100;

fitLand = fitlm(1:length(areaLandTrend), areaLandTrend);
fitLandY = fitLand.Fitted;
fitLandSlope = fitLand.Coefficients.Estimate(2);
fitLandSE = fitLand.Coefficients.SE(2);
fitGlobal = fitlm(1:length(areaGlobalTrend), areaGlobalTrend);
fitGlobalY = fitGlobal.Fitted;
fitGlobalSlope = fitGlobal.Coefficients.Estimate(2);
fitGlobalSE = fitGlobal.Coefficients.SE(2);

figure('Color',[1,1,1]);
hold on;
p1 = plot(areaLandTrend, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 108/255.0, 71/255.0]);
plot(1:length(areaLandTrend), fitLandY, '--', 'Color', [255/255.0, 108/255.0, 71/255.0]);
p2 = plot(areaGlobalTrend, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [66/255.0, 134/255.0, 244/255.0]);
plot(1:length(areaGlobalTrend), fitGlobalY, '--', 'Color', [66/255.0, 134/255.0, 244/255.0]);

plot(1:length(areaLandTrend), ones(length(areaLandTrend), 1) .* (100-thresh), 'k--');

title(['Area above ' num2str(thresh) 'th percentile'], 'FontSize', 32);

xTicks = 1:5:length(areaLandTrend);

set(gca, 'XTick', xTicks);
set(gca, 'XTickLabel', basePeriodYears(xTicks));
set(gca, 'FontSize', 26);
legend([p1, p2], 'land', 'global');
ylabel('Percent coverage');

fitLandStr = [sprintf('%.3f', roundn(fitLandSlope, -3)) char(176) '%/year ' char(177) sprintf('%.3f', roundn(fitLandSE, -3))];
fitGlobalStr = [sprintf('%.3f', roundn(fitGlobalSlope, -3)) char(176) '%/year ' char(177) sprintf('%.3f', roundn(fitGlobalSE, -3))];
text(2, 9.6, fitLandStr, 'FontSize', 26);
text(13.5, 11, fitGlobalStr, 'FontSize', 26);
%ylim([6 10.5]);





