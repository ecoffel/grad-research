% computes the difference in the yearly mean of maximum summertime
% temperatures between NARCCAP models and NARR reanalysis.

season = 'summer';
testTime = 'future';
baseDataset = 'cmip5';
testDataset = 'cmip5';

models = {'gfdl-cm3'};
% models = {'bnu-esm', 'canesm2', 'ccsm4', 'cesm1-bgc', ...
%           'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
%           'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-es', ...
%           'ipsl-cm5a-mr', 'miroc-esm', 'mpi-esm-mr', 'mri-cgcm3', ...
%           'noresm1-m'};

%models = {'gfdl-cm3'};

stdGridModel = 'ccsm4';

modelDir = 'cmip5/output';
ensemble = 'r1i1p1';
modelVar = 'huss';
modelRcp = 'rcp85';

baseVar = 'huss';
baseRcp = 'historical'

baseRegrid = false;
modelRegrid = false;

% compare the annual mean temperatures or the mean extreme temperatures
annualmean = false;
exportformat = 'pdf';

baseDir = 'e:/data/';
yearStep = 1;

if strcmp(season, 'summer')
    findMax = true;
    months = [5 6 7 8 9];
    maxMinStr = 'maximum';
elseif strcmp(season, 'winter')
    findMax = false;
    months = [12 1 2];
    maxMinStr = 'minimum';
end

if annualmean
    maxMinStr = ['mean ' maxMinStr];
    maxMinFileStr = 'mean';
else
    maxMinFileStr = 'ext';
end

basePeriod = 1985:2005;
futurePeriod = 2041:2060;

plotRegion = 'usa';

if strcmp(testTime, 'past')
    testPeriod = basePeriod;
    plotRange = [-8 8];
elseif strcmp(testTime, 'future')
    testPeriod = futurePeriod;
    plotRange = [-8 8];
end

%plotTitle = ['Mean summer daily maximum temperature'];
plotTitle = [testDataset ' [' num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '] yearly ' season ' ' maxMinStr ' - ' baseDataset ' [' num2str(basePeriod(1)) '-' num2str(basePeriod(end)) ']'];
fileTitle = ['extremeAnom-' testDataset '-' season '-' maxMinFileStr '-'  num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '-' baseDataset '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end)) '.' exportformat];

baseExt = {};
futureExt = {};

for m = 1:length(models)
    curModel = models{m};

    baseExt{m} = {};
    
    ['loading ' curModel ' base']
    for y = basePeriod(1):yearStep:basePeriod(end)
        ['year ' num2str(y) '...']
        if baseRegrid
            baseDaily = loadDailyData([baseDir modelDir '/' curModel '/' ensemble '/' baseRcp '/' baseVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            baseDaily = loadDailyData([baseDir modelDir '/' curModel '/' ensemble '/' baseRcp '/' baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        if annualmean
            baseExtTmp = {{baseDaily{1}, baseDaily{2}, nanmean(nanmean(baseDaily{3}(:,:,:,months,:), 5), 4)}};
        else
            baseExtTmp = findYearlyExtremes(baseDaily, months, findMax);
        end
        baseExt{m} = {baseExt{m}{:} baseExtTmp{:}};
        clear baseDaily baseExtTmp;
    end

    futureExt{m} = {};
    
    ['loading ' curModel ' future']
    for y = testPeriod(1):yearStep:testPeriod(end)
        ['year ' num2str(y) '...']
        % load daily data
        if modelRegrid
            testDaily = loadDailyData([baseDir modelDir '/' curModel '/' ensemble '/' modelRcp '/' modelVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            testDaily = loadDailyData([baseDir modelDir '/' curModel '/' ensemble '/' modelRcp '/' modelVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        
        if annualmean
            testDailyExtTmp = {{testDaily{1}, testDaily{2}, nanmean(nanmean(testDaily{3}(:,:,:,months,:), 5), 4)}};
        else
            testDailyExtTmp = findYearlyExtremes(testDaily, months, findMax);
        end
        
        futureExt{m} = {futureExt{m}{:}, testDailyExtTmp{:}};
        clear testDaily testDailyExtTmp;
    end

end
['done loading...']
modelAvg = [];
baseAvg = [];

% average over models and years
for m = 1:length(baseExt)
    for y = 1:length(baseExt{m})
        baseAvg(:,:,m,y) = baseExt{m}{y}{3};
    end
end

for m = 1:length(futureExt)
    for y = 1:length(futureExt{m})
        modelAvg(:,:,m,y) = futureExt{m}{y}{3};
    end
end

% construct plotable structures
modelAvg = {futureExt{1}{1}{1}, futureExt{1}{1}{2}, nanmean(nanmean(modelAvg, 4), 3)};
baseAvg = {baseExt{1}{1}{1}, baseExt{1}{1}{2}, squeeze(nanmean(nanmean(baseAvg, 4), 3))};

% regrid the base data if needed
if size(baseAvg{3}) ~= size(modelAvg{3})
    baseExtAvgRegrid = regridGriddata(baseAvg, modelAvg);
else
    baseExtAvgRegrid = baseAvg;
end

curModelExtAvgBias = {modelAvg{1}, modelAvg{2}, modelAvg{3}-baseExtAvgRegrid{3}};

[fg,cb] = plotModelData(curModelExtAvgBias, plotRegion, 'caxis', plotRange);
xlabel(cb, 'degrees C', 'FontSize', 24);
cbPos = get(cb, 'Position');
title(plotTitle, 'FontSize', 30);
set(gcf, 'Position', get(0,'Screensize'));
set(gcf, 'Units', 'normalized');
set(gca, 'Units', 'normalized');

ti = get(gca,'TightInset');
set(gca,'Position',[ti(1) cbPos(2) 1-ti(3)-ti(1) 1-ti(4)-cbPos(2)-cbPos(4)]);
eval(['export_fig ' fileTitle ';']);
close all;

