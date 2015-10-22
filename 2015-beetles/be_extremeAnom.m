% computes the difference in the yearly mean of maximum summertime
% temperatures between NARCCAP models and NARR reanalysis.

season = 'all';
basePeriod = 'past';
testPeriod = 'past';

baseDataset = 'ncep';
testDataset = 'narr';

baseModels = {''};
testModels = {''};
% baseModels = {'bnu-esm', 'canesm2', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
%           'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', 'mri-cgcm3', 'noresm1-m'};
% testModels = {'bnu-esm', 'canesm2', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
%           'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', 'mri-cgcm3', 'noresm1-m'};
      
baseVar = 'tmin';
testVar = 'tasmin';

baseRegrid = false;
modelRegrid = false;

region = 'usne';

basePeriodYears = 1985:2004;
testPeriodYears = 1985:2004;
%testPeriodYears = 2040:2050;

% compare the annual mean temperatures or the mean extreme temperatures
annualmean = true;
exportformat = 'pdf';

blockWater = true;
baseBiasCorrect = false;
testBiasCorrect = false;

baseDir = 'e:/data/';
yearStep = 1;

baseBcStr = '';

if ~testBiasCorrect
    testBcStr = '-nbc';
else
    testBcStr = '-bc';
end

if strcmp(season, 'summer')
    findMax = false;
    months = [6 7 8];
    maxMinStr = 'minimum';
elseif strcmp(season, 'winter')
    findMax = false;
    months = [12 1 2];
    maxMinStr = 'minimum';
elseif strcmp(season, 'all')
    findMax = false;
    months = 1:12;
    maxMinStr = 'minimum';
end

if annualmean
    maxMinStr = ['mean ' maxMinStr];
    maxMinFileStr = 'mean';
else
    maxMinFileStr = 'ext';
end

plotRegion = 'usne';

if strcmp(baseVar, 'bt')
    gridbox = true;
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [0 5];
    else
        plotRange = [-20 20];
    end
    plotXUnits = 'degrees C';
elseif strcmp(baseVar, 'tasmax') | strcmp(baseVar, 'tasmin') | strcmp(baseVar, 'tmax') | strcmp(baseVar, 'tmin')
    gridbox = true;
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [0 5];
    else
        plotRange = [0 50];
    end
    plotXUnits = 'degrees C';
end

if strcmp(basePeriod, 'past')
    basePeriod = basePeriodYears;
    baseRcp = 'historical/';
elseif strcmp(basePeriod, 'future')
    basePeriod = testPeriodYears;
    baseRcp = 'rcp85/';
end

if strcmp(testPeriod, 'past')
    testPeriod = basePeriodYears;
    testRcp = 'historical/';
elseif strcmp(testPeriod, 'future')
    testPeriod = testPeriodYears;
    testRcp = 'rcp85/';
end

testDatasetStr = testDataset;
if ~strcmp(testVar, '')
    if strcmp(testDatasetStr, 'cmip5')
        if length(testModels) == 1
            testDatasetStr = ['cmip5-' testModels{1}];
        else 
            testDatasetStr = ['cmip5-mm'];
        end
        
        testDataDir = 'cmip5/output';
        testEnsemble = 'r1i1p1/';
    elseif strcmp(testDatasetStr, 'ncep')
        testDatasetStr = ['ncep'];
        testDataDir = 'ncep-reanalysis/output';
        testEnsemble = '';
        testRcp = '';
    elseif strcmp(testDatasetStr, 'narr')
        testDatasetStr = ['narr'];
        testDataDir = 'narr/output';
        testEnsemble = '';
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
    baseEnsemble = 'r1i1p1/';
elseif strcmp(baseDatasetStr, 'ncep')
    baseDatasetStr = ['ncep'];
    baseDataDir = 'ncep-reanalysis/output';
    baseEnsemble = '';
    baseRcp = '';
elseif strcmp(baseDatasetStr, 'narr')
    baseDatasetStr = ['narr'];
    baseDataDir = 'narr/output';
    baseEnsemble = '';
    baseRcp = '';
end

fileTimeStr = '';
if ~strcmp(testVar, '')
    fileTimeStr = [testDatasetStr testBcStr '-' season '-' maxMinFileStr '-'  num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '-' baseDatasetStr '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
else
    fileTimeStr = [season '-' maxMinFileStr '-' baseDatasetStr '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
end

fileTitle = ['extremeAnom-' baseVar '-' fileTimeStr '.' exportformat];

baseExt = {};
futureExt = {};

for m = 1:length(baseModels)
    if strcmp(baseModels{m}, '')
        curModel = baseModels{m};
    else
        curModel = [baseModels{m} '/'];
    end

    baseExt{m} = {};
    
    ['loading ' curModel ' base']
    for y = basePeriod(1):yearStep:basePeriod(end)
        ['year ' num2str(y) '...']
        baseDaily = loadDailyData([baseDir baseDataDir '/' curModel baseEnsemble baseRcp baseVar '/regrid/' region baseBcStr], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        
        if strcmp(baseVar, 'tmax') | strcmp(baseVar, 'tmin')
            baseDaily{3} = baseDaily{3} - 273.15;
        end
        
        if annualmean
            baseExtTmp = {{baseDaily{1}, baseDaily{2}, nanmean(nanmean(baseDaily{3}(:,:,:,months,:), 5), 4)}};
        else
            baseExtTmp = findYearlyExtremes(baseDaily, months, findMax);
        end
        
        baseExt{m} = {baseExt{m}{:} baseExtTmp{:}};
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
        for y = testPeriod(1):yearStep:testPeriod(end)
            ['year ' num2str(y) '...']
            % load daily data
            testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar '/regrid/' region testBcStr], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

            if strcmp(testVar, 'tmax') | strcmp(testVar, 'tmin')
                testDaily{3} = testDaily{3} - 273.15;
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

% construct plotable structures
baseAvg = {baseExt{1}{1}{1}, baseExt{1}{1}{2}, squeeze(nanmean(nanmean(baseAvg, 4), 3))};

if ~strcmp(testVar, '')
    for m = 1:length(futureExt)
        for y = 1:length(futureExt{m})
            modelAvg(:,:,m,y) = futureExt{m}{y}{3};
        end
    end
    modelAvg = {futureExt{1}{1}{1}, futureExt{1}{1}{2}, nanmean(nanmean(modelAvg, 4), 3)};
    
    % regrid the base data if needed
    if size(baseAvg{3}) ~= size(modelAvg{3})
        baseExtAvgRegrid = regridGriddata(baseAvg, modelAvg);
    else
        baseExtAvgRegrid = baseAvg;
    end
    
    xdim = 1:min(size(modelAvg{3}, 1), size(baseExtAvgRegrid{3}, 1));
    ydim = 1:min(size(modelAvg{3}, 2), size(baseExtAvgRegrid{3}, 2));
    result = {modelAvg{1}, modelAvg{2}, modelAvg{3}(xdim, ydim)-baseExtAvgRegrid{3}(xdim, ydim)};
else
    result = baseAvg;
end

plotTitle = ['NARR - NCEP mean daily minimum temperature bias'];

saveData = struct('data', {result}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', plotRange, ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', plotXUnits, ...
                  'blockWater', blockWater);

plotFromDataFile(saveData);

