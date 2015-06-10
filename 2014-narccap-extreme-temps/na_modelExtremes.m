% computes the difference in the yearly mean of maximum summertime
% temperatures between NARCCAP models and NARR reanalysis.

season = 'winter';
baseTime = 'past';
testTime = 'future';
baseDataset = 'narccap';
testDataset = 'narccap';

models = {'crcm/ccsm', 'crcm/cgcm3', 'ecp2/gfdl', ...
          'hrm3/gfdl', 'hrm3/hadcm3', 'mm5i/ccsm', ...
          'mm5i/hadcm3', 'rcm3/cgcm3', 'rcm3/gfdl', ...
          'wrfg/ccsm', 'wrfg/cgcm3'};

baseTimePeriod = 1981:1998;
baseScenario = '20c3m';
futureTimePeriod = 2051:2069;
futureScenario = 'sresa2';

region = 'ne';

baseVar = 'tasmin';
testVar = 'tasmin';

baseRegrid = true;
testRegrid = true;

% average all models or run one at a time
multiModelMean = false;

exportformat = 'pdf';

baseDir = 'e:/data/';
yearStep = 1;

if strcmp(region, 'ne')
    latRange = [39 41];
    lonRange = [280 284];
elseif strcmp(region, 'sw')
    latRange = [34 36];
    lonRange = [248 252];  
end

if strcmp(season, 'summer')
    findMax = true;
    months = [6 7 8];
    tempRange = [0 10];
    maxMinStr = 'maximum';
elseif strcmp(season, 'winter')
    findMax = false;
    months = [12 1 2];
    tempRange = [0 10];
    maxMinStr = 'minimum';
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
    testTitleStr = [testDatasetStr ' [' num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '] yearly '];
end

baseDatasetStr = baseDataset;
if strcmp(baseDatasetStr, 'narccap')
    if length(models) == 1
        modelStr = strsplit(models{1}, '/');
        baseDatasetStr = ['narccap-' modelStr{1} '-' modelStr{2}];
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


plotTitle = [baseVar ': ' testTitleStr season ' - ' baseDataset ' [' num2str(basePeriod(1)) '-' num2str(basePeriod(end)) ']'];
fileTitle = ['modelExtremes-' baseVar '-' season '-' region '-' baseDatasetStr '.' exportformat];

baseExtData = {};
baseMeanData = {};
testExtData = {};
testMeanData = {};

modelMeanChg = [];
modelExtChg = [];

for m = 1:length(models)
    curModel = models{m};

    baseExtData{m} = {};
    baseMeanData{m} = {};
    
    ['loading ' curModel ' base']
    for y = basePeriod(1):yearStep:basePeriod(end)
        ['year ' num2str(y) '...']
        if baseRegrid
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel  '/' baseEmissionsScenarioStr baseVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel '/' baseEmissionsScenarioStr baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(baseDaily, latRange, lonRange);
        baseDaily{3} = baseDaily{3}(latIndexRange, lonIndexRange, :, :, :);
        
        % compute extreme & mean temps
        curBaseMean = {{baseDaily{1}, baseDaily{2}, nanmean(nanmean(baseDaily{3}(:,:,:,months,:), 5), 4)}};
        curBaseExt = findYearlyExtremes(baseDaily, months, findMax);

        baseExtData{m} = {baseExtData{m}{:} curBaseExt{:}};
        baseMeanData{m} = {baseMeanData{m}{:} curBaseMean{:}};
        
        clear baseDaily curBaseMean curBaseExt;
    end
    
    % if we are only looking at one dataset
    if strcmp(testVar, '')
        continue;
    end
    
    testExtData{m} = {};
    testMeanData{m} = {};
    
    ['loading ' curModel ' future']
    for y = testPeriod(1):yearStep:testPeriod(end)
        ['year ' num2str(y) '...']
        % load daily data
        if testRegrid
            testDaily = loadDailyData([baseDir testDataDir '/' curModel '/' futureEmissionsScenarioStr testVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            testDaily = loadDailyData([baseDir testDataDir '/' curModel '/' futureEmissionsScenarioStr testVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(testDaily, latRange, lonRange);
        testDaily{3} = testDaily{3}(latIndexRange, lonIndexRange, :, :, :);
        
        curTestMean = {{testDaily{1}, testDaily{2}, nanmean(nanmean(testDaily{3}(:,:,:,months,:), 5), 4)}};
        curTestExt = findYearlyExtremes(testDaily, months, findMax);
        
        testExtData{m} = {testExtData{m}{:}, curTestExt{:}};
        testMeanData{m} = {testMeanData{m}{:}, curTestMean{:}};
        
        clear testDaily curTestExt curTestMean;
    end

    curBaseExtMean = [];
    curBaseMeanMean = [];
    curTestExtMean = [];
    curTestMeanMean = [];
    
    for y = 1:length(baseExtData{1})
        curBaseExtMean = [curBaseExtMean nanmean(nanmean(nanmean(nanmean(baseExtData{m}{y}{3}, 5), 4), 2), 1)];
        curBaseMeanMean = [curBaseMeanMean nanmean(nanmean(nanmean(nanmean(baseMeanData{m}{y}{3}, 5), 4), 2), 1)];
    end

    for y = 1:length(testExtData{1})
        curTestExtMean = [curTestExtMean nanmean(nanmean(nanmean(nanmean(testExtData{m}{y}{3}, 5), 4), 2), 1)];
        curTestMeanMean = [curTestMeanMean nanmean(nanmean(nanmean(nanmean(testMeanData{m}{y}{3}, 5), 4), 2), 1)];
    end

    modelExtChg(m) = nanmean(curTestExtMean) - nanmean(curBaseExtMean);
    modelMeanChg(m) = nanmean(curTestMeanMean) - nanmean(curBaseMeanMean);
end
['done loading...']

plotTitle = ['NARCCAP NE DJF temperature change'];
saveData = {};

colors = distinguishable_colors(11, [1, 1, 1]);
legendStr = 'legend(';
for i = 1:length(modelMeanChg)
    legendStr = [legendStr '''' models{i} ''','];
end
legendStr = [legendStr '''mean'');'];

saveData{1} = [modelMeanChg; modelExtChg];
saveData{2} = legendStr;
saveData{3} = tempRange;
saveData{4} = region;
saveData{5} = season;
saveData{6} = fileTitle;
saveData{7} = plotTitle;
saveData{8} = colors;

f = figure('Color', [1, 1, 1]);
hold on;
axis square;

for i = 1:length(squeeze(saveData{1}(1, :)))
    plot(saveData{1}(1, i), saveData{1}(2, i), 'x', 'Color', saveData{8}(i,:), 'MarkerSize', 12, 'LineWidth', 2);
    
end

plot(nanmean(saveData{1}(1,:)), nanmean(saveData{1}(2, :)), '*k', 'MarkerSize', 12, 'LineWidth', 2);
xlim(saveData{3});
ylim(saveData{3});
set(gca, 'FontSize', 24);
xlabel('change in mean temperature', 'FontSize', 24);
ylabel('change in extreme temperature', 'FontSize', 24);
title(saveData{7}, 'FontSize', 24);
leg = eval(saveData{2});
set(leg, 'FontSize', 16);
plot(saveData{3}, saveData{3}, 'k');
set(gcf, 'Position', get(0,'Screensize'));
eval(['export_fig ' saveData{6} ';']);
fileTitleParts = strsplit(saveData{6}, '.');
save([fileTitleParts{1} '.mat'],'saveData');
close all;
