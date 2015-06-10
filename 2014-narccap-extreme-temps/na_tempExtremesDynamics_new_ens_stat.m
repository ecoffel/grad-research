
dataset = {'narr'};
% dataset = {'crcm/ccsm', 'crcm/cgcm3'};
% dataset = {'crcm/ccsm', 'crcm/cgcm3', 'ecp2/gfdl', ...
%           'hrm3/gfdl', 'hrm3/hadcm3', 'mm5i/ccsm', ...
%           'mm5i/hadcm3', 'rcm3/cgcm3', 'rcm3/gfdl', ...
%           'wrfg/ccsm', 'wrfg/cgcm3'};

% for mrso
%dataset = {'crcm/ccsm', 'crcm/cgcm3', 'ecp2/gfdl', 'hrm3/gfdl'};
% dataset = {'crcm/ccsm', 'crcm/cgcm3', 'ecp2/gfdl', ...
%           'hrm3/gfdl', 'mm5i/ccsm', ...
%           'mm5i/hadcm3', 'rcm3/cgcm3', ...
%           'wrfg/ccsm', 'wrfg/cgcm3'};

% for swe
% dataset = {'crcm/ccsm', 'crcm/cgcm3', 'ecp2/gfdl', ...
%           'rcm3/cgcm3', 'rcm3/gfdl', ...
%           'wrfg/ccsm'};

%dataset={'crcm/cgcm3'};

compVar = 'zg500';

summer = false;

testPeriod = 'past';

% whether to find the annual extreme or use a temp percentile
annualExtreme = true;

% if using annual extreme, find the max or the min?
findMax = false;
% if not annual extreme, specify temp percentile
tempPercentile = 25;

% whether we're taking the difference of two different time periods
diff = false;

blockWater = false;

% whether to subtract the period (base or future) mean to look at anomalies
anomalies = false;

% the temperature reference area
region = 'ne';
plotRegion = 'usa-exp';
fileformat = 'pdf';

% show the absolute anomaly in units (true) or a multiple of the std.
% (false)
realAnom = true;

% using a single narccap model and don't want to use regridded data
forceNoRegrid = false;

% whether to do statistical testing
statTest = false;
% how many standard deviations above mean to consider significant
statTestThresh = 2;
% whether to do the stat test for only base period extremes (true) or for all days (false)
statTestExt = true;
% whether to average the std. of each model and then stat test the ensemble
% mean to this average
statTestEnsemble = true;

plotColorMap = [];

tempStdDev = {};
compStdDev = {};

tempDispStr = '';
if annualExtreme
    if findMax
        tempDispStr = 'ann-max';
    else
        tempDispStr = 'ann-min';
    end
else
    tempDispStr = [num2str(tempPercentile) 'p'];
end

% cannot use diff except on narccap-gcm and for the future
if diff & (strcmp(dataset, 'narccap-ncep') | strcmp(dataset, 'ncep') | strcmp(dataset, 'narr') | ~strcmp(testPeriod, 'future'))
    diff = false;
    ['diff is false']
    return;
end

if strcmp(compVar, 'zg500')
    gridbox = false;
    if anomalies
        plotRange = [-150 150];
    else
        plotRange = [5000 6500];
    end
    plotXUnits = 'm';
elseif strcmp(compVar, 'tasmax') | strcmp(compVar, 'tasmin')
    gridbox = false;
    plotRange = [-20 20];
    plotXUnits = 'degrees C';
elseif strcmp(compVar, 'mrso')
    gridbox = true;
    plotColorMap = ceprecip;
    if realAnom
        plotRange = [-200 200];
        plotXUnits = 'kg / m^2';
    else
        plotRange = [-4 4];
        plotXUnits = 'std. deviations';
    end
    
elseif strcmp(compVar, 'swe')
    gridbox = true;
    if diff
        plotRange = [-0.01 0.01];
    else
        plotRange = [0 0.5];
    end
    plotXUnits = 'm';
elseif strcmp(compVar, 'va850') | strcmp(compVar, 'ua850')
    gridbox = false;
    plotRange = [-10 10];
    plotXUnits = 'm/s';
elseif strcmp(compVar, 'hus')
    gridbox = false;
    plotRange = [0 0.005];
    plotXUnits = 'kg water vapor / kg dry air';
end

if strcmp(region, 'ne')
    tempLatRange = [39 41];
    tempLonRange = [280 284];
    
    if ~gridbox
        boxCoords = [tempLatRange; tempLonRange];
    else
        boxCoords = [];
    end
elseif strcmp(region, 'sw')
    tempLatRange = [34 36];
    tempLonRange = [248 252];
    
    if ~gridbox
        boxCoords = [tempLatRange; tempLonRange];
    else
        boxCoords = [];
    end
end

basePeriod = 1981:1998;
futurePeriod = 2051:2069;

% basePeriod = 1981:1983;
% futurePeriod = 2051:2053;

if strcmp(testPeriod, 'past')
    varPeriods = {basePeriod};
elseif strcmp(testPeriod, 'future')
    if diff
        varPeriods = {basePeriod, futurePeriod};
    else
        varPeriods = {futurePeriod};
    end
end

seasonStr = '';
if summer
    months = [6 7 8];
    seasonStr = 'jja';
    if tempPercentile == -1
        tempPercentile = 99;
    end
else
    months = [12 1 2];
    seasonStr = 'djf';
    if tempPercentile == -1
        tempPercentile = 1;
    end
end

yearStep = 1; % the number of years loaded at a time for memory  reasons

% stores the comp grid that will be shown on the final map
outputCompGrid = {};

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
    else
        if diff
            vars = {['narccap/output/' dataset{d}], ['narccap/output/' dataset{d}]};
        else
            vars = {['narccap/output/' dataset{d}]};
        end    
    end
    
    baseDir = 'e:/';
    if length(findstr(vars{1}, 'narccap')) ~= 0
        if summer
            tempVar = 'tasmax';
        else
            tempVar = 'tasmin';
        end
        tempPlev = -1;

        if strcmp(compVar, 'zg500')
            compVarName = 'zg500';
            compVarLevel = -1;
        elseif strcmp(compVar, 'mrso')
            compVarName = 'mrso';
            compVarLevel = -1;
        elseif strcmp(compVar, 'swe')
            compVarName = 'swe';
            compVarLevel = -1;
        else
            compVarName = compVar;
            compVarLevel = -1;
        end
        
        if forceNoRegrid
            isCompVarRegridded = false;
            isTempRegridded = false;
        else
            isTempRegridded = true;
            isCompVarRegridded = true;
        end
        
    elseif length(findstr(vars{1}, 'narr')) ~= 0
        if summer
            tempVar = 'tasmax';
        else
            tempVar = 'tasmin';
        end
        tempPlev = -1;

        if strcmp(compVar, 'zg500')
            compVarName = 'hgt';
            compVarLevel = 2;
        elseif strcmp(compVar, 'mrso')
            compVarName = 'soilm';
            compVarLevel = -1;
        elseif strcmp(compVar, 'swe')
            compVarName = 'snod';
            compVarLevel = -1;
        end

        isTempRegridded = false;
        isCompVarRegridded = false;
    elseif length(findstr(vars{1}, 'ncep')) ~= 0
        if summer
            tempVar = 'tmax';
        else
            tempVar = 'tmin';
        end
        tempPlev = -1;

        if strcmp(compVar, 'zg500')
            compVarName = 'hgt';
            compVarLevel = -1;
            isCompVarRegridded = true;
        elseif strcmp(compVar, 'mrso')
            compVarName = 'soilw';
            compVarLevel = -1;
            isCompVarRegridded = false;
        elseif strcmp(compVar, 'swe')
            compVarName = '';
            compVarLevel = -1;
            isCompVarRegridded = false;
        end

        isTempRegridded = false;
    end
    
    tempTargetFileStr = '';
    tempTargetPlotStr = '';
    if strcmp(compVar, 'zg500')
        tempTargetFileStr = ['-' num2str(round(mean(tempLatRange))) 'n-' num2str(round(mean(tempLonRange))) 'e'];
        tempTargetPlotStr = ['[' num2str(tempLatRange(1)) '-' num2str(tempLatRange(2)) ' N], [' num2str(tempLonRange(1)) '-' num2str(tempLonRange(2)) ' E], '];
    end

    if strcmp(dataset{d}, 'ncep')
        if diff
            plotTitle = ['NCEP ' compVar ' diff at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{2}(1)), '-', num2str(varPeriods{2}(end)), '] - [', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)), ']'];
            fileTitle = [compVar 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-diff-ncep.' fileformat];
        else
            plotTitle = ['NCEP ' compVar ' at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
            fileTitle = [compVar 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-ncep.' fileformat];
        end
    elseif strcmp(dataset{d}, 'narr')
        if diff
            plotTitle = ['NARR ' compVarName ' diff at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{2}(1)), '-', num2str(varPeriods{2}(end)), '] - [', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)), ']'];
            fileTitle = [compVarName 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-diff-narr.' fileformat];
        else
            plotTitle = ['NARR ' compVarName ' at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
            fileTitle = [compVarName 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-narr.' fileformat];
        end
    else
        modelStr = '';
        if length(dataset) > 1
            modelStr = 'narccap-mm';
        else
            parts = strsplit(dataset{d}, '/');
            modelStr = [parts{1} '-' parts{2}];
        end
        
        if diff
            plotTitle = ['NARCCAP ' modelStr ' ' compVar ' diff at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{2}(1)), '-', num2str(varPeriods{2}(end)), '] - [', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)), ']'];
            fileTitle = [compVar 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-diff-narccap-' modelStr '.' fileformat];
        else
            plotTitle = ['NARCCAP ' modelStr ' ' compVar ' at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
            fileTitle = [compVar 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-narccap-' modelStr '.' fileformat];
        end    
    end
    
    lat = [];
    lon = [];

    % saved temp and comp grid for each threshold exceeding day per year /
    % variable
    compGrid = {};
    compStatGrid = {};
    
    meanGrid{d} = {};
    
    for v = 1:length(vars)
        compGrid{v} = [];
        meanGrid{d}{v} = [];
        
        compStatGrid{v} = {};

        yearIndex = 1;
        
        ['loading ' vars{v} '...']
        for y = varPeriods{v}(1):yearStep:varPeriods{v}(end)
            ['year ' num2str(y)]

            if isTempRegridded
                tempStr = [baseDir 'data/' vars{v} '/' tempVar '/regrid'];
            else
                tempStr = [baseDir 'data/' vars{v} '/' tempVar];
            end

            if isCompVarRegridded
                compVarStr = [baseDir 'data/' vars{v} '/' compVarName '/regrid'];
            else
                compVarStr = [baseDir 'data/' vars{v} '/' compVarName];
            end

            dailyTemp = loadDailyData(tempStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));

            if length(lat) == 0 | length(lon) == 0
                lat = dailyTemp{1};
                lon = dailyTemp{2};
            end

            if length(dailyTemp{1}) == 0
                continue;
            end
            
            if ~gridbox
                [latIndexRange, lonIndexRange] = latLonIndexRange(dailyTemp, tempLatRange, tempLonRange);
            end

            curDailyTempData = dailyTemp{3};
            clear dailyTemp;

            if compVarLevel ~= -1
                dailyComp = loadDailyData(compVarStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', compVarLevel);
            else
                if strcmp(compVar, 'zg500')
                    dailyComp = loadDailyData(compVarStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'mult', 8, 'multMethod', 'mean');
                else
                    dailyComp = loadDailyData(compVarStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
                end
            end
            
            if length(dailyComp{1}) == 0
                continue;
            end
            
            curDailyCompData = dailyComp{3};
            clear dailyComp;

            curDailyTempData = single(curDailyTempData(:,:,:,months,:));
            curDailyCompData = single(curDailyCompData(:,:,:,months,:));

            if ~gridbox
                curDailyTempData = reshape(curDailyTempData(latIndexRange, lonIndexRange, :, :, :), ...
                                           [length(latIndexRange), ...
                                           length(lonIndexRange), ...
                                           size(curDailyTempData, 3)*size(curDailyTempData,4)*size(curDailyTempData,5)]);
                curDailyCompData = reshape(curDailyCompData(:, :, :, :, :), ...
                                            [size(curDailyCompData, 1), size(curDailyCompData, 2), ...
                                             size(curDailyCompData, 3)*size(curDailyCompData,4)*size(curDailyCompData,5)]);
            else
                curDailyTempData = reshape(curDailyTempData, ...
                                       [size(curDailyTempData, 1), size(curDailyTempData, 2), ...
                                       size(curDailyTempData, 3)*size(curDailyTempData,4)*size(curDailyTempData,5)]);
                curDailyCompData = reshape(curDailyCompData, ...
                                        [size(curDailyCompData, 1), size(curDailyCompData, 2), ...
                                         size(curDailyCompData, 3)*size(curDailyCompData,4)*size(curDailyCompData,5)]);
            end

            % make sure temp and comp are same length
            % these contain the data for the current year
            curDailyCompData = curDailyCompData(:,:,1:min(size(curDailyCompData, 3), size(curDailyTempData, 3)));
            curDailyTempData = curDailyTempData(:,:,1:min(size(curDailyCompData, 3), size(curDailyTempData, 3)));
            
            % if we need to calculate the mean comp var at each gridbox for
            % anomalies...
            if anomalies
                % first calculate the mean at each gridbox for the current
                % year
                tmpMean = nanmean(curDailyCompData, 3);
                
                % then calculate the mean between the current year and the
                % existing years
                if length(meanGrid{d}{v}) == 0
                    meanGrid{d}{v} = tmpMean;
                else
                    for xlat = 1:size(curDailyCompData, 1)
                        for ylon = 1:size(curDailyCompData, 2)
                            meanGrid{d}{v}(xlat, ylon) = nanmean([meanGrid{d}{v}(xlat, ylon), tmpMean(xlat, ylon)]);
                        end
                    end
                end
                
                clear tmpMean;
            end
            
            if gridbox
                % loop over each gridbox
                for xlat = 1:size(curDailyTempData, 1)
                    if size(compStatGrid{v}, 1) < xlat
                        compStatGrid{v}{xlat} = {};
                    end
                    for ylon = 1:size(curDailyTempData, 2)
                        if size(compStatGrid{v}{xlat}, 2) < ylon
                            compStatGrid{v}{xlat}{ylon} = [];
                        end
                        % find the days on which to save the compGrid -
                        % either on the max/min days of above/below a
                        % certain threshold
                        if annualExtreme
                            if findMax
                                tempInd = find(curDailyTempData(xlat, ylon, :) == nanmax(curDailyTempData(xlat, ylon, :)));
                            else
                                tempInd = find(curDailyTempData(xlat, ylon, :) == nanmin(curDailyTempData(xlat, ylon, :)));
                            end
                            
                            if length(tempInd) > 1
                                tempInd = tempInd(1);
                            end
                        else
                            gridboxTempAvgCutoff = prctile(curDailyTempData(xlat, ylon, :), tempPercentile);
                            if summer
                                tempInd = find(curDailyTempData(xlat, ylon, :) >= gridboxTempAvgCutoff);
                            else
                                tempInd = find(curDailyTempData(xlat, ylon, :) <= gridboxTempAvgCutoff);
                            end
                        end
                        
                        notTempInd = 1:size(curDailyTempData(xlat, ylon, :), 3);
                        notTempInd(tempInd) = [];
                        
                        if length(tempInd) == 0
                            compGrid{v}(xlat,ylon,:,yearIndex) = NaN;
                            continue;
                        end
                        
                        % save the comp grid for the threshold exceeding days
                        compGrid{v}(xlat,ylon,:,yearIndex) = curDailyCompData(xlat,ylon,tempInd);
                        
                        if statTest
                            % if we are comparing to only std. of extreme days
                            if statTestExt
                                compStatGrid{v}{xlat}{ylon} = [squeeze(compStatGrid{v}{xlat}{ylon}); squeeze(curDailyCompData(xlat,ylon,tempInd))];

                            % or std. of all days
                            else
                                compStatGrid{v}{xlat}{ylon} = [squeeze(compStatGrid{v}{xlat}{ylon}); squeeze(curDailyCompData(xlat,ylon,:))];
                            end
                        end
                        
                    end
                end
            else
                % find days with maximum/minimum average temp in the target
                % region and save the compVar grid on those days
                
                % average daily temperature over the target region 
                dailyTempAvg = squeeze(nanmean(nanmean(curDailyTempData, 2), 1));
                
                % find the days for which we want to save the compVar grid
                % - either the max/min days per year or exceeding a certain
                % threshold
                if annualExtreme
                    if findMax
                        tempInd = find(dailyTempAvg == max(dailyTempAvg));
                    else
                        tempInd = find(dailyTempAvg == min(dailyTempAvg));
                    end
                    
                    if length(tempInd) > 1
                        tempInd = tempInd(1);
                    end
                else
                    dailyTempAvgCutoff = prctile(dailyTempAvg, tempPercentile);
                    if summer
                        tempInd = find(dailyTempAvg >= dailyTempAvgCutoff);
                    else
                        tempInd = find(dailyTempAvg <= dailyTempAvgCutoff);
                    end
                end

                % these are the idices of days that do not meet the
                % threshold - so we don't save the compVar grid here
                notTempInd = 1:length(dailyTempAvg);
                notTempInd(tempInd) = [];
                
                % save the comp grid for the threshold exceeding days
                compGrid{v}(:,:,:,yearIndex) = curDailyCompData(:,:,tempInd);
                
                if statTest
                    for xlat = 1:size(curDailyCompData, 1)
                        if size(compStatGrid{v}, 1) < xlat
                            compStatGrid{v}{xlat} = {};
                        end
                        
                        for ylon = 1:size(curDailyCompData, 2)
                            if size(compStatGrid{v}{xlat}, 2) < ylon
                                compStatGrid{v}{xlat}{ylon} = [];
                            end
                            
                            % if we are comparing to only std. of extreme days
                            if statTestExt
                                compStatGrid{v}{xlat}{ylon} = [squeeze(compStatGrid{v}{xlat}{ylon}); squeeze(curDailyCompData(xlat,ylon,tempInd))];

                            % or std. of all days
                            else
                                compStatGrid{v}{xlat}{ylon} = [squeeze(compStatGrid{v}{xlat}{ylon}); squeeze(curDailyCompData(xlat,ylon,:))];
                            end
                        end
                    end
                end
            end
            
            %dailyTempData{v} = cat(3, dailyTempData{v}, curDailyTempData);
            clear curDailyTempData;
            %dailyCompData{v} = cat(3, dailyCompData{v}, curDailyCompData);
            clear curDailyCompData;
            
            yearIndex = yearIndex+1;
        end
    end

    outputCompGrid{d} = [];

    % for each time period in the current dataset, average the comp grid over years and
    % selected days
    for v = 1:length(vars)
        compGrid{v} = nanmean(nanmean(compGrid{v}, 4), 3);
        
        % if we need to subtract the mean...
        if anomalies
            compGrid{v} = compGrid{v} - meanGrid{d}{v};
        end
    end
    
    % if taking difference between 2 time periods, subtract the first
    % period from the second
    if diff
        outputCompGrid{d} = compGrid{2} - compGrid{1};
        
    % otherwise just save the base period comp grid
    else
        outputCompGrid{d} = compGrid{1};
    end
    
    if statTest        
        compStdDev{d} = {};
        % calculate the std. of the comp variable at each gridbox for each time period over each year
        for v = 1:length(vars)
            compStdDev{d}{v} = [];
            for xlat = 1:length(compStatGrid{v})
                for ylon = 1:length(compStatGrid{v}{xlat})
                    compStdDev{d}{v}(xlat, ylon) = nanstd(squeeze(compStatGrid{v}{xlat}{ylon}-meanGrid{d}{v}(xlat, ylon)));
                end
            end
        end
        clear compStatGrid;
        
    end
    
    clear compGrid;
end



% average over all models
finalOutputCompData = [];
for d = 1:length(dataset)
    finalOutputCompData(:,:,d) = outputCompGrid{d};
end
finalOutputCompData = nanmean(finalOutputCompData, 3);
finalOutputStatData = [];

if statTest
    % calculate the mean of the std. dev. for each model
    stdDevMean = [];

    for d = 1:length(compStdDev)
        for xlat = 1:size(compStdDev{d}{1}, 1)
            for ylon = 1:size(compStdDev{d}{1}, 2)
                % squre to get the variance (so we can sum & average)
                stdDevMean(xlat, ylon, d) = compStdDev{d}{1}(xlat, ylon)*compStdDev{d}{1}(xlat, ylon);
            end
        end
    end

    stdDevMean = squeeze(nansum(stdDevMean(:, :, d), 3));
    stdDevMean = sqrt(stdDevMean(:, :) ./ length(compStdDev));
    
    % test if the multi-model mean is significant with respect to the mean
    % std. dev.
    for xlat = 1:size(finalOutputCompData, 1)
        for ylon = 1:size(finalOutputCompData, 2)
            if abs(finalOutputCompData(xlat, ylon)) > statTestThresh*stdDevMean(xlat, ylon) & stdDevMean(xlat, ylon) ~= 0
                finalOutputStatData(xlat, ylon) = 1;
            else
                finalOutputStatData(xlat, ylon) = 0;
            end
        end
    end
end

plotTitle='NARR DJF geopotential height field';

result = {lat, lon, double(finalOutputCompData)};


saveData = struct('data', {result}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', plotRange, ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', plotXUnits, ...
                  'boxCoords', boxCoords, ...
                  'colorMap', plotColorMap, ...
                  'blockWater', blockWater, ...
                  'statData', finalOutputStatData);

plotFromDataFile(saveData);

    
