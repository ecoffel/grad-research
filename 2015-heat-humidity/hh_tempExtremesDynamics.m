summer = true;
testPeriod = 'future';

dataset = {'bnu-esm', 'canesm2', 'cnrm-cm5', ...
          'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'ipsl-cm5a-mr', ...
          'hadgem2-es', 'mri-cgcm3', 'noresm1-m'};
      
testVar = 'rh';
testRcp = 'rcp85';
baseVar = 'tasmax';
baseRcp = 'historical'

% whether to find the annual extreme or use a temp percentile
annualExtreme = true;

% if using annual extreme, find the max or the min?
findMax = true;

% if not annual extreme, specify temp percentile
tempPercentile = 90;

% whether we're taking the difference of two different time periods
diff = true;

% the temperature reference area
region = 'ne';
plotZone = 'usa-exp';
fileformat = 'pdf';

baseDir = 'e:/';
ensemble = 'r1i1p1';
modelDir = 'cmip5/output';

basePeriod = 1981:2005;
futurePeriod = 2051:2069;

baseRegrid = true;
testRegrid = true;

testVarLevel = -1;

if strcmp(region, 'ne')
    baseLatRange = [39 41];
    baseLonRange = [280 284];
elseif strcmp(region, 'sw')
    baseLatRange = [34.5 36.5];
    baseLonRange = [256 260];   
end

if strcmp(testVar, 'zg500')
    gridbox = false;
    plotRange = [-150 150];
    plotXUnits = 'm';
elseif strcmp(testVar, 'mrso')
    gridbox = true;
    if strcmp(dataset, 'narr')
        plotRange = [-200 200];
        plotXUnits = 'kg / m^2';
    else
        plotRange = [-200 200];
        plotXUnits = 'kg / m^2';
    end
elseif strcmp(testVar, 'swe')
    gridbox = true;
    if diff
        plotRange = [-0.01 0.01];
    else
        plotRange = [-0.02 0.02];
    end
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
elseif strcmp(testVar, 'psl')
    gridbox = false;
	plotRange = [-100 100];
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

seasonStr = '';
if summer
    months = [6 7 8];
    seasonStr = 'jja';
else
    months = [12 1 2];
    seasonStr = 'djf';
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
minusMean = true;

outputTestData = {};

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

        if strcmp(testVar, 'zg500')
            testVarName = 'zg500';
            testVarLevel = -1;
        elseif strcmp(testVar, 'mrso')
            testVarName = 'mrso';
            testVarLevel = -1;
        elseif strcmp(testVar, 'swe')
            testVarName = 'swe';
            testVarLevel = -1;
        else
            testVarName = testVar;
            testVarLevel = -1;
        end

    elseif length(findstr(vars{1}, 'narr')) ~= 0
        if summer
            tempVar = 'tasmax';
        else
            tempVar = 'tasmin';
        end
        tempPlev = -1;

        if strcmp(testVar, 'zg500')
            testVarName = 'hgt';
            testVarLevel = 2;
        elseif strcmp(testVar, 'mrso')
            testVarName = 'soilm';
            testVarLevel = -1;
        elseif strcmp(testVar, 'swe')
            testVarName = 'snod';
            testVarLevel = -1;
        end

        isTempRegridded = false;
        istestVarRegridded = false;
    elseif length(findstr(vars{1}, 'ncep')) ~= 0
        if summer
            tempVar = 'tmax';
        else
            tempVar = 'tmin';
        end
        tempPlev = -1;

        if strcmp(testVar, 'zg500')
            testVarName = 'hgt';
            testVarLevel = -1;
            istestVarRegridded = true;
        elseif strcmp(testVar, 'mrso')
            testVarName = 'soilw';
            testVarLevel = -1;
            istestVarRegridded = false;
        elseif strcmp(testVar, 'swe')
            testVarName = '';
            testVarLevel = -1;
            istestVarRegridded = false;
        end

        isTempRegridded = false;
    end
    
    tempTargetFileStr = '';
    tempTargetPlotStr = '';
    if strcmp(testVar, 'zg500')
        tempTargetFileStr = ['-' num2str(round(mean(tempLatRange))) 'n-' num2str(round(mean(tempLonRange))) 'e'];
        tempTargetPlotStr = ['[' num2str(tempLatRange(1)) '-' num2str(tempLatRange(2)) ' N], [' num2str(tempLonRange(1)) '-' num2str(tempLonRange(2)) ' E], '];
    end

    if strcmp(dataset{d}, 'ncep')
        if diff
            plotTitle = ['NCEP ' testVar ' diff at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{2}(1)), '-', num2str(varPeriods{2}(end)), '] - [', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)), ']'];
            fileTitle = [testVar 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-diff-ncep.' fileformat];
        else
            plotTitle = ['NCEP ' testVar ' at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
            fileTitle = [testVar 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-ncep.' fileformat];
        end
    elseif strcmp(dataset{d}, 'narr')
        if diff
            plotTitle = ['NARR ' testVarName ' diff at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{2}(1)), '-', num2str(varPeriods{2}(end)), '] - [', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)), ']'];
            fileTitle = [testVarName 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-diff-narr.' fileformat];
        else
            plotTitle = ['NARR ' testVarName ' at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
            fileTitle = [testVarName 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-narr.' fileformat];
        end
    else
        if length(dataset) > 2
            modelStr = 'cmip5';
        else
            modelStr = dataset{d};
        end
%         
%         if diff
%             plotTitle = ['NARCCAP ' modelStr ' ' compVar ' diff at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{2}(1)), '-', num2str(varPeriods{2}(end)), '] - [', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)), ']'];
%             fileTitle = [compVar 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-diff-narccap-' modelStr '.' fileformat];
%         else
%             plotTitle = ['NARCCAP ' modelStr ' ' compVar ' at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
%             fileTitle = [compVar 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-narccap-' modelStr '.' fileformat];
%         end   
%         
        if diff
            vars = {['cmip5/output/' dataset{d} '/' ensemble '/' baseRcp], ['cmip5/output/' dataset{d} '/' ensemble '/' testRcp]};
            plotTitle = [modelStr ' ' testVar ' diff at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{2}(1)), '-', num2str(varPeriods{2}(end)), '] - [', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)), ']'];
            fileTitle = [testVar 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-diff-narccap-' modelStr '.' fileformat];
        else
            vars = {['cmip5/output/' dataset{d} '/' ensemble '/' baseRcp]};
            plotTitle = [modelStr ' ' testVar ' at ', tempDispStr, ' temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
            fileTitle = [testVar 'TempExtremes-', testPeriod, '-', seasonStr, '-', tempDispStr, tempTargetFileStr, '-narccap-' modelStr '.' fileformat];
        end    
    end

    lat = [];
    lon = [];
    baseGrid = {};

    dailyBaseData = {};
    dailyTestData = {};

    for v = 1:length(vars)
        dailyBaseData{v} = [];
        dailyTestData{v} = [];

        ['loading ' vars{v} '...']
        for y = varPeriods{v}(1):yearStep:varPeriods{v}(end)
            ['year ' num2str(y)]

            if baseRegrid
                baseStr = [baseDir 'data/' vars{v} '/' baseVar '/regrid'];
            else
                baseStr = [baseDir 'data/' vars{v} '/' baseVar];
            end

            if testRegrid
                testStr = [baseDir 'data/' vars{v} '/' testVar '/regrid'];
            else
                testStr = [baseDir 'data/' vars{v} '/' testVar];
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
                [latIndexRange, lonIndexRange] = latLonIndexRange(dailyBase, baseLatRange, baseLonRange);
            end

            curDailyBaseData = dailyBase{3};
            clear dailyBase;

            if testVarLevel ~= -1
                dailyTest = loadDailyData(testStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', testVarLevel);
            else
                if strcmp(testVar, 'zg500')
                    dailyTest = loadDailyData(testStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'mult', 8, 'multMethod', 'mean');
                else
                    dailyTest = loadDailyData(testStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
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

            % make sure temp and comp are same length
            curDailyTestData = curDailyTestData(:,:,1:min(size(curDailyTestData, 3), size(curDailyBaseData, 3)));
            curDailyBaseData = curDailyBaseData(:,:,1:min(size(curDailyTestData, 3), size(curDailyBaseData, 3)));
            
            dailyBaseData{v} = cat(3, dailyBaseData{v}, curDailyBaseData);
            clear curDailyBaseData;
            dailyTestData{v} = cat(3, dailyTestData{v}, curDailyTestData);
            clear curDailyTestData;
        end

    end

        outputTestData{d} = [];

    if gridbox
        if diff
            outputTestData{d} = {};
            for v = 1:length(vars)
                if size(dailyBaseData{v}, 1) == size(dailyTestData{v}, 1) & ...
                   size(dailyBaseData{v}, 2) == size(dailyTestData{v}, 2)
                    for x = 1:size(dailyBaseData{v}, 1)
                        for y = 1:size(dailyBaseData{v}, 2)
                            
                            if annualExtreme
                                if findMax
                                    tempInd = find(dailyBaseData{v}(x, y, :) == max(dailyBaseData{v}(x, y, :)));
                                else
                                    tempInd = find(dailyBaseData{v}(x, y, :) == min(dailyBaseData{v}(x, y, :)));
                                end
                            else
                                gridboxBaseAvgCutoff = prctile(dailyBaseData{v}(x, y, :), tempPercentile);
                                if summer
                                    tempInd = find(dailyBaseData{v}(x, y, :) >= gridboxBaseAvgCutoff);
                                else
                                    tempInd = find(dailyBaseData{v}(x, y, :) <= gridboxBaseAvgCutoff);
                                end
                            end

                            % indices with temperatures < cutoff for calcuating mean zg500
                            notTempInd = 1:size(dailyBaseData{v}(x, y, :), 3);
                            notTempInd(tempInd) = [];

                            % if we're doing mrso, need to normalize the data to
                            % get mrso "fraction"
%                             if strcmp(testVar, 'mrso')
%                                 if strcmp(dataset{d}, 'narccap-gcm') | strcmp(dataset{d}, 'narccap-ncep')
%                                     dailyTestData{v}(x, y, :) = dailyTestData{v}(x, y, :) ./ nanmax(dailyTestData{v}(x, y, :), [], 3);
%                                 end
%                             end

                            if minusMean
                                dailyTestMean = nanmean(dailyTestData{v}(x,y,notTempInd), 3);
                                outputTestData{d}{v}(x, y) = nanmean(dailyTestData{v}(x, y, tempInd), 3) - dailyTestMean;
                                clear dailyTestMean;
                            else
                                outputTestData{d}{v}(x, y) = nanmean(dailyTestData{v}(x, y, tempInd), 3);
                            end 
                        end
                    end
                else
                    ['bad regridding']
                    break;
                end
            end

            outputTestData{d} = outputTestData{d}{2} - outputTestData{d}{1};

        else
            if size(dailyBaseData{1}, 1) == size(dailyTestData{1}, 1) & ...
               size(dailyBaseData{1}, 2) == size(dailyTestData{1}, 2)
                for x = 1:size(dailyBaseData{1}, 1)
                    for y = 1:size(dailyBaseData{1}, 2)
                        
                        if annualExtreme
                            if findMax
                                tempInd = find(dailyBaseData{v}(x, y, :) == max(dailyBaseData{v}(x, y, :)));
                            else
                                tempInd = find(dailyBaseData{v}(x, y, :) == min(dailyBaseData{v}(x, y, :)));
                            end
                        else
                            gridboxBaseAvgCutoff = prctile(dailyBaseData{v}(x, y, :), tempPercentile);
                            if summer
                                tempInd = find(dailyBaseData{v}(x, y, :) >= gridboxBaseAvgCutoff);
                            else
                                tempInd = find(dailyBaseData{v}(x, y, :) <= gridboxBaseAvgCutoff);
                            end
                        end
                            

                        % indices with temperatures < cutoff for calcuating mean zg500
                        notTempInd = 1:size(dailyBaseData{1}(x, y, :), 3);
                        notTempInd(tempInd) = [];

                        % if we're doing mrso, need to normalize the data to
                        % get mrso "fraction"
%                         if strcmp(testVar, 'mrso')
%                             if strcmp(dataset{d}, 'narccap-gcm') | strcmp(dataset{d}, 'narccap-ncep')
%                                 dailyTestData{1}(x, y, :) = dailyTestData{1}(x, y, :) ./ nanmax(dailyTestData{1}(x, y, :), [], 3);
%                             end
%                         end

                        if minusMean
                            dailyTestMean = nanmean(dailyTestData{1}(x,y,notTempInd), 3);
                            outputTestData{d}(x, y) = nanmean(dailyTestData{1}(x, y, tempInd), 3) - dailyTestMean;
                            clear dailyTestMean;
                        else
                            outputTestData{d}(x, y) = nanmean(dailyTestData{1}(x, y, tempInd), 3);
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

                % indices with temperatures < cutoff for calcuating mean zg500
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

            % indices with temperatures < cutoff for calcuating mean zg500
            notTempInd = 1:length(dailyBaseAvg);
            notTempInd(tempInd) = [];

            if minusMean
                dailyTestMean = nanmean(dailyTestData{1}(:,:,notTempInd), 3);
                outputTestData{d} = nanmean(dailyTestData{1}(:,:,tempInd), 3)-dailyTestMean;
                clear dailyTestMean;
            else
                outputTestData{d} = nanmean(dailyTestData{1}(:,:,tempInd), 3);
            end
        end
    end
    
    clear curDailyTestData curDailyBaseData dailyBaseData dailyTestData;
end

% average over all models
finalOutputTestData = [];
for d = 1:length(dataset)
    finalOutputTestData(:,:,d) = outputTestData{d};
end
finalOutputTestData = nanmean(finalOutputTestData, 3);

% plotting code
[fg,cb] = plotModelData({lat, lon, double(finalOutputTestData)}, plotZone, 'caxis', plotRange);
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

    
