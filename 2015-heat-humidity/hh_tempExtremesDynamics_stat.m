season = 'all';
testPeriod = 'future';


dataset = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
          'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};
      
testVar = 'wb';
testRcp = 'rcp85';
testVarLevel = -1;

baseVar = 'hi';
baseRcp = 'historical'
baseVarLevel = -1;

% whether to find the annual extreme or use a temp percentile
annualExtreme = true;

% if using annual extreme, find the max or the min?
findMax = true;

% if not annual extreme, specify temp percentile
basePercentile = 90;

% whether we're taking the difference of two different time periods
diff = true;

% whether to subtract the period (base or future) mean to look at anomalies
anomalies = false;

% the temperature reference area
region = 'ne';
plotRegion = 'world';
fileformat = 'pdf';

% show water tiles in output map?
blockWater = true;

% whether to do statistical testing
statTest = false;
% how many standard deviations above mean to consider significant
statTestThresh = 2;
% whether to do the stat test for only base period extremes (true) or for all days (false)
statTestExt = true;
% whether to average the std. of each model and then stat test the ensemble
% mean to this average
statTestEnsemble = true;

baseDir = 'e:/';
ensemble = 'r1i1p1';
modelDir = 'cmip5/output';

basePeriod = 1980:2004;
futurePeriod = 2060:2079;

baseRegrid = true;
testRegrid = true;

if strcmp(region, 'ne')
    latRange = [39 41];
    lonRange = [280 284];
elseif strcmp(region, 'sw')
    latRange = [34.5 36.5];
    lonRange = [256 260];   
end

if strcmp(testVar, 'zg500')
    gridbox = false;
    plotRange = [-150 150];
    plotXUnits = 'm';
elseif strcmp(testVar, 'va850') | strcmp(testVar, 'ua850')
    gridbox = false;
    plotRange = [-10 10];
    plotXUnits = 'm/s';
elseif strcmp(testVar, 'huss')
    gridbox = true;
    plotRange = [-0.003 0.003];
    plotXUnits = 'kg water vapor / kg air';
elseif strcmp(testVar, 'rh')
    gridbox = true;
    if diff
        plotRange = [-5 5];
    else
        plotRange = [0 100];
    end
    plotXUnits = 'percent';
elseif strcmp(testVar, 'tasmax')
    gridbox = true;
    if diff
        plotRange = [-5 5];
    else
        plotRange = [10 50];
    end
    plotXUnits = 'degrees C';
elseif strcmp(testVar, 'wb')
    gridbox = true;
    if diff
        plotRange = [-5 5];
    else
        plotRange = [10 50];
    end
    plotXUnits = 'degrees C';
elseif strcmp(testVar, 'psl')
    gridbox = false;
	plotRange = [-100 100];
end

if ~gridbox
    boxCoords = [latRange; lonRange];
else
    boxCoords = [];
end

if strcmp(testPeriod, 'past')
    varPeriods = {basePeriod};
elseif strcmp(testPeriod, 'future')
    if diff
        varPeriods = {basePeriod, futurePeriod};
    else
        varPeriods = {futurePeriod};
    end
end

basePeriodStr = [num2str(basePeriod(1)) '-' num2str(basePeriod(end))];
testPeriodStr = [num2str(futurePeriod(1)) '-' num2str(futurePeriod(end))];

seasonStr = '';
if strcmp(season, 'summer')
    months = [6 7 8];
    seasonStr = 'jja';
elseif strcmp(season, 'winter')
    months = [12 1 2];
    seasonStr = 'djf';
elseif strcmp(season, 'all')
    months = 1:12;
    seasonStr = 'all';
end

maxMinStr = '';
if annualExtreme
    if findMax
        maxMinStr = 'ann-max';
    else
        maxMinStr = 'ann-min';
    end
else
    maxMinStr = [num2str(basePercentile) 'p'];
end

yearStep = 1; % the number of years loaded at a time for memory  reasons
minusMean = false;

% stores the test grid that will be shown on the final map
outputTestGrid = {};

% stores the mean value at each gridbox for each model - subtract this at the end to
% get anomalies
meanGrid = {};

if statTest
    outputStatData = {};
end

for d = 1:length(dataset)
    
    if strcmp(dataset{d}, 'ncep')
        vars = {'ncep-reanalysis/output'};
    elseif strcmp(dataset{d}, 'narr')
        vars = {'narr/output'};
    end
    
    baseDir = 'e:/';
    
    baseTargetFileStr = '';
    baseTargetPlotStr = '';

    if strcmp(dataset{d}, 'ncep')
        
        fileTitle = [testVar 'TempExtremes-' baseVar '-' maxMinStr '-ncep-' basePeriodStr '-' seasonStr '.' fileformat];
        
    elseif strcmp(dataset{d}, 'narr')
    
        fileTitle = [testVar 'TempExtremes-' baseVar '-' maxMinStr '-narr-' basePeriodStr '-' seasonStr '.' fileformat];
        
    else
        if length(dataset) > 2
            modelStr = 'cmip5';
        else
            modelStr = dataset{d};
        end
        
        if diff
            vars = {['cmip5/output/' dataset{d} '/' ensemble '/' baseRcp], ['cmip5/output/' dataset{d} '/' ensemble '/' testRcp]};
            fileTitle = [testVar 'TempExtremes-' baseVar '-' maxMinStr '-' modelStr '-' testPeriodStr, '-minus-' basePeriodStr '-' seasonStr '.' fileformat];
        else
            vars = {['cmip5/output/' dataset{d} '/' ensemble '/' baseRcp]};
            fileTitle = [testVar 'TempExtremes-' baseVar '-' maxMinStr '-' modelStr '-' basePeriodStr '-' seasonStr '.' fileformat];
        end 
    end
    
    lat = [];
    lon = [];

    % saved temp and test grid for each threshold exceeding day per year /
    % variable
    testGrid = {};
    testStatGrid = {};
    
    meanGrid{d} = {};
    
    for v = 1:length(vars)
        testGrid{v} = [];
        meanGrid{d}{v} = [];
        
        testStatGrid{v} = {};

        yearIndex = 1;
        
        ['loading ' vars{v} '...']
        for y = varPeriods{v}(1):yearStep:varPeriods{v}(end)
            ['year ' num2str(y)]

            if baseRegrid
                baseStr = [baseDir 'data/' vars{v} '/' baseVar '/regrid'];
            else
                baseStr = [baseDir 'data/' vars{v} '/' baseVar];
            end

            if testRegrid
                testVarStr = [baseDir 'data/' vars{v} '/' testVar '/regrid'];
            else
                testVarStr = [baseDir 'data/' vars{v} '/' testVar];
            end

            dailyBase = loadDailyData(baseStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));

            if length(lat) == 0 | length(lon) == 0
                lat = dailyBase{1};
                lon = dailyBase{2};
            end

            if length(dailyBase{1}) == 0
                continue;
            end
            
            if ~gridbox
                [latIndexRange, lonIndexRange] = latLonIndexRange(dailyBase, latRange, lonRange);
            end

            curDailyBaseData = dailyBase{3};
            clear dailyBase;

            if testVarLevel ~= -1
                dailyTest = loadDailyData(testVarStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', testVarLevel);
            else
                if strcmp(testVar, 'zg500')
                    dailyTest = loadDailyData(testVarStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'mult', 8, 'multMethod', 'mean');
                else
                    dailyTest = loadDailyData(testVarStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
                end
            end
            
            if length(dailyTest{1}) == 0
                continue;
            end
            
            curDailyTestData = dailyTest{3};
            clear dailyTest;

            curDailyBaseData = single(curDailyBaseData(:,:,:,months,:));
            curDailyTestData = single(curDailyTestData(:,:,:,months,:));

            if ~gridbox
                curDailyBaseData = reshape(curDailyBaseData(latIndexRange, lonIndexRange, :, :, :), ...
                                           [length(latIndexRange), ...
                                           length(lonIndexRange), ...
                                           size(curDailyBaseData, 3)*size(curDailyBaseData,4)*size(curDailyBaseData,5)]);
                curDailyTestData = reshape(curDailyTestData(:, :, :, :, :), ...
                                            [size(curDailyTestData, 1), size(curDailyTestData, 2), ...
                                             size(curDailyTestData, 3)*size(curDailyTestData,4)*size(curDailyTestData,5)]);
            else
                curDailyBaseData = reshape(curDailyBaseData, ...
                                       [size(curDailyBaseData, 1), size(curDailyBaseData, 2), ...
                                       size(curDailyBaseData, 3)*size(curDailyBaseData,4)*size(curDailyBaseData,5)]);
                curDailyTestData = reshape(curDailyTestData, ...
                                        [size(curDailyTestData, 1), size(curDailyTestData, 2), ...
                                         size(curDailyTestData, 3)*size(curDailyTestData,4)*size(curDailyTestData,5)]);
            end

            % make sure base and test are same length
            % these contain the data for the current year
            curDailyTestData = curDailyTestData(:,:,1:min(size(curDailyTestData, 3), size(curDailyBaseData, 3)));
            curDailyBaseData = curDailyBaseData(:,:,1:min(size(curDailyTestData, 3), size(curDailyBaseData, 3)));
            
            % if we need to calculate the mean test var at each gridbox for
            % anomalies...
            if anomalies
                % first calculate the mean at each gridbox for the current
                % year
                tmpMean = nanmean(curDailyTestData, 3);
                
                % then calculate the mean between the current year and the
                % existing years
                if length(meanGrid{d}{v}) == 0
                    meanGrid{d}{v} = tmpMean;
                else
                    for xlat = 1:size(curDailyTestData, 1)
                        for ylon = 1:size(curDailyTestData, 2)
                            meanGrid{d}{v}(xlat, ylon) = nanmean([meanGrid{d}{v}(xlat, ylon), tmpMean(xlat, ylon)]);
                        end
                    end
                end
                
                clear tmpMean;
            end
            
            if gridbox
                % loop over each gridbox
                for xlat = 1:size(curDailyBaseData, 1)
                    if size(testStatGrid{v}, 1) < xlat
                        testStatGrid{v}{xlat} = {};
                    end
                    for ylon = 1:size(curDailyBaseData, 2)
                        if size(testStatGrid{v}{xlat}, 2) < ylon
                            testStatGrid{v}{xlat}{ylon} = [];
                        end
                        % find the days on which to save the testGrid -
                        % either on the max/min days of above/below a
                        % certain threshold
                        if annualExtreme
                            if findMax
                                baseInd = find(curDailyBaseData(xlat, ylon, :) == nanmax(curDailyBaseData(xlat, ylon, :)));
                            else
                                baseInd = find(curDailyBaseData(xlat, ylon, :) == nanmin(curDailyBaseData(xlat, ylon, :)));
                            end
                            
                            if length(baseInd) > 1
                                baseInd = baseInd(1);
                            end
                        else
                            gridboxBaseAvgCutoff = prctile(curDailyBaseData(xlat, ylon, :), basePercentile);
                            if summer
                                baseInd = find(curDailyBaseData(xlat, ylon, :) >= gridboxBaseAvgCutoff);
                            else
                                baseInd = find(curDailyBaseData(xlat, ylon, :) <= gridboxBaseAvgCutoff);
                            end
                        end
                        
                        notBaseInd = 1:size(curDailyBaseData(xlat, ylon, :), 3);
                        notBaseInd(baseInd) = [];
                        
                        if length(baseInd) == 0
                            testGrid{v}(xlat,ylon,:,yearIndex) = NaN;
                            continue;
                        end
                        
                        % save the test grid for the threshold exceeding days
                        testGrid{v}(xlat,ylon,:,yearIndex) = curDailyTestData(xlat,ylon,baseInd);
                        
                        if statTest
                            % if we are testaring to only std. of extreme days
                            if statTestExt
                                testStatGrid{v}{xlat}{ylon} = [squeeze(testStatGrid{v}{xlat}{ylon}); squeeze(curDailyTestData(xlat,ylon,baseInd))];

                            % or std. of all days
                            else
                                testStatGrid{v}{xlat}{ylon} = [squeeze(testStatGrid{v}{xlat}{ylon}); squeeze(curDailyTestData(xlat,ylon,:))];
                            end
                        end
                        
                    end
                end
            else
                % find days with maximum/minimum average base in the target
                % region and save the testVar grid on those days
                
                % average daily temperature over the target region 
                dailyBaseAvg = squeeze(nanmean(nanmean(curDailyBaseData, 2), 1));
                
                % find the days for which we want to save the testVar grid
                % - either the max/min days per year or exceeding a certain
                % threshold
                if annualExtreme
                    if findMax
                        baseInd = find(dailyBaseAvg == max(dailyBaseAvg));
                    else
                        baseInd = find(dailyBaseAvg == min(dailyBaseAvg));
                    end
                    
                    if length(baseInd) > 1
                        baseInd = baseInd(1);
                    end
                else
                    dailyBaseAvgCutoff = prctile(dailyBaseAvg, basePercentile);
                    if summer
                        baseInd = find(dailyBaseAvg >= dailyBaseAvgCutoff);
                    else
                        baseInd = find(dailyBaseAvg <= dailyBaseAvgCutoff);
                    end
                end

                % these are the idices of days that do not meet the
                % threshold - so we don't save the testVar grid here
                notBaseInd = 1:length(dailyBaseAvg);
                notBaseInd(baseInd) = [];
                
                % save the test grid for the threshold exceeding days
                testGrid{v}(:,:,:,yearIndex) = curDailyTestData(:,:,baseInd);
                
                if statTest
                    for xlat = 1:size(curDailyTestData, 1)
                        if size(testStatGrid{v}, 1) < xlat
                            testStatGrid{v}{xlat} = {};
                        end
                        
                        for ylon = 1:size(curDailyTestData, 2)
                            if size(testStatGrid{v}{xlat}, 2) < ylon
                                testStatGrid{v}{xlat}{ylon} = [];
                            end
                            
                            % if we are testaring to only std. of extreme days
                            if statTestExt
                                testStatGrid{v}{xlat}{ylon} = [squeeze(testStatGrid{v}{xlat}{ylon}); squeeze(curDailyTestData(xlat,ylon,baseInd))];

                            % or std. of all days
                            else
                                testStatGrid{v}{xlat}{ylon} = [squeeze(testStatGrid{v}{xlat}{ylon}); squeeze(curDailyTestData(xlat,ylon,:))];
                            end
                        end
                    end
                end
            end
            
            %dailyBaseData{v} = cat(3, dailyBaseData{v}, curDailyBaseData);
            clear curDailyBaseData;
            %dailyTestData{v} = cat(3, dailyTestData{v}, curDailyTestData);
            clear curDailyTestData;
            
            yearIndex = yearIndex+1;
        end
    end

    outputTestGrid{d} = [];

    % for each time period in the current dataset, average the test grid over years and
    % selected days
    for v = 1:length(vars)
        testGrid{v} = nanmean(nanmean(testGrid{v}, 4), 3);
        
        % if we need to subtract the mean...
        if anomalies
            testGrid{v} = testGrid{v} - meanGrid{d}{v};
        end
    end
    
    % if taking difference between 2 time periods, subtract the first
    % period from the second
    if diff
        outputTestGrid{d} = testGrid{2} - testGrid{1};
        
    % otherwise just save the base period test grid
    else
        outputTestGrid{d} = testGrid{1};
    end
    
    if statTest        
        testStdDev{d} = {};
        % calculate the std. of the test variable at each gridbox for each time period over each year
        for v = 1:length(vars)
            testStdDev{d}{v} = [];
            for xlat = 1:length(testStatGrid{v})
                for ylon = 1:length(testStatGrid{v}{xlat})
                    testStdDev{d}{v}(xlat, ylon) = nanstd(squeeze(testStatGrid{v}{xlat}{ylon}-meanGrid{d}{v}(xlat, ylon)));
                end
            end
        end
        clear testStatGrid;
        
    end
    
    clear testGrid;
end



% average over all models
finalOutputTestData = [];
for d = 1:length(dataset)
    finalOutputTestData(:,:,d) = outputTestGrid{d};
end
finalOutputTestData = nanmean(finalOutputTestData, 3);
finalOutputStatData = [];

if statTest
    % calculate the mean of the std. dev. for each model
    stdDevMean = [];

    for d = 1:length(testStdDev)
        for xlat = 1:size(testStdDev{d}{1}, 1)
            for ylon = 1:size(testStdDev{d}{1}, 2)
                % squre to get the variance (so we can sum & average)
                stdDevMean(xlat, ylon, d) = testStdDev{d}{1}(xlat, ylon)*testStdDev{d}{1}(xlat, ylon);
            end
        end
    end

    stdDevMean = squeeze(nansum(stdDevMean(:, :, d), 3));
    stdDevMean = sqrt(stdDevMean(:, :) ./ length(testStdDev));
    
    % test if the multi-model mean is significant with respect to the mean
    % std. dev.
    for xlat = 1:size(finalOutputTestData, 1)
        for ylon = 1:size(finalOutputTestData, 2)
            if abs(finalOutputTestData(xlat, ylon)) > statTestThresh*stdDevMean(xlat, ylon) & stdDevMean(xlat, ylon) ~= 0
                finalOutputStatData(xlat, ylon) = 1;
            else
                finalOutputStatData(xlat, ylon) = 0;
            end
        end
    end
end

plotTitle='CMIP5 HI TXx anomaly change';

result = {lat, lon, double(finalOutputTestData)};

saveData = struct('data', {result}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', plotRange, ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', plotXUnits, ...
                  'blockWater', blockWater);

plotFromDataFile(saveData);

    
















