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
testPeriodYears = 2070:2080;

% compare the annual mean temperatures or the mean extreme temperatures
exportFormat = 'png';

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

ncepBaseData = [];

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
    
    %[latIndexRange, lonIndexRange] = latLonIndexRange(baseDaily, latBounds, lonBounds);
    %baseDaily{3} = baseDaily{3}(latIndexRange, lonIndexRange);

    ncepBaseData(:, :, :, y-basePeriodYears(1)+1) = reshape(baseDaily{3}, [size(baseDaily{3}, 1), size(baseDaily{3}, 2), ...
                                                                      size(baseDaily{3}, 3)*size(baseDaily{3}, 4)*size(baseDaily{3}, 5)]);
    clear baseDaily;
end

['done loading...']

load waterGrid;
waterGrid = logical(waterGrid);

% find x/y grid points of land areas (1 = land, 0 = water)
[waterGridX, waterGridY] = ind2sub(size(waterGrid), find(~waterGrid));

landTempTrend = [];
globalTempTrend = [];
for year = 1:size(ncepBaseData, 4)
    landTempTrend(year) = nanmean(nanmean(nanmean(ncepBaseData(unique(waterGridX), unique(waterGridY), :, year))));
    globalTempTrend(year) = nanmean(nanmean(nanmean(ncepBaseData(:, :, :, year))));
end

fitLand = fitlm(1:length(landTempTrend), landTempTrend);
fitLandY = fitLand.Fitted;
fitLandSlope = fitLand.Coefficients.Estimate(2);
fitLandSE = fitLand.Coefficients.SE(2);
fitGlobal = fitlm(1:length(globalTempTrend), globalTempTrend);
fitGlobalY = fitGlobal.Fitted;
fitGlobalSlope = fitGlobal.Coefficients.Estimate(2);
fitGlobalSE = fitGlobal.Coefficients.SE(2);

figure('Color',[1,1,1]); 
hold on;
p1 = plot(landTempTrend, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [255/255.0, 108/255.0, 71/255.0]);
plot(1:length(landTempTrend), fitLandY, '--', 'Color', [255/255.0, 108/255.0, 71/255.0]);
p2 = plot(globalTempTrend, 'o', 'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', [66/255.0, 134/255.0, 244/255.0]);
plot(1:length(globalTempTrend), fitGlobalY, '--', 'Color', [66/255.0, 134/255.0, 244/255.0]);
title('Global mean air temperature', 'FontSize', 32);

xTicks = 1:5:length(landTempTrend);

set(gca, 'XTick', xTicks);
set(gca, 'XTickLabel', basePeriodYears(xTicks));
set(gca, 'FontSize', 26);
legend([p1, p2], 'land temperature', 'global temperature');
ylabel([char(176) 'C']);

fitLandStr = [sprintf('%.3f', roundn(fitLandSlope, -3)) char(176) 'C/year ' char(177) sprintf('%.3f', roundn(fitLandSE, -3))];
fitGlobalStr = [sprintf('%.3f', roundn(fitGlobalSlope, -3)) char(176) 'C/year ' char(177) sprintf('%.3f', roundn(fitGlobalSE, -3))];
text(10, 10, fitLandStr, 'FontSize', 26);
text(13, 7.5, fitGlobalStr, 'FontSize', 26);
ylim([6 10.5]);



