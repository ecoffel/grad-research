
%dataset = {'narr'};
dataset = {'crcm/ccsm', 'crcm/cgcm3'};
% dataset = {'crcm/ccsm', 'crcm/cgcm3', 'ecp2/gfdl', ...
%           'hrm3/gfdl', 'hrm3/hadcm3', 'mm5i/ccsm', ...
%           'mm5i/hadcm3', 'rcm3/cgcm3', 'rcm3/gfdl', ...
%           'wrfg/ccsm', 'wrfg/cgcm3'};

% for mrso
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

summer = true;

testPeriod = 'past';

% whether to find the annual extreme or use a temp percentile
annualExtreme = true;

% if using annual extreme, find the max or the min?
findMax = true;
% if not annual extreme, specify temp percentile
tempPercentile = 25;

% whether we're taking the difference of two different time periods
diff = false;

blockWater = false;

% the temperature reference area
region = 'ne';
plotRegion = 'usa-exp';
fileformat = 'pdf';

% using a single narccap model and don't want to use regridded data
forceNoRegrid = false;

% whether to do statistical testing
statTest = true;
% how many standard deviations above mean to consider significant
statTestThresh = 1;
% what percentage of models must be above threshold
statTestModelFrac = 0.5;
% whether to do the stat test for only base period extremes (true) or for all days (false)
statTestExt = true;

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
    plotRange = [-150 150];
    plotXUnits = 'm';
elseif strcmp(compVar, 'tasmax') | strcmp(compVar, 'tasmin')
    gridbox = false;
    plotRange = [-20 20];
    plotXUnits = 'degrees C';
elseif strcmp(compVar, 'mrso')
    gridbox = true;
    if strcmp(dataset, 'narr')
        plotRange = [-200 200];
        plotXUnits = 'kg / m^2';
    else
        plotRange = [-200 200];
        plotXUnits = 'kg / m^2';
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
minusMean = true;

outputCompData = {};

if statTest
    dailyCompStatData = {};
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
    baseGrid = {};

    dailyTempData = {};
    dailyCompData = {};

    for v = 1:length(vars)
        dailyTempData{v} = [];
        dailyCompData{v} = [];

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

            if tempPlev ~= -1
                dailyTemp = loadDailyData(tempStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', tempPlev);
            else
                dailyTemp = loadDailyData(tempStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
            end

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
            curDailyCompData = curDailyCompData(:,:,1:min(size(curDailyCompData, 3), size(curDailyTempData, 3)));
            curDailyTempData = curDailyTempData(:,:,1:min(size(curDailyCompData, 3), size(curDailyTempData, 3)));
            
            dailyTempData{v} = cat(3, dailyTempData{v}, curDailyTempData);
            clear curDailyTempData;
            dailyCompData{v} = cat(3, dailyCompData{v}, curDailyCompData);
            clear curDailyCompData;
        end

    end

    outputCompData{d} = [];
    
    if statTest
        dailyCompStatData{d} = {};
    end
    
    if gridbox
        if diff
            outputCompData{d} = {};
            for v = 1:length(vars)
                if size(dailyTempData{v}, 1) == size(dailyCompData{v}, 1) & ...
                   size(dailyTempData{v}, 2) == size(dailyCompData{v}, 2)
                    for x = 1:size(dailyTempData{v}, 1)
                        for y = 1:size(dailyTempData{v}, 2)
                            
                            if annualExtreme
                                if findMax
                                    tempInd = find(dailyTempData{v}(x, y, :) == max(dailyTempData{v}(x, y, :)));
                                else
                                    tempInd = find(dailyTempData{v}(x, y, :) == min(dailyTempData{v}(x, y, :)));
                                end
                            else
                                gridboxTempAvgCutoff = prctile(dailyTempData{v}(x, y, :), tempPercentile);
                                if summer
                                    tempInd = find(dailyTempData{v}(x, y, :) >= gridboxTempAvgCutoff);
                                else
                                    tempInd = find(dailyTempData{v}(x, y, :) <= gridboxTempAvgCutoff);
                                end
                            end

                            % indices with temperatures < cutoff for calcuating mean zg500
                            notTempInd = 1:size(dailyTempData{v}(x, y, :), 3);
                            notTempInd(tempInd) = [];

                            if statTest
                                if statTestExt
                                    dailyCompStatData{v} = dailyCompData{v}(:,:,tempInd);
                                else
                                    dailyCompStatData{v} = dailyCompData{v}(:,:,:);
                                end
                            end
                            
                            if minusMean
                                dailyCompMean = nanmean(dailyCompData{v}(x,y,notTempInd), 3);
                                outputCompData{d}{v}(x, y) = nanmean(dailyCompData{v}(x, y, tempInd), 3) - dailyCompMean;
                                clear dailyCompMean;
                            else
                                outputCompData{d}{v}(x, y) = nanmean(dailyCompData{v}(x, y, tempInd), 3);
                            end 
                        end
                    end
                else
                    ['bad regridding']
                    break;
                end
            end

            outputCompData{d} = outputCompData{d}{2} - outputCompData{d}{1};

        else
            if size(dailyTempData{1}, 1) == size(dailyCompData{1}, 1) & ...
               size(dailyTempData{1}, 2) == size(dailyCompData{1}, 2)
                for x = 1:size(dailyTempData{1}, 1)
                    for y = 1:size(dailyTempData{1}, 2)
                        
                        if annualExtreme
                            if findMax
                                tempInd = find(dailyTempData{v}(x, y, :) == max(dailyTempData{v}(x, y, :)));
                            else
                                tempInd = find(dailyTempData{v}(x, y, :) == min(dailyTempData{v}(x, y, :)));
                            end
                        else
                            gridboxTempAvgCutoff = prctile(dailyTempData{v}(x, y, :), tempPercentile);
                            if summer
                                tempInd = find(dailyTempData{v}(x, y, :) >= gridboxTempAvgCutoff);
                            else
                                tempInd = find(dailyTempData{v}(x, y, :) <= gridboxTempAvgCutoff);
                            end
                        end
                            

                        % indices with temperatures < cutoff for calcuating mean zg500
                        notTempInd = 1:size(dailyTempData{1}(x, y, :), 3);
                        notTempInd(tempInd) = [];

                        if statTest
                            if statTestExt
                                dailyCompStatData{1} = dailyCompData{1}(:,:,tempInd);
                            else
                                dailyCompStatData{1} = dailyCompData{1}(:,:,:);
                            end
                        end
                        
                        if minusMean
                            dailyCompMean = nanmean(dailyCompData{1}(x,y,notTempInd), 3);
                            outputCompData{d}(x, y) = nanmean(dailyCompData{1}(x, y, tempInd), 3) - dailyCompMean;
                            clear dailyCompMean;
                        else
                            outputCompData{d}(x, y) = nanmean(dailyCompData{1}(x, y, tempInd), 3);
                        end
                    end
                end
            else
                ['bad regridding']
                break;
            end
        end
    else
        if diff
            
            dailyCompMean = {};
            
            for v = 1:length(vars)
                
                dailyTempAvg = squeeze(nanmean(nanmean(dailyTempData{v}, 2), 1));
                
                if annualExtreme
                    if findMax
                        tempInd = find(dailyTempAvg == max(dailyTempAvg));
                    else
                        tempInd = find(dailyTempAvg == min(dailyTempAvg));
                    end
                else
                    dailyTempAvgCutoff = prctile(dailyTempAvg, tempPercentile);
                    if summer
                        tempInd = find(dailyTempAvg >= dailyTempAvgCutoff);
                    else
                        tempInd = find(dailyTempAvg <= dailyTempAvgCutoff);
                    end
                end

                % indices with temperatures < cutoff for calcuating mean zg500
                notTempInd = 1:length(dailyTempAvg);
                notTempInd(tempInd) = [];
                
                if statTest
                    if statTestExt
                        dailyCompStatData{v} = dailyCompData{v}(:,:,tempInd);
                    else
                        dailyCompStatData{v} = dailyCompData{v}(:,:,:);
                    end
                end
                
                dailyCompMean{v} = nanmean(dailyCompData{v}(:,:,notTempInd), 3);
                dailyCompData{v} = dailyCompData{v}(:,:,tempInd);
                
%                 if minusMean
%                     dailyCompMean{v} = nanmean(dailyCompData{v}(:,:,notTempInd), 3);
%                     dailyCompData{v} = dailyCompData{v}(:,:,tempInd);
%                     %dailyCompData{v} = nanmean(dailyCompData{v}(:,:,tempInd), 3)-dailyCompMean;
%                     clear dailyCompMean;
%                 else
%                     % here is the issue for stat testing with diff=true
%                     %dailyCompData{v} = nanmean(dailyCompData{v}(:,:,tempInd), 3);
%                     dailyCompData{v} = dailyCompData{v}(:,:,tempInd);
%                 end
            end

            if minusMean
                outputCompData{d} = nanmean(dailyCompData{2}-dailyCompMean{2}, 3) - nanmean(dailyCompData{1}-dailyCompMean{1}, 3);
            else
                outputCompData{d} = nanmean(dailyCompData{2}, 3) - nanmean(dailyCompData{1}, 3);
            end
            
            clear varTempInd dailyCompMean;
        else
            dailyTempAvg = squeeze(nanmean(nanmean(dailyTempData{1}, 2), 1));
            
            if annualExtreme
                if findMax
                    tempInd = find(dailyTempAvg == max(dailyTempAvg));
                else
                    tempInd = find(dailyTempAvg == min(dailyTempAvg));
                end
            else
                dailyTempAvgCutoff = prctile(dailyTempAvg, tempPercentile);
                if summer
                    tempInd = find(dailyTempAvg >= dailyTempAvgCutoff);
                else
                    tempInd = find(dailyTempAvg <= dailyTempAvgCutoff);
                end
            end

            % indices with temperatures < cutoff for calcuating mean zg500
            notTempInd = 1:length(dailyTempAvg);
            notTempInd(tempInd) = [];

            if statTest
                if statTestExt
                    dailyCompStatData{1} = dailyCompData{1}(:,:,tempInd);
                else
                    dailyCompStatData{1} = dailyCompData{1}(:,:,:);
                end
            end
            
            if minusMean
                dailyCompMean = nanmean(dailyCompData{1}(:,:,notTempInd), 3);
                outputCompData{d} = nanmean(dailyCompData{1}(:,:,tempInd), 3)-dailyCompMean;
                clear dailyCompMean;
            else
                outputCompData{d} = nanmean(dailyCompData{1}(:,:,tempInd), 3);
            end
        end
    end
    
    if statTest
        tempStdDev{d} = {};
        for v = 1:length(vars)
            tempStdDev{d}{v} = [];
            for xlat = 1:size(dailyTempData{v}, 1)
                for ylon = 1:size(dailyTempData{v}, 2)
                    tempStdDev{d}{v}(xlat, ylon) = nanstd(squeeze(dailyTempData{v}(xlat, ylon, :)));
                end
            end
            
            for xlat = 1:size(dailyCompStatData{v}, 1)
                for ylon = 1:size(dailyCompStatData{v}, 2)
                    compStdDev{d}{v}(xlat, ylon) = nanstd(squeeze(dailyCompStatData{v}(xlat, ylon, :)));
                end
            end
        end
        
        % compare anonaly difference to base period variability
        outputStatData{d} = [];
        for xlat = 1:size(outputCompData{d}, 1)
            for ylon = 1:size(outputCompData{d}, 2)
                if abs(outputCompData{d}(xlat, ylon)) > statTestThresh*compStdDev{d}{1}(xlat, ylon)
                    outputStatData{d}(xlat, ylon) = 1;
                else
                    outputStatData{d}(xlat, ylon) = 0;
                end
            end
        end
    end
    
    clear curDailyCompData dailyCompStatData curDailyTempData dailyTempData dailyCompData;
end

% average over all models
finalOutputCompData = [];
for d = 1:length(dataset)
    finalOutputCompData(:,:,d) = outputCompData{d};
end
finalOutputCompData = nanmean(finalOutputCompData, 3);

if statTest
    finalOutputStatData = [];
    for xlat = 1:size(outputStatData{1}, 1)
        for ylon = 1:size(outputStatData{1}, 2)
            numModelsSig = 0;
            for d = 1:length(dataset)
                if outputStatData{d}(xlat, ylon) == 1
                    numModelsSig = numModelsSig+1;
                end
            end
            if numModelsSig > statTestModelFrac*length(dataset)
                finalOutputStatData(xlat, ylon) = 1;
            else
                finalOutputStatData(xlat, ylon) = 0;
            end
        end
    end
end

plotTitle='NARCCAP DJF 500 hPa geopotential height anomaly change';

result = {lat, lon, double(finalOutputCompData)};
saveData = {result, plotRegion, plotRange, plotTitle, fileTitle, plotXUnits, boxCoords, [], blockWater, finalOutputStatData};
plotFromDataFile(saveData);

    
