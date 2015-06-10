summer = false;
period = 'future';

if strcmp(period, 'past')
    yearStart = 1981;
    yearEnd = 1999;
elseif strcmp(period, 'future')
    yearStart = 2051;
    yearEnd = 2069;
end

seasonStr = '';
if summer
    months = [6 7 8];
    seasonStr = 'jja';
    tempPercentile = 99;
else
    months = [12 1 2];
    seasonStr = 'djf';
    tempPercentile = 1;
end

yearStep = 1; % the number of years loaded at a time for memory  reasons
minusMean = true;
gridbox = true;

dataset = 'narccap-gcm';

if ~gridbox
    tempLatRange = [40 42];
    tempLonRange = [285 287];
end

if strcmp(dataset, 'narccap-gcm')
    vars = {'narccap/output/ensemble-mean/gcm'};
    plotTitle = ['NARCCAP GCM-driven ensemble mean swe at ', num2str(tempPercentile), ' percentile temperatures, ', num2str(yearStart), '-', num2str(yearEnd)];
    fileTitle = ['sweTempExtremes-', period, '-', seasonStr, '-narccap-gcm-em.png'];
elseif strcmp(dataset, 'narccap-ncep')
    vars = {'narccap/output/ensemble-mean/ncep'};
    plotTitle = ['NARCCAP NCEP-driven ensemble mean swe at ', num2str(tempPercentile), ' percentile temperatures, ', num2str(yearStart), '-', num2str(yearEnd)];
    fileTitle = ['sweTempExtremes-', period, '-', seasonStr, '-narccap-ncep-em.png'];
elseif strcmp(dataset, 'ncep')
    vars = {'ncep-reanalysis/output'};
    plotTitle = ['NCEP swe at ', num2str(tempPercentile), ' percentile temperatures, ', num2str(yearStart), '-', num2str(yearEnd)];
    fileTitle = ['sweTempExtremes-', period, '-', seasonStr, '-ncep.png'];
% elseif strcmp(dataset, 'narr')
%     vars = {'narr/output'};
%     plotTitle = ['NARR swe at ', num2str(tempPercentile), ' percentile temperatures, ', num2str(yearStart), '-', num2str(yearEnd)];
%     fileTitle = ['sweTempExtremes-past-', seasonStr, '-ncep.png'];
end

baseDir = 'e:/';
if length(findstr(vars{1}, 'narccap')) ~= 0
    if summer
        tempVar = 'tasmax';
    else
        tempVar = 'tasmin';
    end
    tempPlev = -1;

    sweVar = 'swe';
    swePlev = -1;
    
    if length(findstr(vars{1}, 'ensemble-mean')) == 0
        isRegridded = true;
    else
        isRegridded = false;
    end
elseif length(findstr(vars{1}, 'narr')) ~= 0
    if summer
        tempVar = 'tasmax';
    else
        tempVar = 'tasmin';
    end
    tempPlev = -1;

    sweVar = 'hgt';
    swePlev = 2;
    
    isRegridded = false;
elseif length(findstr(vars{1}, 'ncep')) ~= 0
    if summer
        tempVar = 'tmax';
    else
        tempVar = 'tmin';
    end
    tempPlev = -1;

    sweVar = 'weasd';
    swePlev = -1;
    
    isRegridded = false;
end

lat = [];
lon = [];
baseGrid = {};

for v = 1:length(vars)
    curModel = vars{v};
    
    dailyTempData = [];
    dailysweData = [];
    
    ['loading ' curModel '...']
    for y = yearStart:yearStep:yearEnd
        ['year ' num2str(y)]
        
        if isRegridded
            tempStr = [baseDir 'data/' vars{v} '/' tempVar '/regrid'];
            sweStr = [baseDir 'data/' vars{v} '/' sweVar '/regrid'];
        else
            tempStr = [baseDir 'data/' vars{v} '/' tempVar];
            sweStr = [baseDir 'data/' vars{v} '/' sweVar];
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
        
        if swePlev ~= -1
            dailyswe = loadDailyData(sweStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', swePlev);
        else
            dailyswe = loadDailyData(sweStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
        end
        
        if length(dailyswe{1}) == 0
            continue;
        end
        
        curDailysweData = dailyswe{3};
        clear dailyswe;
        
        curDailyTempData = curDailyTempData(:,:,:,months,:);
        curDailysweData = curDailysweData(:,:,:,months,:);
        
        if ~gridbox
            curDailyTempData = reshape(curDailyTempData(latIndexRange, lonIndexRange, :, :, :), ...
                                       [length(latIndexRange), ...
                                       length(lonIndexRange), ...
                                       size(curDailyTempData, 3)*size(curDailyTempData,4)*size(curDailyTempData,5)]);
            curDailysweData = reshape(curDailysweData(:, :, :, :, :), ...
                                        [size(curDailysweData, 1), size(curDailysweData, 2), ...
                                         size(curDailysweData, 3)*size(curDailysweData,4)*size(curDailysweData,5)]);
        else
            curDailyTempData = reshape(curDailyTempData, ...
                                       [size(curDailyTempData, 1), size(curDailyTempData, 2), ...
                                       size(curDailyTempData, 3)*size(curDailyTempData,4)*size(curDailyTempData,5)]);
            curDailysweData = reshape(curDailysweData, ...
                                        [size(curDailysweData, 1), size(curDailysweData, 2), ...
                                         size(curDailysweData, 3)*size(curDailysweData,4)*size(curDailysweData,5)]);
        end
        
        dailyTempData = cat(3, dailyTempData, curDailyTempData);
        clear curDailyTempData;
        dailysweData = cat(3, dailysweData, curDailysweData);
        clear curDailysweData;
    end
    
    outputDailySweData = [];
    
    if gridbox
        if size(dailyTempData, 1) == size(dailysweData, 1) & ...
           size(dailyTempData, 2) == size(dailysweData, 2)
            for x = 1:size(dailyTempData, 1)
                for y = 1:size(dailyTempData, 2)
                    dailyTempAvgCutoff = prctile(dailyTempData(x, y, :), tempPercentile);
                    if summer
                        tempInd = find(dailyTempData(x, y, :) >= dailyTempAvgCutoff);
                    else
                        tempInd = find(dailyTempData(x, y, :) <= dailyTempAvgCutoff);
                    end

                    % indices with temperatures < cutoff for calcuating mean zg500
                    notTempInd = 1:size(dailyTempData(x, y, :), 3);
                    notTempInd(tempInd) = [];

                    dailysweMean = nanmean(dailysweData(x,y,notTempInd), 3);
                    if isnan(dailysweMean)
                        dailysweMean = 0;
                    end
                    
                    if minusMean
                        outputDailySweData(x, y) = nanmean(dailysweData(x,y,tempInd), 3)-dailysweMean;
                    else
                        outputDailySweData(x, y) = nanmean(dailysweData(x,y,tempInd), 3);
                    end
                end
            end
        end
    else
        dailyTempAvg = squeeze(nanmean(nanmean(dailyTempData, 2), 1));
        dailyTempAvgCutoff = prctile(dailyTempAvg, tempPercentile);
        if summer
            tempInd = find(dailyTempAvg >= dailyTempAvgCutoff);
        else
            tempInd = find(dailyTempAvg <= dailyTempAvgCutoff);
        end

        % indices with temperatures < cutoff for calcuating mean zg500
        notTempInd = 1:length(dailyTempAvg);
        notTempInd(tempInd) = [];

        dailysweMean = nanmean(dailysweData(:,:,notTempInd), 3);
        if minusMean
            outputDailySweData = nanmean(dailysweData(:,:,tempInd), 3)-dailysweMean;
        else
            outputDailySweData = nanmean(dailysweData(:,:,tempInd), 3);
        end
    end
    
    if strcmp(dataset, 'ncep')
        [fg,cb] = plotModelData({lat, lon, outputDailySweData}, 'north america', 'colormap', 'winter', 'caxis', [-30 30]);
        xlabel(cb, 'kg/m^2', 'FontSize', 18);
    else
        [fg,cb] = plotModelData({lat, lon, outputDailySweData}, 'north america', 'colormap', 'winter', 'caxis', [-5 5]);
        xlabel(cb, 'm', 'FontSize', 18);
    end
    cbPos = get(cb, 'Position');
    title(plotTitle, 'FontSize', 18);
    set(gcf, 'Position', get(0,'Screensize'));
    set(gcf, 'Units', 'normalized');
    set(gca, 'Units', 'normalized');
    
    ti = get(gca,'TightInset');
    set(gca,'Position',[ti(1) cbPos(2) 1-ti(3)-ti(1) 1-ti(4)-cbPos(2)-cbPos(4)]);
    myaa('publish');
    exportfig(fileTitle, 'Width', 16);
    close all;
    
end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

