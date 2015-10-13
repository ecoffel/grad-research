
seasons = {'JJA', 'SON', 'DJF', 'MAM'};
seasonRange = {6:8, 9:11, [12 1 2], 3:5};

basePeriod = 'past';
testPeriod = 'past';

baseDataset = 'cmip5';
testDataset = 'cmip5';

%baseModels = {''};
baseModels = {'gfdl-cm3', 'gfdl-esm2g', 'ipsl-cm5a-mr', ...
              'hadgem2-es', 'mpi-esm-mr', 'noresm1-m'};
testModels = {'gfdl-cm3', 'gfdl-esm2g', 'ipsl-cm5a-mr', ...
              'hadgem2-es', 'mpi-esm-mr', 'noresm1-m'};
      
baseVar = 'pr';
testVar = '';

%basePeriodYears = 2060:2070;
basePeriodYears = 1985:2004;
testPeriodYears = 2050:2069;

exportformat = 'pdf';
biasCorrect = false;
blockWater = true;

baseDir = 'e:/data/';
yearStep = 1;

plotRegion = 'nepal';

if strcmp(baseVar, 'zg500')
    plotRange = [-150 150];
    plotXUnits = 'm';
elseif strcmp(baseVar, 'va850') | strcmp(baseVar, 'ua850')
    gridbox = false;
    plotRange = [-10 10];
    plotXUnits = 'm/s';
elseif strcmp(baseVar, 'wb')
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [-10 10];
    else
        plotRange = [25 35];
    end
    plotXUnits = 'degrees C';
elseif strcmp(baseVar, 'rh') || strcmp(baseVar, 'rhum')
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [-5 5];
    else
        plotRange = [0 100];
    end
    plotXUnits = 'percent';
elseif strcmp(baseVar, 'tasmax') | strcmp(baseVar, 'tasmin') | strcmp(baseVar, 'tmax') | strcmp(baseVar, 'tmin')
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [-10 10];
    else
        plotRange = [0 50];
    end
    plotXUnits = 'degrees C';
elseif strcmp(baseVar, 'pr') | strcmp(baseVar, 'prate')
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [-10 10];
    else
        plotRange = [0 10];
    end
    plotXUnits = 'mm/day';
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
    fileTimeStr = [baseDataset '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
end

baseSeasonal = [];
futureSeasonal = [];

baseLat = [];
baseLon = [];

for m = 1:length(baseModels)
    if strcmp(baseModels{m}, '')
        curModel = baseModels{m};
    else
        curModel = [baseModels{m} '/'];
    end

    ['loading ' curModel ' base']
    for y = basePeriod(1):yearStep:basePeriod(end)
        ['year ' num2str(y) '...']
        if strcmp(baseDataset, 'cmip5')
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel baseEnsemble baseRcp baseVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            baseDaily{3} = baseDaily{3} * 86400;
        elseif strcmp(baseDataset, 'ncep')
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel baseEnsemble baseRcp baseVar '/'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            baseDaily{3} = baseDaily{3} * 86400;
        end
        
        if length(baseLat) == 0
            baseLat = baseDaily{1};
        end
        if length(baseLon) == 0
            baseLon = baseDaily{2};
        end
        
        for s = 1:length(seasons)
            season = seasons{s};
            baseSeasonal(:, :, s, m) = squeeze(nanmean(nanmean(baseDaily{3}(:, :, 1, seasonRange{s}, :), 5), 4));
        end
        
        clear baseDaily;
    end
end

if ~strcmp(testVar, '')
    for m = 1:length(testModels)
        if strcmp(testModels{m}, '')
            curModel = testModels{m};
        else
            curModel = [testModels{m} '/'];
        end

        ['loading ' curModel ' future']
        for y = testPeriod(1):yearStep:testPeriod(end)
            ['year ' num2str(y) '...']
            % load daily data
            testDaily = loadDailyData([baseDir testDataDir '/' curModel testEnsemble testRcp testVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            testDaily{3} = testDaily{3} * 86400;
            
            for s = 1:length(seasons)
                season = seasons{s};
                futureSeasonal(:, :, s, m) = squeeze(nanmean(nanmean(testDaily{3}(:, :, 1, seasonRange{s}, :), 5), 4));
            end

            clear testDaily;
        end
    end
end

['done loading...']
futureSeasonal = nanmean(futureSeasonal, 4);
baseSeasonal = nanmean(baseSeasonal, 4);

for s = 1:length(seasons)
    plotTitle = ['CMIP5 mean ' seasons{s} ' precip'];
    fileTitle = ['seasonalMeans-' baseVar '-' seasons{s} '-' fileTimeStr '-' plotRegion '.' exportformat];
    
    result = {baseLat, baseLon, baseSeasonal(:,:,s)};
    saveData = struct('data', {result}, ...
                      'plotRegion', plotRegion, ...
                      'plotRange', plotRange, ...
                      'plotTitle', plotTitle, ...
                      'fileTitle', fileTitle, ...
                      'plotXUnits', plotXUnits, ...
                      'blockWater', blockWater, ...
                      'plotCountries', true);

    plotFromDataFile(saveData);
end

