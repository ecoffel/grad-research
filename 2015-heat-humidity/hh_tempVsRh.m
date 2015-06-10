season = 'all';
basePeriod = 'past';
testPeriod = 'future';

baseDataset = 'cmip5';
testDataset = 'cmip5';

baseModels = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', ...
          'ipsl-cm5a-mr', ...
          'mri-cgcm3', 'noresm1-m'};
testModels = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', ...
          'ipsl-cm5a-mr', ...
          'mri-cgcm3', 'noresm1-m'};

tempVar = 'tasmax';
rhVar = 'rh';

baseRegrid = true;
modelRegrid = true;

basePeriodYears = 1985:2005;
testPeriodYears = 2061:2080;

region = 'w-africa';

if strcmp(region, 'ne-us')
    latRange = [39 41];
    lonRange = [280 284];
elseif strcmp(region, 'e-china')
    latRange = [30 34];
    lonRange = [110 118];
elseif strcmp(region, 'w-africa')
    latRange = [7 12];
    lonRange = [0 10];
end

% compare the annual mean temperatures or the mean extreme temperatures
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

if strcmp(basePeriod, 'past')
    basePeriod = basePeriodYears;
    baseRcp = 'historical'
elseif strcmp(basePeriod, 'future')
    basePeriod = testPeriodYears;
    baseRcp = 'rcp85';
end

if strcmp(testPeriod, 'past')
    testPeriod = basePeriodYears;
    testRcp = 'historical'
elseif strcmp(testPeriod, 'future')
    testPeriod = testPeriodYears;
    testRcp = 'rcp85';
end

testDatasetStr = testDataset;
if strcmp(testDatasetStr, 'cmip5')
    if length(testModels) == 1
        modelStr = strsplit(testModels{1}, '/');
        testDatasetStr = ['cmip5-' modelStr];
    else 
        testDatasetStr = ['cmip5-mm'];
    end

    testDataDir = 'cmip5/output';
    testRcp = 'rcp85/';
    ensemble = 'r1i1p1/';
elseif strcmp(testDatasetStr, 'ncep')
    testDatasetStr = ['ncep'];
    testDataDir = 'ncep-reanalysis/output';
    ensemble = '';
    testRcp = '';
end

baseDatasetStr = baseDataset;
if strcmp(baseDatasetStr, 'cmip5')
    if length(baseModels) == 1
        modelStr = strsplit(baseModels{1}, '/');
        baseDatasetStr = ['cmip5-' modelStr];
    else
        baseDatasetStr = ['cmip5-mm'];
    end
    
    baseDataDir = 'cmip5/output';
    baseRcp = 'historical/';
    ensemble = 'r1i1p1/';
elseif strcmp(baseDatasetStr, 'ncep')
    baseDatasetStr = ['ncep'];
    baseDataDir = 'ncep-reanalysis/output';
    ensemble = '';
    baseRcp = '';
end


fileTimeStr = '';
fileTimeStr = [testDataset '-' season  '-'  num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '-' baseDataset '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];

%plotTitle = [testDataset ' [' num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '] yearly ' season ' ' maxMinStr ' - ' baseDataset ' [' num2str(basePeriod(1)) '-' num2str(basePeriod(end)) ']'];
fileTitle = ['hh_tempVsRh' '-' region '-' fileTimeStr '.' exportformat];
plotTitle = ['CMIP5 minus NCEP tasmax'];

baseExtTemp = {};
baseMeanTemp = {};
baseExtRh = {};
baseMeanRh = {};

futureExtTemp = {};
futureMeanTemp = {};
futureExtRh = {};
futureMeanRh = {};

for m = 1:length(baseModels)
    if strcmp(baseModels{m}, '')
        curModel = baseModels{m};
    else
        curModel = [baseModels{m} '/'];
    end

    baseMeanTemp{m} = {};
    baseExtTemp{m} = {};
    baseMeanRh{m} = {};
    baseExtRh{m} = {};
    
    ['loading ' curModel ' base']
    for y = basePeriod(1):yearStep:basePeriod(end)
        ['year ' num2str(y) '...']
        if baseRegrid
            baseDailyTemp = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp tempVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            baseDailyRh = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp rhVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            baseDailyTemp = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp tempVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            baseDailyRh = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp rhVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(baseDailyTemp, latRange, lonRange);
        baseDailyTemp{3} = baseDailyTemp{3}(latIndexRange, lonIndexRange, :, :, :)-273.15;
        baseDailyRh{3} = baseDailyRh{3}(latIndexRange, lonIndexRange, :, :, :);
        
        baseMeanTmpTemp = squeeze(nanmean(nanmean(baseDailyTemp{3}(:,:,:,months,:), 5), 4));
        baseMeanTmpRh = squeeze(nanmean(nanmean(baseDailyRh{3}(:,:,:,months,:), 5), 4));
        
        baseDailyTemp{3} = baseDailyTemp{3}(:,:,:,months,:);
        baseDailyRh{3} = baseDailyRh{3}(:,:,:,months,:);
        baseTempLinear = reshape(baseDailyTemp{3}, [size(baseDailyTemp{3}, 1), size(baseDailyTemp{3}, 2), ...
                                                    size(baseDailyTemp{3}, 3)*size(baseDailyTemp{3}, 4)*size(baseDailyTemp{3}, 5)]);
        baseRhLinear = reshape(baseDailyRh{3}, [size(baseDailyRh{3}, 1), size(baseDailyRh{3}, 2), ...
                                                    size(baseDailyRh{3}, 3)*size(baseDailyRh{3}, 4)*size(baseDailyRh{3}, 5)]);
                     
        baseExtTempTmp = [];
        baseExtRhTmp = [];
        
        for xlat = 1:size(baseTempLinear, 1)
            for ylon = 1:size(baseTempLinear, 2)
                t = squeeze(baseTempLinear(xlat, ylon, :));
                r = squeeze(baseRhLinear(xlat, ylon, :));
                
                maxTempInd = find(t == nanmax(t));
                baseExtTempTmp(xlat, ylon) = t(maxTempInd);
                baseExtRhTmp(xlat, ylon) = r(maxTempInd);
                
                clear t r;
            end
        end
        
        baseMeanTemp{m} = {baseMeanTemp{m}{:} baseMeanTmpTemp};
        baseMeanRh{m} = {baseMeanRh{m}{:} baseMeanTmpRh};
        
        baseExtTemp{m} = {baseExtTemp{m}{:} baseExtTempTmp};
        baseExtRh{m} = {baseExtRh{m}{:} baseExtRhTmp};
        
        clear baseDailyTemp baseDailyRh baseMeanTmpTemp baseMeanTmpRh 
        clear baseTempLinear baseRhLinear;
    end
end

for m = 1:length(testModels)
    if strcmp(testModels{m}, '')
        curModel = testModels{m};
    else
        curModel = [testModels{m} '/'];
    end

    testMeanTemp{m} = {};
    testExtTemp{m} = {};
    testMeanRh{m} = {};
    testExtRh{m} = {};

    ['loading ' curModel ' future']
    for y = testPeriod(1):yearStep:testPeriod(end)
        ['year ' num2str(y) '...']
        % load daily data
        if modelRegrid
            testDailyTemp = loadDailyData([baseDir testDataDir '/' curModel ensemble testRcp tempVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            testDailyRh = loadDailyData([baseDir testDataDir '/' curModel ensemble testRcp rhVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            testDailyTemp = loadDailyData([baseDir testDataDir '/' curModel ensemble testRcp tempVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            testDailyRh = loadDailyData([baseDir testDataDir '/' curModel ensemble testRcp rhVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end

        [latIndexRange, lonIndexRange] = latLonIndexRange(testDailyTemp, latRange, lonRange);
        testDailyTemp{3} = testDailyTemp{3}(latIndexRange, lonIndexRange, :, :, :)-273.15;
        testDailyRh{3} = testDailyRh{3}(latIndexRange, lonIndexRange, :, :, :);

        testMeanTmpTemp = squeeze(nanmean(nanmean(testDailyTemp{3}(:,:,:,months,:), 5), 4));
        testMeanTmpRh = squeeze(nanmean(nanmean(testDailyRh{3}(:,:,:,months,:), 5), 4));

        testDailyTemp{3} = testDailyTemp{3}(:,:,:,months,:);
        testDailyRh{3} = testDailyRh{3}(:,:,:,months,:);
        testTempLinear = reshape(testDailyTemp{3}, [size(testDailyTemp{3}, 1), size(testDailyTemp{3}, 2), ...
                                                    size(testDailyTemp{3}, 3)*size(testDailyTemp{3}, 4)*size(testDailyTemp{3}, 5)]);
        testRhLinear = reshape(testDailyRh{3}, [size(testDailyRh{3}, 1), size(testDailyRh{3}, 2), ...
                                                    size(testDailyRh{3}, 3)*size(testDailyRh{3}, 4)*size(testDailyRh{3}, 5)]);

        testExtTempTmp = [];
        testExtRhTmp = [];

        for xlat = 1:size(testTempLinear, 1)
            for ylon = 1:size(testTempLinear, 2)
                t = squeeze(testTempLinear(xlat, ylon, :));
                r = squeeze(testRhLinear(xlat, ylon, :));

                maxTempInd = find(t == nanmax(t));
                testExtTempTmp(xlat, ylon) = t(maxTempInd);
                testExtRhTmp(xlat, ylon) = r(maxTempInd);

                clear t r;
            end
        end

        testMeanTemp{m} = {testMeanTemp{m}{:} testMeanTmpTemp};
        testMeanRh{m} = {testMeanRh{m}{:} testMeanTmpRh};

        testExtTemp{m} = {testExtTemp{m}{:} testExtTempTmp};
        testExtRh{m} = {testExtRh{m}{:} testExtRhTmp};

        clear testDailyTemp testDailyRh testMeanTmpTemp testMeanTmpRh 
        clear testTempLinear testRhLinear;
    end
end


['done loading...']
baseExtTempAvg = [];
baseExtRhAvg = [];

% average over models and years
for m = 1:length(baseExtTemp)
    for y = 1:length(baseExtTemp{m})
        baseExtTempAvg(m, y) = squeeze(nanmean(nanmean(baseExtTemp{m}{y}, 2), 1));
        baseExtRhAvg(m, y) = squeeze(nanmean(nanmean(baseExtRh{m}{y}, 2), 1));
    end
end
baseExtTempAvg = nanmean(baseExtTempAvg, 2);
baseExtRhAvg = nanmean(baseExtRhAvg, 2);

testExtTempAvg = [];
testExtRhAvg = [];

for m = 1:length(testExtTemp)
    for y = 1:length(testExtTemp{m})
        testExtTempAvg(m, y) = squeeze(nanmean(nanmean(testExtTemp{m}{y}, 2), 1));
        testExtRhAvg(m, y) = squeeze(nanmean(nanmean(testExtRh{m}{y}, 2), 1));
    end
end

testExtTempAvg = nanmean(testExtTempAvg, 2);
testExtRhAvg = nanmean(testExtRhAvg, 2);


tempDiff = [];
rhDiff = [];

for m = 1:length(baseExtTempAvg)
    tempDiff(m) = testExtTempAvg(m) - baseExtTempAvg(m);
    rhDiff(m) = testExtRhAvg(m) - baseExtRhAvg(m);
end

xRange = [0 10];
yRange = [-20 20];
xlabelStr = 'temp change (degrees C)';
ylabelStr =  'rh change (%)';

plotTitle = 'Temp vs. RH';

saveData = {};
saveData{1} = [tempDiff rhDiff];
saveData{2} = '';
saveData{3} = xRange;
saveData{4} = region;
saveData{5} = season;
saveData{6} = fileTitle;
saveData{7} = plotTitle;

f = figure('Color', [1, 1, 1]);
hold on;
plot(tempDiff, rhDiff, 'ok');
xlim([0 10]);
ylim([-20 20]);
xlabel('temp change (degrees C)', 'FontSize', 24);
ylabel('rh change (%)', 'FontSize', 24);
title(plotTitle, 'FontSize', 24);
lsline;

set(gcf, 'Position', get(0,'Screensize'));
eval(['export_fig ' fileTitle ';']);
fileTitleParts = strsplit(fileTitle, '.');
save([fileTitleParts{1} '.mat'],'saveData');
close all;













