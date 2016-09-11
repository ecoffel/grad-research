testPeriod = 'past';

models = {'access1-0', 'access1-3', 'bnu-esm', 'bcc-csm1-1-m', ...
          'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};

% models = {'access1-0', 'access1-3', 'bnu-esm', 'bcc-csm1-1-m', ...
%           'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
%           'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
%           'ipsl-cm5b-lr', 'miroc5', 'noresm1-m'};

dataset = 'cmip5';
% models = {'access1-0', 'access1-3', 'bnu-esm'};

testVar = 'tos';
testRcp = 'historical';
baseVar = 'wb';
baseRcp = 'historical'

% whether to find the annual extreme or the top 20
annualExtreme = false;

% whether we're taking the difference of two different time periods
diff = false;

plotEachModel = false;

% the temperature reference area
region = 'west-africa';
plotRegion = 'world';
fileformat = 'png';

baseDir = 'e:/data/';
ensemble = 'r1i1p1';
modelDir = 'cmip5/output';

timePeriod = [];
if strcmp(testPeriod, 'past')
    timePeriod = 1985:2005;
elseif strcmp(testPeriod, 'future')
    timePeriod = 2060:2080;
end

baseRegrid = true;
testRegrid = true;

% should we look at anomalies
minusMean = true;
% relative to the mean of the SST on the same day as the extreme
sameDayMean = true;

sameDayStr = 'day-mean';
if ~sameDayMean
    sameDayStr = 'year-mean';
end

testVarLevel = -1;

if strcmp(region, 'us-ne')
    % right around NYC
    latBounds = [40 40];
    lonBounds = [-75 -75] + 360;
elseif strcmp(region, 'india')
    latBounds = [25 26];
    lonBounds = [82 83];   
elseif strcmp(region, 'west-africa')
    latBounds = [6 6];
    lonBounds = [-1 -1] + 360;   
elseif strcmp(region, 'china')
    latBounds = [23 23];
    lonBounds = [113 113];   
end

if strcmp(testVar, 'tos')
    gridbox = false;
    if minusMean || diff
        plotRange = [-0.5 0.5];
    else
        plotRange = [0 40];
    end
    plotXUnits = 'degrees C';
end

if annualExtreme
    tempDispStr = 'ann-max';
else
    tempDispStr = 'top-max';
end

yearStep = 1; % the number of years loaded at a time for memory  reasons

outputTestData = {};

lat = [];
lon = [];

for d = 1:length(models)
    
    tempTargetFileStr = '';
    tempTargetPlotStr = '';

    if length(models) > 2
        modelStr = 'cmip5';
    else
        modelStr = models{d};
    end

    baseGrid = {};
    yearLengths = [];
    
    SSTMeans = [];
    extremeSSTVals = [];
    
    sstData = [];
    wbData = [];
    tempIndData = [];
    
    ['loading ' models{d} '...']
    for y = timePeriod(1):yearStep:timePeriod(end)
        ['year ' num2str(y)]

        if baseRegrid
            baseStr = [baseDir modelDir '/' models{d} '/' ensemble '/' baseRcp '/' baseVar '/regrid/world'];
        else
            baseStr = [baseDir modelDir '/' models{d} '/' ensemble '/' baseRcp '/' baseVar];
        end

        if testRegrid
            testStr = [baseDir modelDir '/' models{d} '/' ensemble '/' testRcp '/' testVar '/regrid/world'];
        else
            testStr = [baseDir modelDir '/' models{d} '/' ensemble '/' testRcp '/' testVar];
        end

        dailyBase = loadDailyData(baseStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));

        if length(lat) == 0 | length(lon) == 0
            lat = dailyBase{1};
            lon = dailyBase{2};
        end

        if strcmp(baseVar, 'tos')
            dailyBase{3} = dailyBase{3} - 273.15;
        end
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(dailyBase, latBounds, lonBounds);
        
        curDailyBaseData = dailyBase{3};
        clear dailyBase;

        if testVarLevel ~= -1
            dailyTest = loadDailyData(testStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', testVarLevel);
        else
            dailyTest = loadDailyData(testStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
        end

        if strcmp(testVar, 'tos')
            dailyTest{3} = dailyTest{3} - 273.15;
        end

        curDailyTestData = dailyTest{3};
        clear dailyTest;

        curDailyBaseData = squeeze(reshape(curDailyBaseData(latIndexRange, lonIndexRange, :, :, :), ...
                                   [length(latIndexRange), ...
                                   length(lonIndexRange), ...
                                   size(curDailyBaseData, 3)*size(curDailyBaseData,4)*size(curDailyBaseData,5)]));
        curDailyTestData = reshape(curDailyTestData(:, :, :, :, :), ...
                                    [size(curDailyTestData, 1), size(curDailyTestData, 2), ...
                                     size(curDailyTestData, 3)*size(curDailyTestData,4)*size(curDailyTestData,5)]);
                         
        if annualExtreme
            % find index of once-per-year highest land temperature
            tempInd = find(curDailyBaseData == nanmax(curDailyBaseData));
            
            sstData = cat(3, sstData, curDailyTestData);
            tempIndData(end+1) = tempInd + yearLengths(d)*(y-timePeriod(1));
            wbData(end+1) = curDailyBaseData(tempInd);
            extremeSSTVals(:, :, y-timePeriod(1)+1) = curDailyTestData(:, :, tempInd);
        else
            % store wb temps as well as SSTs to find the top 20 events
            % later
            sstData = cat(3, sstData, curDailyTestData);
            wbData = cat(1, wbData, curDailyBaseData);
        end
        
        if length(yearLengths) < d
            yearLengths(d) = length(curDailyBaseData);
        end
        
        clear curDailyBaseData;
        clear curDailyTestData;
    end
    
    outputTestData{d} = [];

    if ~annualExtreme
        % find top 20 events in wb data
        wbSort = sort(wbData, 'descend');
        
        indNan = isnan(wbSort);
        wbSort(indNan) = [];
        
        for i = 1:20
            tempIndData(end+1) = find(wbData == wbSort(i));
            extremeSSTVals(:, :, i) = sstData(:, :, tempIndData(end));
        end
        
    end

    if minusMean

        SSTMeans = {};

        if sameDayMean
            for t = 1:length(tempIndData)
                % now find corresponding day mean SST for whole period
                curInd = tempIndData(t) - yearLengths(d);
                sstInds = [];
                SSTMeans{t} = [];

                meanInd = 1;
                while curInd > 0
                    %SSTMeans{t}(:, :, meanInd) = sstData(:, :, curInd);
                    sstInds(end+1) = curInd;
                    curInd = curInd - yearLengths(d);
                    %meanInd = meanInd + 1;
                end
                curInd = tempIndData(t) + yearLengths(d);
                while curInd < size(sstData, 3)
                    %SSTMeans{t}(:, :, meanInd) = sstData(:, :, curInd);
                    sstInds(end+1) = curInd;
                    curInd = curInd + yearLengths(d);
                    %meanInd = meanInd + 1;
                end

                SSTMeans{t} = nanmean(sstData(:, :, sstInds), 3);
            end

            finalSSTMean = [];
            for t = 1:length(SSTMeans)
                finalSSTMean(:, :, t) = SSTMeans{t};
            end
            finalSSTMean = nanmean(finalSSTMean, 3);
        else
            finalSSTMean = nanmean(sstData, 3);
        end

        extremeSSTVals = nanmean(extremeSSTVals, 3);
        outputTestData{d} = extremeSSTVals - finalSSTMean;
    else
        outputTestData{d} = finalSSTMean;
    end
    
    clear SSTMeans sstData extremeSSTVals finalSSTMean;
    
end

if plotEachModel
    for d = 1:length(models)
        
        plotTitle = ['SST anomalies on highest ' baseVar ' day (' region ', ' models{d} ')'];
        fileTitle = [testVar 'TempExtremes-', baseVar '-' region, '-', sameDayStr '-' tempDispStr, tempTargetFileStr, '-' models{d} '.' fileformat];
    
        result = {lat, lon, outputTestData{d}};
    
        saveData = struct('data', {result}, ...
                          'plotRegion', plotRegion, ...
                          'plotRange', plotRange, ...
                          'plotTitle', plotTitle, ...
                          'fileTitle', fileTitle, ...
                          'plotXUnits', plotXUnits, ...
                          'plotCountries', false, ...
                          'plotStates', false, ...
                          'blockWater', false);

        plotFromDataFile(saveData);
    end
else
    
    plotTitle = ['SST anomalies on highest ' baseVar ' day (' region ', CMIP5 mean)'];
    fileTitle = [testVar 'TempExtremes-', baseVar '-' region '-' sameDayStr '-' testPeriod, '-', tempDispStr, tempTargetFileStr, '-' modelStr '.' fileformat];
    
    % average over all models
    finalOutputTestData = [];
    for d = 1:length(models)
        finalOutputTestData(:,:,d) = outputTestData{d};
    end
    finalOutputTestData = nanmean(finalOutputTestData, 3);

    result = {lat, lon, finalOutputTestData};
    
    saveData = struct('data', {result}, ...
                      'plotRegion', plotRegion, ...
                      'plotRange', plotRange, ...
                      'plotTitle', plotTitle, ...
                      'fileTitle', fileTitle, ...
                      'plotXUnits', plotXUnits, ...
                      'plotCountries', false, ...
                      'plotStates', false, ...
                      'blockWater', false);
    
    plotFromDataFile(saveData);
end
    
