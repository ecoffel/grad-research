summer = true;
testPeriod = 'past';

dataset = {'crcm/ccsm', 'crcm/cgcm3', ...
          'hrm3/gfdl', 'hrm3/hadcm3', 'mm5i/ccsm', ...
          'mm5i/hadcm3', 'rcm3/cgcm3', 'rcm3/gfdl', ...
          'wrfg/ccsm'};
%dataset = {'narr'};
      
% whether we're taking the difference of two different time periods
diff = false;

% whether to look at anomalies
minusMean = true;

% the temperature reference area
region = 'ne';
plotZone = 'north america';
fileformat = 'pdf';
baseDir = 'e:/';

% using a single narccap model and don't want to use regridded data
forceNoRegrid = false;

% nyc: 40-42, 285-287
% il: 39-40, 269-271
% az: 33-35, 247-249
if strcmp(region, 'ne')
    tempLatRange = [39 41];
    tempLonRange = [280 284];
elseif strcmp(region, 'sw')
    tempLatRange = [34.5 36.5];
    tempLonRange = [256 260];   
end

% cannot use diff except on narccap-gcm and for the future
if diff & ~strcmp(testPeriod, 'future')
    diff = false;
    ['test period must be future to use diff']
    return;
end

plotRange = [0 15];
plotXUnits = 'm/s';

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

tempPercentile = -1;
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

yearStep = 1;       % the number of years loaded at a time for memory  reasons

outputData = {};

for d = 1:length(dataset)
    tempTargetFileStr = '';
    tempTargetPlotStr = '';

    if strcmp(dataset{d}, 'ncep')
        vars = {'ncep-reanalysis/output'};
        if diff
            plotTitle = ['NCEP ' region ' 850 hPa winds diff at ', num2str(tempPercentile), ' percentile temps ', tempTargetPlotStr, '[', num2str(varPeriods{2}(1)), '-', num2str(varPeriods{2}(end)), '] - [', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)), ']'];
            fileTitle = ['uaVaTempExtremes-', region '-' testPeriod, '-', seasonStr, '-', num2str(tempPercentile), tempTargetFileStr, '-diff-ncep.' fileformat];
        else
            plotTitle = ['NCEP ' region ' 850 hPa winds at ', num2str(tempPercentile), ' percentile temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
            fileTitle = ['uaVaTempExtremes-', region '-' testPeriod, '-', seasonStr, '-', num2str(tempPercentile), tempTargetFileStr, '-ncep.' fileformat];
        end
    elseif strcmp(dataset{d}, 'narr')
        vars = {'narr/output'};
        if diff
            plotTitle = ['NARR ' region ' 850 hPa winds diff at ', num2str(tempPercentile), ' percentile temps ', tempTargetPlotStr, '[', num2str(varPeriods{2}(1)), '-', num2str(varPeriods{2}(end)), '] - [', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)), ']'];
            fileTitle = ['uaVaTempExtremes-', region '-' testPeriod, '-', seasonStr, '-', num2str(tempPercentile), tempTargetFileStr, '-diff-narr.' fileformat];
        else
            plotTitle = ['NARR ' region ' 850 hPa winds at ', num2str(tempPercentile), ' percentile temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
            fileTitle = ['uaVaTempExtremes-', region '-' testPeriod, '-', seasonStr, '-', num2str(tempPercentile), tempTargetFileStr, '-narr.' fileformat];
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
            vars = {['narccap/output/' dataset{d}], ['narccap/output/' dataset{d}]};
            plotTitle = ['NARCCAP ' modelStr ' ' region ' 850 hPa winds diff at ', num2str(tempPercentile), ' percentile temps ', tempTargetPlotStr, '[', num2str(varPeriods{2}(1)), '-', num2str(varPeriods{2}(end)), '] - [', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)), ']'];
            fileTitle = ['uaVaTempExtremes-', region '-' testPeriod, '-', seasonStr, '-', num2str(tempPercentile), tempTargetFileStr, '-diff-narccap-' modelStr '.' fileformat];
        else
            vars = {['narccap/output/' dataset{d}]};
            plotTitle = ['NARCCAP ' modelStr ' ' region ' 850 hPa winds at ', num2str(tempPercentile), ' percentile temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
            fileTitle = ['uaVaTempExtremes-', region '-' testPeriod, '-', seasonStr, '-', num2str(tempPercentile), tempTargetFileStr, '-narccap-' modelStr '.' fileformat];
        end    
    end

    lat = [];
    lon = [];

    dailyTempData = {};
    dailyUaData = {};
    dailyVaData = {};

    for v = 1:length(vars)
        
        if length(findstr(vars{1}, 'narccap')) ~= 0
            if summer
                tempVar = 'tasmax';
            else
                tempVar = 'tasmin';
            end

            uaVar = 'ua850';
            vaVar = 'va850';

            tempPlev = -1;
            uaVarLevel = -1;
            vaVarLevel = -1;

            isTempRegridded = true;
            isWindVarRegridded = true;
        elseif length(findstr(vars{1}, 'narr')) ~= 0
            if summer
                tempVar = 'tasmax';
            else
                tempVar = 'tasmin';
            end
            tempPlev = -1;

            uaVar = 'uwnd';
            vaVar = 'vwnd';

            uaVarLevel = narrPlevIndex(850);
            vaVarLevel = narrPlevIndex(850);

            isTempRegridded = false;
            isWindVarRegridded = false;
        elseif length(findstr(vars{1}, 'ncep')) ~= 0
            if summer
                tempVar = 'tmax';
            else
                tempVar = 'tmin';
            end
            tempPlev = -1;
            uaVarLevel = -1;
            vaVarLevel = -1;

            isTempRegridded = false;
            isWindVarRegridded = false;
        end
        
        dailyTempData{v} = [];
        dailyUaData{v} = [];
        dailyVaData{v} = [];

        ['loading ' vars{v} '...']
        for y = varPeriods{v}(1):yearStep:varPeriods{v}(end)
            ['year ' num2str(y)]

            if isTempRegridded
                tempStr = [baseDir 'data/' vars{v} '/' tempVar '/regrid'];
            else
                tempStr = [baseDir 'data/' vars{v} '/' tempVar];
            end

            if isWindVarRegridded
                uaVarStr = [baseDir 'data/' vars{v} '/' uaVar '/regrid'];
                vaVarStr = [baseDir 'data/' vars{v} '/' vaVar '/regrid'];
            else
                uaVarStr = [baseDir 'data/' vars{v} '/' uaVar];
                vaVarStr = [baseDir 'data/' vars{v} '/' vaVar];
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

            [latIndexRange, lonIndexRange] = latLonIndexRange(dailyTemp, tempLatRange, tempLonRange);

            curDailyTempData = dailyTemp{3};
            clear dailyTemp;

            if uaVarLevel ~= -1
                dailyUa = loadDailyData(uaVarStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', uaVarLevel);
            else
                dailyUa = loadDailyData(uaVarStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
            end
            
            if vaVarLevel ~= -1
                dailyVa = loadDailyData(vaVarStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', vaVarLevel);
            else
                dailyVa = loadDailyData(vaVarStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
            end

            if length(dailyUa{1}) == 0 | length(dailyVa{1}) == 0
                continue;
            end

            curDailyUaData = dailyUa{3};
            curDailyVaData = dailyVa{3};
            clear dailyUa dailyVa;

            curDailyTempData = single(curDailyTempData(:,:,:,months,:));
            curDailyUaData = single(curDailyUaData(:,:,:,months,:));
            curDailyVaData = single(curDailyVaData(:,:,:,months,:));

            curDailyTempData = reshape(curDailyTempData(latIndexRange, lonIndexRange, :, :, :), ...
                                       [length(latIndexRange), ...
                                       length(lonIndexRange), ...
                                       size(curDailyTempData, 3)*size(curDailyTempData,4)*size(curDailyTempData,5)]);
            curDailyUaData = reshape(curDailyUaData(:, :, :, :, :), ...
                                        [size(curDailyUaData, 1), size(curDailyUaData, 2), ...
                                         size(curDailyUaData, 3)*size(curDailyUaData,4)*size(curDailyUaData,5)]);
            curDailyVaData = reshape(curDailyVaData(:, :, :, :, :), ...
                                        [size(curDailyVaData, 1), size(curDailyVaData, 2), ...
                                         size(curDailyVaData, 3)*size(curDailyVaData,4)*size(curDailyVaData,5)]);

            % make sure temp and comp are same length
            curDailyUaData = curDailyUaData(:,:,1:min(size(curDailyUaData, 3), size(curDailyTempData, 3)));
            curDailyVaData = curDailyVaData(:,:,1:min(size(curDailyVaData, 3), size(curDailyTempData, 3)));
            curDailyTempData = curDailyTempData(:,:,1:min(min(size(curDailyUaData, 3), size(curDailyVaData, 3)), size(curDailyTempData, 3)));
            
            dailyTempData{v} = cat(3, dailyTempData{v}, curDailyTempData);
            clear curDailyTempData;
            
            dailyUaData{v} = cat(3, dailyUaData{v}, curDailyUaData);
            dailyVaData{v} = cat(3, dailyVaData{v}, curDailyVaData);
            clear curDailyUaData curDailyVaData;
        end

    end

    outputData{d} = {};

    if diff
        for v = 1:length(vars)
            dailyTempAvg = squeeze(nanmean(nanmean(dailyTempData{v}, 2), 1));
            dailyTempAvgCutoff = prctile(dailyTempAvg, tempPercentile);
            if summer
                tempInd = find(dailyTempAvg >= dailyTempAvgCutoff);
            else
                tempInd = find(dailyTempAvg <= dailyTempAvgCutoff);
            end

            % indices with temperatures < cutoff for calcuating mean zg500
            notTempInd = 1:length(dailyTempAvg);
            notTempInd(tempInd) = [];

            if minusMean
                dailyUaMean = nanmean(dailyUaData{v}(:,:,notTempInd), 3);
                dailyVaMean = nanmean(dailyVaData{v}(:,:,notTempInd), 3);
                dailyUaData{v} = nanmean(dailyUaData{v}(:,:,tempInd), 3)-dailyUaMean;
                dailyVaData{v} = nanmean(dailyVaData{v}(:,:,tempInd), 3)-dailyVaMean;
                clear dailyUaMean dailyVaMean;
            else
                dailyUaData{v} = nanmean(dailyUaData{v}(:,:,tempInd), 3);
                dailyVaData{v} = nanmean(dailyVaData{v}(:,:,tempInd), 3);
            end
        end

        outputData{d}{1} = dailyUaData{2} - dailyUaData{1};
        outputData{d}{2} = dailyVaData{2} - dailyVaData{1};
    else
        dailyTempAvg = squeeze(nanmean(nanmean(dailyTempData{1}, 2), 1));
        dailyTempAvgCutoff = prctile(dailyTempAvg, tempPercentile);
        if summer
            tempInd = find(dailyTempAvg >= dailyTempAvgCutoff);
        else
            tempInd = find(dailyTempAvg <= dailyTempAvgCutoff);
        end

        % indices with temperatures < cutoff for calcuating mean zg500
        notTempInd = 1:length(dailyTempAvg);
        notTempInd(tempInd) = [];

        if minusMean
            dailyUaMean = nanmean(dailyUaData{v}(:,:,notTempInd), 3);
            dailyVaMean = nanmean(dailyVaData{v}(:,:,notTempInd), 3);
            outputData{d}{1} = nanmean(dailyUaData{1}(:,:,tempInd), 3)-dailyUaMean;
            outputData{d}{2} = nanmean(dailyVaData{1}(:,:,tempInd), 3)-dailyVaMean;
            clear dailyUaMean dailyVaMean;
        else
            outputData{d}{1} = nanmean(dailyUaData{1}(:,:,tempInd), 3);
            outputData{d}{2} = nanmean(dailyVaData{1}(:,:,tempInd), 3);
        end
    end
    
    clear curDailyUaData curDailyVaData curDailyTempData dailyTempData dailyUaData dailyVaData;
end

% average over all models
finalOutputUaData = [];
finalOutputVaData = [];
for d = 1:length(dataset)
    finalOutputUaData(:,:,d) = outputData{d}{1};
    finalOutputVaData(:,:,d) = outputData{d}{2};
end
finalOutputUaData = nanmean(finalOutputUaData, 3);
finalOutputVaData = nanmean(finalOutputVaData, 3);

vectorSpacing = 3;
vectorData = {lat(1:vectorSpacing:end, 1:vectorSpacing:end), lon(1:vectorSpacing:end, 1:vectorSpacing:end), ...
              double(finalOutputUaData(1:vectorSpacing:end, 1:vectorSpacing:end)), ...
              double(finalOutputVaData(1:vectorSpacing:end, 1:vectorSpacing:end))};
vectorSpeeds = sqrt(finalOutputUaData .* finalOutputUaData + finalOutputVaData .* finalOutputVaData);

% plotting code
[fg,cb] = plotModelData({lat, lon, vectorSpeeds}, plotZone, 'caxis', plotRange, 'vectorData', vectorData, 'colormap', 'cool');
set(gca, 'Color', 'none');
xlabel(cb, plotXUnits, 'FontSize', 18);
cbPos = get(cb, 'Position');
title(plotTitle, 'FontSize', 18);
set(gcf, 'Position', get(0,'Screensize'));
set(gcf, 'Units', 'normalized');
set(gca, 'Units', 'normalized');

ti = get(gca,'TightInset');
set(gca,'Position',[ti(1) cbPos(2) 1-ti(3)-ti(1) 1-ti(4)-cbPos(2)-cbPos(4)]);
eval(['export_fig ' fileTitle ';']);
close all;

    
