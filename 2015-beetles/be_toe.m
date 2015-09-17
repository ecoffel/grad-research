% computes the difference in the yearly mean of maximum summertime
% temperatures between NARCCAP models and NARR reanalysis.

season = 'all';
basePeriod = 'past';
testPeriod = 'future';

baseDataset = 'cmip5';
testDataset = 'cmip5';

% baseModels = {'gfdl-cm3'};
% testModels = {'gfdl-cm3'};
baseModels = {'bnu-esm', 'canesm2', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', 'mri-cgcm3', 'noresm1-m'};
testModels = {'bnu-esm', 'canesm2', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', 'mri-cgcm3', 'noresm1-m'};
      
baseVar = 'bt';
testVar = 'bt';

region = 'usne';

baseRegrid = true;
modelRegrid = true;

basePeriodYears = 1985:2004;
testPeriodYears = 2021:2050;

% compare the annual mean temperatures or the mean extreme temperatures
annualmean = false;
exportformat = 'pdf';

blockWater = true;

baseDir = 'e:/data/';
yearStep = 1;

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

plotRange = [2020 2055];
plotXUnits = 'Year';

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

if ~strcmp(testVar, '')
    testDatasetStr = testDataset;
    if strcmp(testDatasetStr, 'cmip5')
        if length(testModels) == 1
            testDatasetStr = ['cmip5-' baseModels{1}];
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

baseExt = {};
futureExt = {};
percentiles = [];

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

        baseDaily = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp baseVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        
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

            testDaily = loadDailyData([baseDir testDataDir '/' curModel ensemble testRcp testVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);

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
baseAvg = [];

% average over models and years
for m = 1:length(baseExt)
    for y = 1:length(baseExt{m})
        baseAvg(:,:,m, y) = baseExt{m}{y}{3};
    end
    baseAvg = nanmean(baseAvg, 4);
end

plotRange = [2020 2045];

probabilityThreshold = true;

tempThreshold = -11;       % bark temp
%tempThreshold = -16;        % air temp
    
if probabilityThreshold
    cutoff = [70 80 90 100];
    futureWindow = 10;
else
    cutoff = [-6 -7 -8 -10 -1] - 4;
end

for t = cutoff
    lastYear = zeros(size(futureExt{m}{y}{3}, 1), size(futureExt{m}{y}{3}, 2), length(futureExt));
    
    if probabilityThreshold
        for m = 1:length(futureExt)
            for y = 1:length(futureExt{m})-futureWindow
                
                % number of times in futureWindow that cold threshold is
                % surpassed
                eventCount = zeros(size(futureExt{m}{y}{3}, 1), size(futureExt{m}{y}{3}, 2));
                
                for y2 = y:y+futureWindow-1
                    curTest(:,:) = futureExt{m}{y2}{3};
                    
                    for xlat = 1:size(curTest, 1)
                        for ylon = 1:size(curTest, 2)

                            if curTest(xlat, ylon) <= tempThreshold
                                eventCount(xlat, ylon) = eventCount(xlat, ylon) + 1;
                            end
                            
                        end
                    end
                end
                
                for xlat = 1:size(eventCount, 1)
                    for ylon = 1:size(eventCount, 2)
                        if eventCount(xlat, ylon) >= 0.01*t*futureWindow
                            lastYear(xlat, ylon, m) = testPeriodYears(1) + y;
                        elseif lastYear(xlat, ylon, m) == 0
                            lastYear(xlat, ylon, m) = testPeriodYears(1) + y;
                        end
                    end
                end
                
            end
        end
    else
        for m = 1:length(futureExt)
            for y = 1:length(futureExt{m})
                curTest(:,:) = futureExt{m}{y}{3};
                for xlat = 1:size(curTest, 1)
                    for ylon = 1:size(curTest, 2)

                        if t == -1
                            if curTest(xlat, ylon) < baseAvg(xlat, ylon, m) || lastYear(xlat, ylon, m) == 0
                                lastYear(xlat, ylon, m) = y + testPeriodYears(1);
                            end
                        else
                            if curTest(xlat, ylon) < t || lastYear(xlat, ylon, m) == 0
                                lastYear(xlat, ylon, m) = y + testPeriodYears(1);
                            end
                        end
                    end
                end
            end
        end
    end

    lastYear = nanmean(lastYear, 3);

    result = {futureExt{m}{y}{1}, futureExt{m}{y}{2}, lastYear};

    cutoffStr = '';
    if probabilityThreshold
        cutoffStr = [num2str(t) '-perc-' num2str(tempThreshold)];
        plotTitle = ['Time of emergence (' num2str(t) '% chance of ' num2str(tempThreshold) 'C)'];
    else
        if t == -1
            cutoffStr = 'mean';
            plotTitle = ['Time of emergence (' num2str(t) 'C)'];
        else
            cutoffStr = [num2str(t) 'C'];
            plotTitle = ['Time of emergence (mean TNn)'];
        end
    end

    fileTitle = ['bt-toe-' baseVar '-' cutoffStr '-' fileTimeStr '.' exportformat];

    saveData = struct('data', {result}, ...
                      'plotRegion', plotRegion, ...
                      'plotRange', plotRange, ...
                      'plotTitle', plotTitle, ...
                      'fileTitle', fileTitle, ...
                      'plotXUnits', plotXUnits, ...
                      'blockWater', blockWater);

    plotFromDataFile(saveData);
end

