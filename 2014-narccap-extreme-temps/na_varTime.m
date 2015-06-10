
season = 'winter';
baseTime = 'past';
testTime = 'future';
baseDataset = 'narccap';
testDataset = 'narccap';

% for swe
% models = {'crcm/ccsm'};
models = {'crcm/ccsm', 'crcm/cgcm3', 'ecp2/gfdl', ...
          'rcm3/cgcm3', 'rcm3/gfdl', ...
          'wrfg/ccsm'};


baseTimePeriod = 1981:1998;
baseScenario = '20c3m';
futureTimePeriod = 2051:2069;
futureScenario = 'sresa2';

baseVar = 'swe';
testVar = 'swe';

baseRegrid = true;
testRegrid = true;

% what level the target var must be to be counted
cutoff = 0;
% greater or less than cutoff
greater = true;

plotRegion = 'usa';
exportformat = 'pdf';

baseDir = 'e:/data/';
yearStep = 1;

if strcmp(season, 'summer')
    months = [6 7 8];
elseif strcmp(season, 'winter')
    months = [12 1 2];
end

if strcmp(testTime, 'past')
    testPeriod = baseTimePeriod;
elseif strcmp(testTime, 'future')
    testPeriod = futureTimePeriod;
end

if strcmp(baseTime, 'past')
    basePeriod = baseTimePeriod;
elseif strcmp(baseTime, 'future')
    basePeriod = futureTimePeriod;
end

latLim = -1;%[23 60];
lonLim = -1;%[-135 -35]+360;

customColorMap = -1;

if ~strcmp(testVar, '')
    plotRange = [-20 20];
    unitsStr = 'change in days/year';
else
    plotRange = [0 50];
    unitsStr = 'days/year';
end

if strcmp(baseVar, 'swe')
    customColorMap = ceprecip;
end

testFileStr = '';
testTitleStr = '';
if ~strcmp(testVar, '')
    testDatasetStr = testDataset;
    if strcmp(testDatasetStr, 'narccap')
        if length(models) == 1
            modelStr = strsplit(models{1}, '/');
            testDatasetStr = ['narccap-' modelStr{1} '-' modelStr{2}];
        else
            testDatasetStr = ['narccap-mm'];
        end
        
        testDataDir = 'narccap/output';
        futureEmissionsScenarioStr = '';
    elseif strcmp(testDatasetStr, 'cmip3')
        if length(models) == 1
            testDatasetStr = ['cmip3-' models{1}];
        else
            testDatasetStr = ['cmip3-mm'];
        end
        
        testDataDir = 'cmip3/output';
        futureEmissionsScenarioStr = [futureScenario '/'];
    end
    testFileStr = [testDatasetStr '-' testTime '-'];
    testTitleStr = [testDatasetStr ' [' num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '] '];
end

baseDatasetStr = baseDataset;
if strcmp(baseDatasetStr, 'narccap')
    if length(models) == 1
        modelStr = strsplit(models{1}, '/');
        baseDatasetStr = ['narccap-' modelStr{1} '-' modelStr{2}]
    else
        baseDatasetStr = ['narccap-mm'];
    end
    
    baseDataDir = 'narccap/output';
    baseEmissionsScenarioStr = '';
elseif strcmp(baseDatasetStr, 'cmip3')
    if length(models) == 1
        baseDatasetStr = ['cmip3-' models{1}];
    else
        baseDatasetStr = ['cmip3-mm'];
    end

    baseDataDir = 'cmip3/output';
    baseEmissionsScenarioStr = [baseScenario '/'];
end

greaterTitleStr = '';
greaterFileStr = '';
if greater
    greaterTitleStr = '>=';
    greaterFileStr = 'gt';
else
    greaterTitleStr = '<=';
    greaterFileStr = 'lt';
end

%plotTitle = ['Yearly maximum temperature'];
plotTitle = [baseVar ' ' greaterTitleStr ' ' num2str(cutoff) ': ' testTitleStr season ' - ' baseDataset ' [' num2str(basePeriod(1)) '-' num2str(basePeriod(end)) ']'];
fileTitle = ['varTime-' baseVar '-' greaterFileStr '-' num2str(cutoff) '-' season '-' testFileStr baseDatasetStr '-' baseTime '.' exportformat];

baseCount = [];
testCount = [];

baseLat = {};
baseLon = {};
testLat = {};
testLon = {};

for m = 1:length(models)
    curModel = models{m};

    baseData{m} = {};
    
    ['loading ' curModel ' base']
    for y = basePeriod(1):yearStep:basePeriod(end)
        ['year ' num2str(y) '...']
        if baseRegrid
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel  '/' baseEmissionsScenarioStr baseVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel '/' baseEmissionsScenarioStr baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end

        if latLim ~= -1
            [latIndexRange, lonIndexRange] = latLonIndexRange(baseDaily, latLim, lonLim);
        else
            latIndexRange = 1:size(baseDaily{1},1);
            lonIndexRange = 1:size(baseDaily{1},2);
        end
        
        if length(baseLat) == 0
            baseLat = baseDaily{1}(latIndexRange, lonIndexRange);
            baseLon = baseDaily{2}(latIndexRange, lonIndexRange);
        end
        
        baseDaily{3} = baseDaily{3}(latIndexRange, lonIndexRange, :, months, :);
        
        if greater
            baseCount(:,:,m,y-basePeriod(1)+1) = squeeze(nansum(nansum(baseDaily{3} >= cutoff, 5), 4));
        else
            baseCount(:,:,m,y-basePeriod(1)+1) = squeeze(nansum(nansum(baseDaily{3} <= cutoff, 5), 4));
        end
        
        clear baseDaily;
    end
    
    % if we are only looking at one dataset
    if strcmp(testVar, '')
        continue;
    end
    
    testData{m} = {};
    
    ['loading ' curModel ' future']
    for y = testPeriod(1):yearStep:testPeriod(end)
        ['year ' num2str(y) '...']
        % load daily data
        if testRegrid
            testDaily = loadDailyData([baseDir testDataDir '/' curModel '/' futureEmissionsScenarioStr testVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            testDaily = loadDailyData([baseDir testDataDir '/' curModel '/' futureEmissionsScenarioStr testVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        
        if latLim ~= -1
            [latIndexRange, lonIndexRange] = latLonIndexRange(testDaily, latLim, lonLim);
        else
            latIndexRange = 1:size(testDaily{1},1);
            lonIndexRange = 1:size(testDaily{1},2);
        end
        
        if length(testLat) == 0
            testLat = testDaily{1}(latIndexRange, lonIndexRange);
            testLon = testDaily{2}(latIndexRange, lonIndexRange);
        end
        
        testDaily{3} = testDaily{3}(latIndexRange, lonIndexRange, :, months, :);
        
        if greater
            testCount(:,:,m,y-testPeriod(1)+1) = squeeze(nansum(nansum(testDaily{3} >= cutoff, 5), 4));
        else
            testCount(:,:,m,y-testPeriod(1)+1) = squeeze(nansum(nansum(testDaily{3} <= cutoff, 5), 4));
        end
        
        clear testDaily;
    end

end
['done loading...']

baseCount = {baseLat, baseLon, squeeze(nanmean(squeeze(nanmean(baseCount, 4)), 3)) ./ length(basePeriod)};

if ~strcmp(testVar, '')    
    testCount = {testLat, testLon, squeeze(nanmean(squeeze(nanmean(testCount, 4)), 3)) ./ length(testPeriod)};
    
    % regrid the base data if needed
    if size(baseCount{3}) ~= size(testCount{3})
        baseExtAvgRegrid = regridGriddata(baseCount, testCount);
    else
        baseExtAvgRegrid = baseCount;
    end
    
    curModelExtAvgBias = {testCount{1}, testCount{2}, testCount{3}-baseExtAvgRegrid{3}};
else
    curModelExtAvgBias = {baseCount{1}, baseCount{2}, baseCount{3}};
end

if customColorMap == -1
    [fg,cb] = plotModelData(curModelExtAvgBias, plotRegion, 'caxis', plotRange);
else
    [fg,cb] = plotModelData(curModelExtAvgBias, plotRegion, 'caxis', plotRange, 'colormap', customColorMap);
end

xlabel(cb, unitsStr, 'FontSize', 24);
cbPos = get(cb, 'Position');
title(plotTitle, 'FontSize', 24);
set(gcf, 'Position', get(0,'Screensize'));
set(gcf, 'Units', 'normalized');
set(gca, 'Units', 'normalized');

ti = get(gca,'TightInset');
set(gca,'Position',[ti(1) cbPos(2) 1-ti(3)-ti(1) 1-ti(4)-cbPos(2)-cbPos(4)]);

eval(['export_fig ' fileTitle ';']);
close all;

