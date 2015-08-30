season = 'all';
basePeriod = 'past';
testPeriod = 'future';

baseDataset = 'cmip5';
testDataset = 'cmip5';

% baseModels = {'bnu-esm'};
% testModels = {'bnu-esm'};

baseModels = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
          'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};
testModels = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
          'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};
      
baseVar = 'tasmax';
testVar = 'tasmax';

baseRegrid = true;
modelRegrid = true;

basePeriodYears = 1985:2004;
testPeriodYears = 2021:2070;

biasCorrect = true;

popRegrid = true;

region = 'west_africa';
exposureThreshold = 50;

% compare the annual mean temperatures or the mean extreme temperatures
annualmean = false;
exportformat = 'pdf';

baseDir = 'e:/data/';
yearStep = 1;

if strcmp(season, 'summer')
    findMax = true;
    months = [6 7 8];
    maxMinStr = 'maximum';
elseif strcmp(season, 'winter')
    findMax = false;
    months = [12 1 2];
    maxMinStr = 'minimum';
elseif strcmp(season, 'all')
    findMax = true;
    months = 1:12;
    maxMinStr = 'maximum';
end

if annualmean
    maxMinStr = ['mean ' maxMinStr];
    maxMinFileStr = 'mean';
else
    maxMinFileStr = 'ext';
end

if strcmp(region, 'usne')
    latRange = [30 55];
    lonRange = [-100 -62] + 360;
elseif strcmp(region, 'west_africa')
    latRange = [0, 30];
    lonRange = [340, 40];
elseif strcmp(region, 'china')
    latRange = [20, 55];
    lonRange = [75, 135];
elseif strcmp(region, 'world')
    latRange = [-90, 90];
    lonRange = [0, 360];
end

if strcmp(basePeriod, 'past')
    basePeriod = basePeriodYears;
    baseRcp = 'historical/'
elseif strcmp(basePeriod, 'future')
    basePeriod = testPeriodYears;
    baseRcp = 'rcp85/';
end

if strcmp(testPeriod, 'past')
    testPeriod = basePeriodYears;
    testRcp = 'historical/'
elseif strcmp(testPeriod, 'future')
    testPeriod = testPeriodYears;
    testRcp = 'rcp85/';
end

if ~strcmp(testVar, '')
    testDatasetStr = testDataset;
    if strcmp(testDatasetStr, 'cmip5')
        if length(testModels) == 1
            testDatasetStr = ['cmip5-' testModels{1}];
        else 
            testDatasetStr = ['cmip5-mm'];
        end
        
        testDataDir = 'cmip5/output';
        ensemble = 'r1i1p1/';
    elseif strcmp(testDatasetStr, 'ncep')
        testDatasetStr = ['ncep'];
        testDataDir = 'ncep-reanalysis/output';
        ensemble = '';
        testRcp = '';
    end
    
end

baseDatasetStr = baseDataset;
if strcmp(baseDatasetStr, 'cmip5')
    if length(baseModels) == 1
        baseDatasetStr = ['cmip5-' baseModels{1}]
    else
        baseDatasetStr = ['cmip5-mm'];
    end
    
    baseDataDir = 'cmip5/output';
    ensemble = 'r1i1p1/';
elseif strcmp(baseDatasetStr, 'ncep')
    baseDatasetStr = ['ncep'];
    baseDataDir = 'ncep-reanalysis/output';
    ensemble = '';
    baseRcp = '';
end

fileTimeStr = '';
if ~strcmp(testVar, '')
    fileTimeStr = [testDataset '-' season '-' maxMinFileStr '-'  num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '-' baseDataset '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
else
    fileTimeStr = [season '-' maxMinFileStr '-' baseDataset '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
end

plotTitle = [testDataset ' [' num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '] yearly ' season ' ' maxMinStr ' - ' baseDataset ' [' num2str(basePeriod(1)) '-' num2str(basePeriod(end)) ']'];
fileTitle = ['popExposure-' baseVar '-' region '-' fileTimeStr '.' exportformat];

baseExt = {};
futureExt = {};

lat = [];
lon = [];

basePopCount = [];
futurePopCount = [];
constPopCount = [];

if biasCorrect
     load(['cmip5BiasCorrection_' baseVar '_' region '.mat']);
     eval(['cmip5BiasCor = cmip5BiasCorrection_' baseVar '_' region ';']);
end

for m = 1:length(baseModels)
    if strcmp(baseModels{m}, '')
        curModel = baseModels{m};
    else
        curModel = [baseModels{m} '/'];
    end

    baseExt{m} = {};
    
    ['loading ' curModel ' base']
    for y = basePeriodYears(1):yearStep:basePeriodYears(end)
        ['year ' num2str(y) '...']
        if baseRegrid
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp baseVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(baseDaily, latRange, lonRange);
        if strcmp(baseVar, 'tasmax')
            baseDaily{3} = baseDaily{3}(latIndexRange, lonIndexRange, :, :) - 273.15;
        else
            baseDaily{3} = baseDaily{3}(latIndexRange, lonIndexRange, :, :);
        end
        
        if length(lat) == 0
            lat = baseDaily{1}(latIndexRange, lonIndexRange);
            lon = baseDaily{2}(latIndexRange, lonIndexRange);
        end
        
        if annualmean
            baseExtTmp = {{baseDaily{1}, baseDaily{2}, nanmean(nanmean(baseDaily{3}(:,:,:,months,:), 5), 4)}};
        else
            baseExtTmp = findYearlyExtremes(baseDaily, months, findMax);
        end
        baseExtTmp = baseExtTmp{1}{3};
        
        selGrid = zeros(size(lat));
        for xlat = 1:size(baseExtTmp, 1)
            for ylon = 1:size(baseExtTmp, 2)
                if baseExtTmp(xlat, ylon) >= exposureThreshold
                    selGrid(xlat, ylon) = 1;
                end
            end
        end
        
        basePopCount(m, y-basePeriodYears(1)+1) = hh_countPop({lat, lon, selGrid}, region, [2010], 5, popRegrid)
        
        clear baseDaily baseExtTmp;
    end
end

if ~strcmp(testVar, '')
    for m = 1:length(testModels)
        if strcmp(testModels{m}, '')
            curModel = testModels{m};
        else
            curModel = [testModels{m} '/'];
        end
        
        futureExt{m} = {};

        ['loading ' curModel ' future']
        for y = testPeriodYears(1):yearStep:testPeriodYears(end)
            ['year ' num2str(y) '...']
            % load daily data
            testDaily = loadDailyData([baseDir testDataDir '/' curModel ensemble testRcp testVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            
            [latIndexRange, lonIndexRange] = latLonIndexRange(testDaily, latRange, lonRange);
            if strcmp(testVar, 'tasmax')
                testDaily{3} = testDaily{3}(latIndexRange, lonIndexRange, :, :, :) - 273.15;
            else
                testDaily{3} = testDaily{3}(latIndexRange, lonIndexRange, :, :, :);
            end
            
            if annualmean
                testDailyExtTmp = {{testDaily{1}, testDaily{2}, nanmean(nanmean(testDaily{3}(:,:,:,months,:), 5), 4)}};
            else
                testDailyExtTmp = findYearlyExtremes(testDaily, months, findMax);
            end
            testDailyExtTmp = testDailyExtTmp{1}{3};
            
            selGrid = zeros(size(lat));
            for xlat = 1:size(testDailyExtTmp,  1)
                for ylon = 1:size(testDailyExtTmp, 2)
                    if testDailyExtTmp(xlat, ylon) >= exposureThreshold
                        selGrid(xlat, ylon) = 1;
                    end
                end
            end

            futurePopCount(m, y-testPeriodYears(1)+1) = hh_countPop({lat, lon, selGrid}, region, [roundn(y, 1)], 5, popRegrid)
            constPopCount(m, y-testPeriodYears(1)+1) = hh_countPop({lat, lon, selGrid}, region, [2010], 5, popRegrid);
            
            clear testDaily testDailyExtTmp;
        end
    end
end
['done loading...']

basePopCount = nanmean(basePopCount, 1);
futurePopCount = nanmean(futurePopCount, 1);
constPopCount = nanmean(constPopCount, 1);

plotTitle = 'Exposure to 50C temperature, West Africa';
fileTitle = ['heatExposure-' baseDataset '-' baseVar '-' num2str(exposureThreshold) '-' region];

saveData = struct('dataX1', basePeriodYears, ...
                  'dataY1', basePopCount, ...
                  'dataX2', testPeriodYears, ...
                  'dataY2', futurePopCount, ...
                  'dataY3', constPopCount, ...
                  'Xlabel', 'Year', ...
                  'Ylabel', 'Number exposed', ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle);

figure('Color', [1, 1, 1]);
hold on;
plot(saveData.dataX1, saveData.dataY1, 'b', 'LineWidth', 2);
plot(saveData.dataX2, saveData.dataY2, 'r', 'LineWidth', 2);
plot(saveData.dataX2, saveData.dataY3, '--r', 'LineWidth', 2);
title(saveData.plotTitle, 'FontSize', 24);
xlabel(saveData.Xlabel, 'FontSize', 24);
ylabel(saveData.Ylabel, 'FontSize', 24);
l = legend('Past', 'Future', 'Constant population');
set(l, 'FontSize', 24, 'Location', 'best');
set(gcf, 'Position', get(0,'Screensize'));
eval(['export_fig ' saveData.fileTitle '.pdf;']);
save([saveData.fileTitle '.mat'], 'saveData');
close all;
