% computes the difference in the yearly mean of maximum summertime
% temperatures between NARCCAP models and NARR reanalysis.

season = 'all';
basePeriod = 'past';
testPeriod = 'past';

baseDataset = 'ncep';
testDataset = 'cmip5';

baseModels = {''};
% testModels = {''};
% baseModels = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
%           'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
%           'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};
testModels = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
          'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};
      
baseVar = 'tmax';
testVar = 'tasmax';

%basePeriodYears = 2060:2070;
basePeriodYears = 1985:2004;
testPeriodYears = 2050:2069;

% compare the annual mean temperatures or the mean extreme temperatures
annualmean = true;
exportformat = 'pdf';

biasCorrect = true;
blockWater = true;

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

plotRegion = 'world';

if strcmp(baseVar, 'zg500')
    gridbox = false;
    plotRange = [-150 150];
    plotXUnits = 'm';
elseif strcmp(baseVar, 'mrso')
    gridbox = true;
    if strcmp(dataset, 'narr')
        plotRange = [-200 200];
        plotXUnits = 'kg / m^2';
    else
        plotRange = [-200 200];
        plotXUnits = 'kg / m^2';
    end
elseif strcmp(baseVar, 'swe')
    gridbox = true;
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [-0.01 0.01];
    else
        plotRange = [-0.02 0.02];
    end
    plotXUnits = 'm';
elseif strcmp(baseVar, 'va850') | strcmp(baseVar, 'ua850')
    gridbox = false;
    plotRange = [-10 10];
    plotXUnits = 'm/s';
elseif strcmp(baseVar, 'huss')
    gridbox = true;
    plotRange = [-0.003 0.003];
    plotXUnits = 'kg water vapor / kg air';
elseif strcmp(baseVar, 'hi')
    gridbox = true;
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [-10 10];
    else
        plotRange = [26 60];
    end
    plotXUnits = 'degrees C';
elseif strcmp(baseVar, 'wb')
    gridbox = true;
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [-10 10];
    else
        plotRange = [25 35];
    end
    plotXUnits = 'degrees C';
elseif strcmp(baseVar, 'rh') || strcmp(baseVar, 'rhum')
    gridbox = true;
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [-5 5];
    else
        plotRange = [0 100];
    end
    plotXUnits = 'percent';
elseif strcmp(baseVar, 'tasmax') | strcmp(baseVar, 'tasmin') | strcmp(baseVar, 'tmax') | strcmp(baseVar, 'tmin')
    gridbox = true;
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [-10 10];
    else
        plotRange = [0 50];
    end
    plotXUnits = 'degrees C';
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
        testEnsemble = 'r1i1p1/';
    elseif strcmp(testDatasetStr, 'ncep')
        testDatasetStr = ['ncep'];
        testDataDir = 'ncep-reanalysis/output';
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
end


fileTimeStr = '';
if ~strcmp(testVar, '')
    fileTimeStr = [testDataset '-' season '-' maxMinFileStr '-'  num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '-' baseDataset '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
else
    fileTimeStr = [season '-' maxMinFileStr '-' baseDataset '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
end

plotTitle = [testDataset ' [' num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '] yearly ' season ' ' maxMinStr ' - ' baseDataset ' [' num2str(basePeriod(1)) '-' num2str(basePeriod(end)) ']'];
fileTitle = ['extremeAnom-' baseVar '-' fileTimeStr '.' exportformat];
plotTitle = ['CMIP5 minus NCEP tasmax'];

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
        if strcmp(baseDataset, 'cmip5')
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel baseEnsemble baseRcp baseVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        elseif strcmp(baseDataset, 'ncep')
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel baseEnsemble baseRcp baseVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            
            if strcmp(baseVar, 'tmax')
                baseDaily{3} = baseDaily{3}-273.15;
            end
            
            if length(size(baseDaily{3}) == 4)
                baseDaily{3} = squeeze(baseDaily{3}(:,:,1,:));
            end
        end
        
        baseExtTmp = {};
        
        if annualmean
            if length(size(baseDaily{3})) == 3
                baseExtTmp = {{baseDaily{1}, baseDaily{2}, nanmean(baseDaily{3}(:,:,:), 3)}};
            elseif length(size(baseDaily{3})) == 5
                baseExtTmp = {{baseDaily{1}, baseDaily{2}, nanmean(nanmean(baseDaily{3}(:,:,:,months,:), 5), 4)}};
            else
                ['baseDaily dimensions unexpected']
            end
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
            if biasCorrect
                testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar '/regrid/world'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            else
                testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
                testDaily{3} = testDaily{3}-273.15;
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
    
    result = {modelAvg{1}, modelAvg{2}, modelAvg{3}-baseExtAvgRegrid{3}};
else
    result = baseAvg;
end

plotTitle = ['CMIP5 mean daily maximum temperature bias (corrected)'];

saveData = struct('data', {result}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', plotRange, ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', plotXUnits, ...
                  'blockWater', blockWater);

plotFromDataFile(saveData);

