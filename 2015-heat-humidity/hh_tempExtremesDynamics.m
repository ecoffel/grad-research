testPeriod = 'past';

% models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
%           'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
%           'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
%           'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};

models = {'bnu-esm'};

testVar = 'tos';
testRcp = 'historical';
baseVar = 'wb';
baseRcp = 'historical'

% whether to find the annual extreme or use a temp percentile
annualExtreme = false;

% if using annual extreme, find the max or the min?
findMax = true;

% if not annual extreme, specify temp percentile
tempPercentile = 98;

% whether we're taking the difference of two different time periods
diff = false;

% the temperature reference area
region = 'india';
plotRegion = 'world';
fileformat = 'pdf';

baseDir = 'e:/';
ensemble = 'r1i1p1';
modelDir = 'cmip5/output';

basePeriod = 1985:2005;
futurePeriod = 2051:2069;

baseRegrid = true;
testRegrid = true;

% should we look at anomalies
minusMean = true;
% relative to the mean of the month where the extreme anom is?
monthlyMean = true;

testVarLevel = -1;

if strcmp(region, 'us-ne')
    % right around NYC
    latBounds = [40 41];
    lonBounds = [-75 -74] + 360;
elseif strcmp(region, 'india')
    latBounds = [25 26];
    lonBounds = [82 83];   
elseif strcmp(region, 'west-africa')
    latBounds = [34.5 36.5];
    lonBounds = [256 260];   
elseif strcmp(region, 'china')
    latBounds = [34.5 36.5];
    lonBounds = [256 260];   
end

if strcmp(testVar, 'tos')
    gridbox = false;
    if minusMean || diff
        plotRange = [-10 10];
    else
        plotRange = [0 40];
    end
    plotXUnits = 'degrees C';
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

yearStep = 1; % the number of years loaded at a time for memory  reasons

outputTestData = {};

for d = 1:length(models)
    
    if strcmp(models{d}, 'ncep')
        vars = {'ncep-reanalysis/output'};
    elseif strcmp(models{d}, 'narr')
        vars = {'narr/output'};
    else
        if diff
            vars = {[models{d}], [models{d}]};
        else
            vars = {[models{d}]};
        end    
    end
    
    if length(findstr(vars{1}, 'narr')) ~= 0
        if summer
            tempVar = 'tasmax';
        else
            tempVar = 'tasmin';
        end
        tempPlev = -1;

        isTempRegridded = false;
        istestVarRegridded = false;
    elseif length(findstr(vars{1}, 'ncep')) ~= 0
        if summer
            tempVar = 'tmax';
        else
            tempVar = 'tmin';
        end
        tempPlev = -1;

        isTempRegridded = false;
    end
    
    tempTargetFileStr = '';
    tempTargetPlotStr = '';

    if strcmp(models{d}, 'ncep')
        if diff
            plotTitle = ['NCEP ' testVar ' diff at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{2}(1)), '-', num2str(varPeriods{2}(end)), '] - [', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)), ']'];
            fileTitle = [testVar 'TempExtremes-', testPeriod, '-', '-', tempDispStr, tempTargetFileStr, '-diff-ncep.' fileformat];
        else
            plotTitle = ['NCEP ' testVar ' at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
            fileTitle = [testVar 'TempExtremes-', testPeriod, '-', '-', tempDispStr, tempTargetFileStr, '-ncep.' fileformat];
        end
    elseif strcmp(models{d}, 'narr')
        if diff
            plotTitle = ['NARR ' testVarName ' diff at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{2}(1)), '-', num2str(varPeriods{2}(end)), '] - [', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)), ']'];
            fileTitle = [testVarName 'TempExtremes-', testPeriod, '-', '-', tempDispStr, tempTargetFileStr, '-diff-narr.' fileformat];
        else
            plotTitle = ['NARR ' testVarName ' at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
            fileTitle = [testVarName 'TempExtremes-', testPeriod, '-', '-', tempDispStr, tempTargetFileStr, '-narr.' fileformat];
        end
    else
        if length(models) > 2
            modelStr = 'cmip5';
        else
            modelStr = models{d};
        end

        if diff
            vars = {['cmip5/output/' models{d} '/' ensemble '/' baseRcp], ['cmip5/output/' models{d} '/' ensemble '/' testRcp]};
            plotTitle = [modelStr ' ' testVar ' diff at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{2}(1)), '-', num2str(varPeriods{2}(end)), '] - [', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)), ']'];
            fileTitle = [testVar 'TempExtremes-', testPeriod, '-', '-', tempDispStr, tempTargetFileStr, '-diff-' modelStr '.' fileformat];
        else
            vars = {['cmip5/output/' models{d} '/' ensemble '/' baseRcp]};
            plotTitle = [modelStr ' ' testVar ' at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
            fileTitle = [testVar 'TempExtremes-', testPeriod, '-', '-', tempDispStr, tempTargetFileStr, '-' modelStr '.' fileformat];
        end    
    end

    lat = [];
    lon = [];
    baseGrid = {};

    dailyBaseData = {};
    dailyTestData = {};

    yearLengths = [];
    
    for v = 1:length(vars)
        dailyBaseData{v} = [];
        dailyTestData{v} = [];

        ['loading ' vars{v} '...']
        for y = varPeriods{v}(1):yearStep:varPeriods{v}(end)
            ['year ' num2str(y)]

            if baseRegrid
                baseStr = [baseDir 'data/' vars{v} '/' baseVar '/regrid/world'];
            else
                baseStr = [baseDir 'data/' vars{v} '/' baseVar];
            end

            if testRegrid
                testStr = [baseDir 'data/' vars{v} '/' testVar '/regrid/world'];
            else
                testStr = [baseDir 'data/' vars{v} '/' testVar];
            end

            dailyBase = loadDailyData(baseStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));

            if length(lat) == 0 | length(lon) == 0
                lat = dailyBase{1};
                lon = dailyBase{2};
            end

            if strcmp(baseVar, 'tos')
                dailyBase{3} = dailyBase{3} - 273.15;
            end
            
            if ~gridbox
                [latIndexRange, lonIndexRange] = latLonIndexRange(dailyBase, latBounds, lonBounds);
            end

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

            curDailyBaseData = single(curDailyBaseData);
            curDailyTestData = single(curDailyTestData);

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

            % make sure temp and comp are same length
            curDailyTestData = curDailyTestData(:,:,1:min(size(curDailyTestData, 3), size(curDailyBaseData, 3)));
            curDailyBaseData = curDailyBaseData(:,:,1:min(size(curDailyTestData, 3), size(curDailyBaseData, 3)));
            
            if length(yearLengths) < d
                yearLengths(d) = size(curDailyBaseData, 3);
            end
            
            dailyBaseData{v} = cat(3, dailyBaseData{v}, curDailyBaseData);
            clear curDailyBaseData;
            dailyTestData{v} = cat(3, dailyTestData{v}, curDailyTestData);
            clear curDailyTestData;
        end

    end

    outputTestData{d} = [];

    if diff
        for v = 1:length(vars)

            dailyBaseAvg = squeeze(nanmean(nanmean(dailyBaseData{v}, 2), 1));

            if annualExtreme
                if findMax
                    tempInd = find(dailyBaseAvg == max(dailyBaseAvg));
                else
                    tempInd = find(dailyBaseAvg == min(dailyBaseAvg));
                end
            else
                dailyBaseAvgCutoff = prctile(dailyBaseAvg, tempPercentile);
                if summer
                    tempInd = find(dailyBaseAvg >= dailyBaseAvgCutoff);
                else
                    tempInd = find(dailyBaseAvg <= dailyBaseAvgCutoff);
                end
            end

            notTempInd = 1:length(dailyBaseAvg);
            notTempInd(tempInd) = [];

            if minusMean
                dailyTestMean = nanmean(dailyTestData{v}(:,:,notTempInd), 3);
                dailyTestData{v} = nanmean(dailyTestData{v}(:,:,tempInd), 3)-dailyTestMean;
                clear dailyTestMean;
            else
                dailyTestData{v} = nanmean(dailyTestData{v}(:,:,tempInd), 3);
            end
        end

        outputTestData{d} = dailyTestData{2} - dailyTestData{1};
    else
            
        dailyBaseAvg = squeeze(nanmean(nanmean(dailyBaseData{1}, 2), 1));

        if annualExtreme
            if findMax
                tempInd = find(dailyBaseAvg == max(dailyBaseAvg));
            else
                tempInd = find(dailyBaseAvg == min(dailyBaseAvg));
            end
        else
            dailyBaseAvgCutoff = prctile(dailyBaseAvg, tempPercentile);
            if summer
                tempInd = find(dailyBaseAvg >= dailyBaseAvgCutoff);
            else
                tempInd = find(dailyBaseAvg <= dailyBaseAvgCutoff);
            end
        end

        % ------------------------------------------------------------
        % need to find index for each year
        
        % for now, take average +- 15 days from index and add/sub year
        % length to get monthly average across base period
        monthlyMeans = [];
        
        % loop backwards
        i = tempInd;
        while i > 15
            monthlyMeans(:, :, d) = nanmean(dailyTestData{1}(:,:,i-15:i+15), 3);
            i = i - yearLengths(d);
        end
        
        % loop forward
        i = tempInd;
        while i < size(dailyTestData{1}, 3)-15
            monthlyMeans(:, :, d) = nanmean(dailyTestData{1}(:,:,i-15:i+15), 3);
            i = i + yearLengths(d);
        end

        notTempInd = 1:length(dailyBaseAvg);
        notTempInd(tempInd) = [];
        
        if minusMean
            dailyTestMean = nanmean(dailyTestData{1}(:,:,notTempInd), 3);
            if monthlyMean
                outputTestData{d} = nanmean(dailyTestData{1}(:,:,tempInd), 3) - nanmean(monthlyMeans, 3);
            else
                outputTestData{d} = nanmean(dailyTestData{1}(:,:,tempInd), 3) - dailyTestMean;
            end
            clear dailyTestMean;
        else
            outputTestData{d} = nanmean(dailyTestData{1}(:,:,tempInd), 3);
        end
    end
end

clear curDailyTestData curDailyBaseData dailyBaseData dailyTestData;

% average over all models
finalOutputTestData = [];
for d = 1:length(models)
    finalOutputTestData(:,:,d) = outputTestData{d};
end
finalOutputTestData = nanmean(finalOutputTestData, 3);

% plotting code
[fg,cb] = plotModelData({lat, lon, double(finalOutputTestData)}, plotRegion, 'caxis', plotRange);
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

    
