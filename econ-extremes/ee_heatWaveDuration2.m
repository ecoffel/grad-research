% computes the difference in the yearly mean of maximum summertime
% temperatures between NARCCAP models and NARR reanalysis.

season = 'all';
basePeriod = 'past';
testPeriod = 'past';

baseDataset = 'ncep';
testDataset = 'ncep';

baseModels = {''};
testModels = {''};
% baseModels = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
%           'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
%           'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};
% testModels = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
%           'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
%           'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};
      

baseVar = 'wb';
testVar = '';

baseRegrid = true;
modelRegrid = true;

basePeriodYears = 1985:2004;
testPeriodYears = 2041:2060;

consecutive = true;

biasCorrect = false;

percentileCutoff = false;
percentile = 90;
hardCutoff = 27; % degrees C

% should we we compare the future temps to the base cutoff (true) or
% compare the future temps to the future percentile cutoff and subtract the
% base temps compared to the base cutoff (false)
compToBase = true;

exportformat = 'pdf';
blockWater = true;
baseDir = 'e:/data/';
yearStep = 1;

latRange = [0 20];
lonRange = [340 40];

if strcmp(season, 'summer')
    months = [6 7 8];
elseif strcmp(season, 'winter')
    months = [12 1 2];
elseif strcmp(season, 'all')
    months = 1:12;
end

plotRegion = 'west africa';

if strcmp(baseVar, 'tasmax') | strcmp(baseVar, 'tasmin') | strcmp(baseVar, 'tmax') | strcmp(baseVar, 'tmin')
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [-10 10];
    else
        if consecutive
            plotRange = [0 20];
        else
            plotRange = [0 50];
        end
    end
    plotXUnits = 'number of days';
elseif strcmp(baseVar, 'hi')
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [-10 10];
    else
        if consecutive
            plotRange = [0 20];
        else
            plotRange = [0 50];
        end
    end
    plotXUnits = 'number of days';
elseif strcmp(baseVar, 'wb')
    if strcmp(basePeriod, 'past') & strcmp(testPeriod, 'future')
        plotRange = [-10 10];
    else
        if consecutive
            plotRange = [0 20];
        else
            plotRange = [0 50];
        end
    end
    plotXUnits = 'number of days';
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

if ~strcmp(testVar, '')
    testDatasetStr = testDataset;
    if strcmp(testDatasetStr, 'cmip5')
        if length(testModels) == 1
            testDatasetStr = ['cmip5-' testModels{1}];
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
    fileTimeStr = [testDataset '-'  num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '-' baseDataset '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
else
    fileTimeStr = [baseDataset '-' num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
end

biasCorrectStr = '';
if biasCorrect
    biasCorrectStr = 'bias-cor-';
end

consecStr = '';
if consecutive
    consecStr = 'consec-';
end

threshStr = '';
if percentileCutoff
    threshStr = [num2str(percentile) '-'];
else
    threshStr = [num2str(hardCutoff) 'C-'];
end

plotTitle = [testDataset ' [' num2str(testPeriod(1)) '-' num2str(testPeriod(end)) '] yearly ' season ' - ' baseDataset ' [' num2str(basePeriod(1)) '-' num2str(basePeriod(end)) ']'];
fileTitle = ['heatWaveDuration-' baseVar '-' consecStr biasCorrectStr threshStr '-' fileTimeStr '.' exportformat];

baseExt = {};
futureExt = {};

lat = [];
lon = [];
baseTempData = {};
testTempData = {};

if biasCorrect
    load cmip5BiasCorrection;
end

for m = 1:length(baseModels)
    if strcmp(baseModels{m}, '')
        curModel = baseModels{m};
    else
        curModel = [baseModels{m} '/'];
    end

    baseTempData{m} = [];
        
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
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(baseDaily, latRange, lonRange);
        
        if length(lat) == 0
            lat = baseDaily{1}(latIndexRange, lonIndexRange);
            lon = baseDaily{2}(latIndexRange, lonIndexRange);
        end
        
        curData = single(baseDaily{3}(latIndexRange, lonIndexRange, :, months, :));
        clear baseDaily;
        
        dInd = 1;
        for mo = 1:size(curData, 4)
            for d = 1:size(curData, 5)
                for xp = 1:size(curData, 1)
                    for yp = 1:size(curData, 2)                
                        baseTempData{m}(xp, yp, dInd, y-basePeriod(1)+1) = curData(xp,yp,1,mo,d);
                    end
                end
                dInd = dInd+1;
            end
        end
        
        clear curData;
    end
end

if ~strcmp(testVar, '')
    for m = 1:length(testModels)
        if strcmp(testModels{m}, '')
            curModel = testModels{m};
        else
            curModel = [testModels{m} '/'];
        end
        
        testTempData{m} = [];

        ['loading ' curModel ' future']
        for y = testPeriod(1):yearStep:testPeriod(end)
            ['year ' num2str(y) '...']
            % load daily data
            if modelRegrid
                testDaily = loadDailyData([baseDir testDataDir '/' curModel ensemble testRcp testVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            else
                testDaily = loadDailyData([baseDir testDataDir '/' curModel ensemble testRcp testVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            end

            [latIndexRange, lonIndexRange] = latLonIndexRange(testDaily, latRange, lonRange);
        
            curData = single(testDaily{3}(latIndexRange, lonIndexRange, :, months, :));
            clear testDaily;

            dInd = 1;
            for mo = 1:size(curData, 4)
                for d = 1:size(curData, 5)
                    for xp = 1:size(curData, 1)
                        for yp = 1:size(curData, 2)                
                            testTempData{m}(xp, yp, dInd, y-testPeriod(1)+1) = curData(xp,yp,1,mo,d);
                        end
                    end
                    dInd = dInd+1;
                end
            end
            clear curData;
        end
    end
end

['done loading...']

if biasCorrect
    percentiles = 10:10:100;
    for m = 1:length(baseModels)
        curBiasCorrection = [];
        for i = 1:length(cmip5BiasCorrection)
            if strcmp(cmip5BiasCorrection{i}{1}, baseModels{m})
                curBiasCorrection = cmip5BiasCorrection{i}{2};
                break;
            end
        end
        
        linearData = reshape(baseTempData{m}, [size(baseTempData{m}, 1), size(baseTempData{m}, 2), size(baseTempData{m}, 3)*size(baseTempData{m}, 4)]);
        
        for xp = 1:size(baseTempData{m}, 1)
            for yp = 1:size(baseTempData{m}, 2)
                % calculate percentiles
                percentileCutoffs = [];
                for p = 1:length(percentiles)
                    percentileCutoffs(p) = prctile(squeeze(linearData(xp, yp, :)), percentiles(p));
                end
                
                for year = 1:size(baseTempData{m}, 4)
                    for d = 1:size(baseTempData{m}, 3)
                        ind = find(baseTempData{m}(xp, yp, d, year) < percentileCutoffs);
                        if length(ind) == 0
                            ind = 10;
                        else
                            ind = ind(1);
                        end
                        baseTempData{m}(xp, yp, d, year) = baseTempData{m}(xp, yp, d, year) + curBiasCorrection(xp, yp, ind);
                    end
                end
            end
        end
        clear curBiasCorrection linearData;
    end
    
    % bias correct test data?
    if ~strcmp(testVar, '')
        for m = 1:length(testModels)
            curBiasCorrection = [];
            for i = 1:length(cmip5BiasCorrection)
                if strcmp(cmip5BiasCorrection{i}{1}, testModels{m})
                    curBiasCorrection = cmip5BiasCorrection{i}{2};
                    break;
                end
            end

            linearData = reshape(testTempData{m}, [size(testTempData{m}, 1), size(testTempData{m}, 2), size(testTempData{m}, 3)*size(testTempData{m}, 4)]);
            
            for xp = 1:size(testTempData{m}, 1)
                for yp = 1:size(testTempData{m}, 2)
                    % calculate percentiles
                    percentileCutoffs = [];
                    for p = 1:length(percentiles)
                        percentileCutoffs(p) = prctile(squeeze(linearData(xp, yp, :)), percentiles(p));
                    end

                    for year = 1:size(testTempData{m}, 4)
                        for d = 1:size(testTempData{m}, 3)
                            ind = find(testTempData{m}(xp, yp, d, year) < percentileCutoffs);
                            if length(ind) == 0
                                ind = 10;
                            else
                                ind = ind(1);
                            end
                            testTempData{m}(xp, yp, d, year) = testTempData{m}(xp, yp, d, year) + curBiasCorrection(xp, yp, ind);
                        end
                    end
                end
            end
            clear curBiasCorrection;
        end
    end
end

if percentileCutoff
    baseTempCutoffs = [];
    for m = 1:length(baseModels)
        linearData = [];
        linearData = reshape(baseTempData{m}, [size(baseTempData{m}, 1), size(baseTempData{m}, 2), size(baseTempData{m}, 3)*size(baseTempData{m}, 4)]);
        for xp = 1:size(baseTempData{m}, 1)
            for yp = 1:size(baseTempData{m}, 2)
                p = prctile(squeeze(linearData(xp, yp, :)), percentile);
                baseTempCutoffs(xp, yp, m) = p;
            end
        end
    end
end

% calculate days for base temps
baseCount = zeros(size(baseTempData{m}, 1), size(baseTempData{m}, 2), size(baseTempData{1}, 4), length(baseModels));
for m = 1:length(baseModels)
    for xp = 1:size(baseTempData{m}, 1)
        for yp = 1:size(baseTempData{m}, 2)
            for year = 1:size(baseTempData{m}, 4)
                curCnt = 0;
                for d = 1:size(baseTempData{m}, 3)
                    
                    tempCutoff = -1;
                    if percentileCutoff
                        tempCutoff = baseTempCutoffs(xp,yp, m);
                    else
                        tempCutoff = hardCutoff;
                    end
                    
                    if consecutive
                        if baseTempData{m}(xp,yp,d,year) >= tempCutoff
                            curCnt = curCnt+1;
                        else
                            if curCnt > baseCount(xp, yp, year, m)
                                baseCount(xp, yp, year, m) = curCnt;
                            end
                            curCnt = 0;
                        end
                    else
                        if baseTempData{m}(xp,yp,d,year) >= tempCutoff
                            baseCount(xp, yp, year, m) = baseCount(xp, yp, year, m) + 1;
                        end
                    end
                    
                end
            end
        end
    end
end

if ~strcmp(testVar, '')
    if percentileCutoff
        testTempCutoffs = [];
        for m = 1:length(testModels)
            linearData = reshape(testTempData{m}, [size(testTempData{m}, 1), size(testTempData{m}, 2), size(testTempData{m}, 3)*size(testTempData{m}, 4)]);

            for xp = 1:size(testTempData{m}, 1)
                for yp = 1:size(testTempData{m}, 2)
                    p = prctile(squeeze(linearData(xp, yp, :)), percentile);
                    testTempCutoffs(xp, yp, m) = p;
                end
            end
        end
    end
    
    % calculate consec days for future temps
    testCount = zeros(size(testTempData, 1), size(testTempData, 2), size(testTempData, 4), length(testModels));
    for m = 1:length(testModels)
        for xp = 1:size(testTempData{m}, 1)
            for yp = 1:size(testTempData{m}, 2)
                
                if percentileCutoff
                    if compToBase
                        compTemp = baseTempCutoffs(xp, yp, m);
                    else
                        compTemp = testTempCutoffs(xp, yp, m);
                    end
                else
                    compTemp = hardCutoff;
                end
                
                for year = 1:size(testTempData{m}, 4)
                    curCnt = 0;
                    for d = 1:size(testTempData{m}, 3)
                        
                        % count number of consec days above threshold
                        if consecutive    
                            if testTempData{m}(xp, yp, d, year) >= compTemp
                                curCnt = curCnt+1;
                            else
                                if curCnt > testCount(xp, yp, year, m)
                                    testCount(xp, yp, year, m) = curCnt;
                                end
                                curCnt = 0;
                            end
                        % count number of total days above threshold
                        else
                            if testTempData{m}(xp, yp, d, year) >= compTemp
                                testCount(xp, yp, year, m) = testCount(xp, yp, year, m)+1;
                            end
                        end
                        
                    end
                end
            end
        end
    end
end

if size(baseCount, 4) > 1
    baseCount = nanmean(nanmean(baseCount, 4), 3);
else
    baseCount = nanmean(baseCount, 3);
end

if ~strcmp(testVar, '')
    if size(testCount, 4) > 1
        testCount = nanmean(nanmean(testCount, 4), 3);
    else
        testCount = nanmean(testCount, 3);
    end
    
    if compToBase
        result = {lat, lon, testCount};
    else
        result = {lat, lon, testCount-baseCount};
    end
else
    result = {lat, lon, baseCount};
end

plotTitle = ['NCEP mean days above WB 27 C [1985-2004]'];

saveData = struct('data', {result}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', plotRange, ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', plotXUnits, ...
                  'blockWater', blockWater);

plotFromDataFile(saveData);

