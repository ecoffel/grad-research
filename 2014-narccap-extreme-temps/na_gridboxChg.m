season = 'winter';
baseTime = 'past';
testTime = 'future';

baseDataset = 'narccap';
testDataset = 'narccap';

baseModels = {'crcm/ccsm', 'crcm/cgcm3', 'ecp2/gfdl', ...
          'hrm3/gfdl', 'hrm3/hadcm3', 'mm5i/ccsm', ...
          'mm5i/hadcm3', 'rcm3/cgcm3', 'rcm3/gfdl', ...
          'wrfg/ccsm', 'wrfg/cgcm3'};
testModels = {'crcm/ccsm', 'crcm/cgcm3', 'ecp2/gfdl', ...
          'hrm3/gfdl', 'hrm3/hadcm3', 'mm5i/ccsm', ...
          'mm5i/hadcm3', 'rcm3/cgcm3', 'rcm3/gfdl', ...
          'wrfg/ccsm', 'wrfg/cgcm3'};

baseTimePeriod = 1981:1998;
baseScenario = '20c3m';
futureTimePeriod = 2051:2069;
futureScenario = 'sresa2';

baseVar = 'tasmax';
testVar = 'tasmax';

region = 'sw';

baseRegrid = true;
testRegrid = true;

% compare the annual mean or the mean extreme or both
meanOrExt = 'both';
findMax = false;

baseDir = 'e:/data/';
baseDataDir = 'narccap/output/'
yearStep = 1;

if strcmp(region, 'ne')
    latRange = [39 39];
    lonRange = [284 284];
elseif strcmp(region, 'sw')
    latRange = [35 35];
    lonRange = [249 249];
end

if findMax
    maxMinStr = 'maximum';
else
    maxMinStr = 'minimum';
end

if strcmp(season, 'summer')
    months = [6 7 8];
elseif strcmp(season, 'winter')
    months = [12 1 2];
end

maxMinStr = [meanOrExt ' '];
maxMinFileStr = meanOrExt;

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

baseExtData = {};
baseMeanData = {};
testExtData = {};
testMeanData = {};

for m = 1:length(baseModels)
    if ~strcmp(baseModels{m}, '')
        curModel = ['/' baseModels{m} '/'];
    else
        curModel = '/';
    end

    baseExtData{m} = {};
    baseMeanData{m} = {};
    
    ['loading ' baseDataset curModel ' ' baseTime]
    for y = basePeriod(1):yearStep:basePeriod(end)
        ['year ' num2str(y) '...']
        
        if baseRegrid
            baseDaily = loadDailyData([baseDir baseDataDir curModel baseVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            baseDaily = loadDailyData([baseDir baseDataDir curModel baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(baseDaily, latRange, lonRange);
        baseDaily{1} = baseDaily{1}(latIndexRange, lonIndexRange);
        baseDaily{2} = baseDaily{2}(latIndexRange, lonIndexRange);
        baseDaily{3} = baseDaily{3}(latIndexRange, lonIndexRange, :, :, :);
        
        baseMeanTmp = {{baseDaily{1}, baseDaily{2}, nanmean(nanmean(baseDaily{3}(:,:,:,months,:), 5), 4)}};
        baseExtTmp = findYearlyExtremes(baseDaily, months, findMax);
        
        baseExtData{m} = {baseExtData{m}{:} baseExtTmp{:}};
        baseMeanData{m} = {baseMeanData{m}{:} baseMeanTmp{:}};
        clear baseDaily baseExtTmp baseMeanTmp;
    end
end

% if we are only looking at one dataset
if ~strcmp(testVar, '')
    for m = 1:length(testModels)
        if ~strcmp(testModels{m}, '')
            curModel = ['/' testModels{m} '/'];
        else
            curModel = '/';
        end
        
        testExtData{m} = {};
        testMeanData{m} = {};

        ['loading ' testDataset curModel ' ' testTime]
        for y = testPeriod(1):yearStep:testPeriod(end)
            ['year ' num2str(y) '...']
            
            % load daily data
            if testRegrid
                testDaily = loadDailyData([baseDir baseDataDir curModel testVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            else
                testDaily = loadDailyData([baseDir baseDataDir curModel testVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            end

            [latIndexRange, lonIndexRange] = latLonIndexRange(testDaily, latRange, lonRange);
            testDaily{1} = testDaily{1}(latIndexRange, lonIndexRange);
            testDaily{2} = testDaily{2}(latIndexRange, lonIndexRange);
            testDaily{3} = testDaily{3}(latIndexRange, lonIndexRange, :, :, :);
            
            testDailyMeanTmp = {{testDaily{1}, testDaily{2}, nanmean(nanmean(testDaily{3}(:,:,:,months,:), 5), 4)}};
            testDailyExtTmp = findYearlyExtremes(testDaily, months, findMax);

            testExtData{m} = {testExtData{m}{:}, testDailyExtTmp{:}};
            testMeanData{m} = {testMeanData{m}{:}, testDailyMeanTmp{:}};
            clear testDaily testDailyExtTmp testDailyMeanTmp;
        end
    end
end
['done loading...']

selectedLat = baseMeanData{1}{1}{1}(1,1);
selectedLon = baseMeanData{1}{1}{2}(1,1);

meanChg = [];
extChg = [];

for m = 1:length(baseModels)
    for y = 1:min(length(testMeanData{m}), length(baseMeanData{m}))
        meanChg(m, y) = testMeanData{m}{y}{3}(1,1) - baseMeanData{m}{y}{3}(1, 1);
        extChg(m, y) = testExtData{m}{y}{3}(1,1) - baseExtData{m}{y}{3}(1, 1);
    end
end

meanChg = nanmean(meanChg, 2);
extChg = nanmean(extChg, 2);










