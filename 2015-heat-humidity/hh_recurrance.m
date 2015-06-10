% computes the difference in the yearly mean of maximum summertime
% temperatures between NARCCAP models and NARR reanalysis.

season = 'all';
basePeriod = 'past';
testPeriod = 'future';

baseDataset = 'cmip5';
testDataset = 'cmip5';

%baseModels = {''};

% baseModels = {'canesm2'};
% testModels = {'canesm2'};

baseModels = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
          'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};
testModels = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
          'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};
      
% models = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
%           'gfdl-cm3', 'gfdl-esm2g', 'ipsl-cm5a-mr', ...
%           'mri-cgcm3', 'noresm1-m'};
       
% models = {'bnu-esm', 'canesm2', 'ccsm4', 'cesm1-bgc', ...
%           'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
%           'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-es', ...
%           'ipsl-cm5a-mr', 'miroc-esm', 'mpi-esm-mr', 'mri-cgcm3', ...
%           'noresm1-m'};

baseVar = 'wb';
testVar = 'wb';

baseRegrid = true;
modelRegrid = true;

basePeriodYears = 1985:2004;
testPeriodYears = 2050:2069;

% compare the annual mean temperatures or the mean extreme temperatures
annualmean = false;
exportformat = 'pdf';

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

if strcmp(baseVar, 'hi')
    gridbox = true;
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [0 100];
    else
        plotRange = [0 100];
    end
    plotXUnits = 'number of days';
elseif strcmp(baseVar, 'wb')
    gridbox = true;
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [0 100];
    else
        plotRange = [0 100];
    end
    plotXUnits = 'number of days';
elseif strcmp(baseVar, 'tasmax') | strcmp(baseVar, 'tasmin') | strcmp(baseVar, 'tmax') | strcmp(baseVar, 'tmin')
    gridbox = true;
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [0 100];
    else
        plotRange = [0 100];
    end
    plotXUnits = 'number of days';
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

if ~strcmp(testVar, '')
    testDatasetStr = testDataset;
    if strcmp(testDatasetStr, 'cmip5')
        if length(testModels) == 1
            testDatasetStr = ['cmip5-' testModels{1}];
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
    
end

baseDatasetStr = baseDataset;
if strcmp(baseDatasetStr, 'cmip5')
    if length(baseModels) == 1
        baseDatasetStr = ['cmip5-' baseModels{1}]
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
if ~strcmp(testVar, '')
    fileTimeStr = [testDataset '-' season '-' maxMinFileStr '-'  num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '-' baseDataset '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
else
    fileTimeStr = [season '-' maxMinFileStr '-' baseDataset '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
end

baseExt = {};
futureData = {};

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
        if baseRegrid
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp baseVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        
        if strcmp(testVar, '') & (strcmp(baseVar, 'tasmax') | strcmp(baseVar, 'tasmin') | strcmp(baseVar, 'tmax') | strcmp(baseVar, 'tmin'))
            baseDaily{3} = baseDaily{3}-273.15;
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

baseMeanMax = [];
for m = 1:length(baseExt)
    for y = 1:length(baseExt{m})
        baseMeanMax(:,:,m,y) = baseExt{m}{y}{3};
    end
end
baseMeanMax = squeeze(nanmean(baseMeanMax, 4));

testExceedences = [];

if ~strcmp(testVar, '')
    for m = 1:length(testModels)
        if strcmp(testModels{m}, '')
            curModel = testModels{m};
        else
            curModel = [testModels{m} '/'];
        end
        
        futureData{m} = {};

        ['loading ' curModel ' future']
        for y = testPeriod(1):yearStep:testPeriod(end)
            ['year ' num2str(y) '...']
            % load daily data
            if modelRegrid
                testDaily = loadDailyData([baseDir testDataDir '/' curModel ensemble testRcp testVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            else
                testDaily = loadDailyData([baseDir testDataDir '/' curModel ensemble testRcp testVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            end
            
            if length(testExceedences) == 0
                testExceedences = zeros(size(testDaily{3}, 1), size(testDaily{3}, 2), length(testModels), length(testPeriod));
            end
            
            testDaily = {testDaily{1}, testDaily{2}, testDaily{3}(:,:,1,months,:)};
            
            for xlat = 1:size(testDaily{3}, 1)
                for ylat = 1:size(testDaily{3}, 2)
                    exCnt = 0;
                    for mo = 1:size(testDaily{3}(xlat, ylat, :, :), 3)
                        for d = 1:size(testDaily{3}(xlat, ylat, :, :), 4)
                            if testDaily{3}(xlat, ylat, mo, d) > baseMeanMax(xlat,ylat,m)
                                exCnt = exCnt+1;
                            end
                        end
                    end
                    testExceedences(xlat,ylat,m,y-testPeriod(1)+1) = testExceedences(xlat,ylat,m,y-testPeriod(1)+1) + exCnt;
                end
            end
            
            clear testDaily;
        end
    end
end
testExceedences = nanmean(nanmean(testExceedences, 4), 3);
['done loading...']

result = {baseExt{1}{1}{1}, baseExt{1}{1}{2}, testExceedences};

fileTitle = ['recurrance-' baseVar '-' fileTimeStr '-' plotRegion '.' exportformat];
plotTitle = ['Heat index'];


saveData = struct('data', {result}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', plotRange, ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', plotXUnits, ...
                  'blockWater', blockWater);

plotFromDataFile(saveData);

