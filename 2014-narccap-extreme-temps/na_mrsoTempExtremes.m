summer = true;
period = 'past';

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

dataset = 'narr';

if ~gridbox
    tempLatRange = [40 42];
    tempLonRange = [285 287];
end

if strcmp(dataset, 'narccap-gcm')
    vars = {'narccap/output/ensemble-mean/gcm'};
    plotTitle = ['NARCCAP GCM-driven ensemble mean mrso at ', num2str(tempPercentile), ' percentile temperatures, ', num2str(yearStart), '-', num2str(yearEnd)];
    fileTitle = ['mrsoTempExtremes-', period, '-', seasonStr, '-narccap-gcm-em.png'];
elseif strcmp(dataset, 'narccap-ncep')
    vars = {'narccap/output/ensemble-mean/ncep'};
    plotTitle = ['NARCCAP NCEP-driven ensemble mean mrso at ', num2str(tempPercentile), ' percentile temperatures, ', num2str(yearStart), '-', num2str(yearEnd)];
    fileTitle = ['mrsoTempExtremes-', period, '-', seasonStr, '-narccap-ncep-em.png'];
elseif strcmp(dataset, 'ncep')
    vars = {'ncep-reanalysis/output'};
    plotTitle = ['NCEP mrso at ', num2str(tempPercentile), ' percentile temperatures, ', num2str(yearStart), '-', num2str(yearEnd)];
    fileTitle = ['mrsoTempExtremes-', period, '-', seasonStr, '-ncep.png'];
% elseif strcmp(dataset, 'narr')
%     vars = {'narr/output'};
%     plotTitle = ['NARR mrso at ', num2str(tempPercentile), ' percentile temperatures, ', num2str(yearStart), '-', num2str(yearEnd)];
%     fileTitle = ['mrsoTempExtremes-past-', seasonStr, '-ncep.png'];
end

baseDir = 'e:/';
if length(findstr(vars{1}, 'narccap')) ~= 0
    if summer
        tempVar = 'tasmax';
    else
        tempVar = 'tasmin';
    end
    tempPlev = -1;

    mrsoVar = 'mrso';
    mrsoPlev = -1;
    
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

    mrsoVar = 'hgt';
    mrsoPlev = 2;
    
    isRegridded = false;
elseif length(findstr(vars{1}, 'ncep')) ~= 0
    if summer
        tempVar = 'tmax';
    else
        tempVar = 'tmin';
    end
    tempPlev = -1;

    mrsoVar = 'soilw';
    mrsoPlev = -1;
    
    isRegridded = false;
end

lat = [];
lon = [];
baseGrid = {};



for v = 1:length(vars)
    curModel = vars{v};
    
    dailyTempData = [];
    dailyMrsoData = [];
    
    ['loading ' curModel '...']
    for y = yearStart:yearStep:yearEnd
        ['year ' num2str(y)]
        
        if isRegridded
            tempStr = [baseDir 'data/' vars{v} '/' tempVar '/regrid'];
            mrsoStr = [baseDir 'data/' vars{v} '/' mrsoVar '/regrid'];
        else
            tempStr = [baseDir 'data/' vars{v} '/' tempVar];
            mrsoStr = [baseDir 'data/' vars{v} '/' mrsoVar];
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
        
        if mrsoPlev ~= -1
            dailyMrso = loadDailyData(mrsoStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', mrsoPlev);
        else
            dailyMrso = loadDailyData(mrsoStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
        end
        
        if length(dailyMrso{1}) == 0
            continue;
        end
        
        curDailyMrsoData = dailyMrso{3};
        clear dailyMrso;
        
        curDailyTempData = curDailyTempData(:,:,:,months,:);
        curDailyMrsoData = curDailyMrsoData(:,:,:,months,:);
        
        if ~gridbox
            curDailyTempData = reshape(curDailyTempData(latIndexRange, lonIndexRange, :, :, :), ...
                                       [length(latIndexRange), ...
                                       length(lonIndexRange), ...
                                       size(curDailyTempData, 3)*size(curDailyTempData,4)*size(curDailyTempData,5)]);
            curDailyMrsoData = reshape(curDailyMrsoData(:, :, :, :, :), ...
                                        [size(curDailyMrsoData, 1), size(curDailyMrsoData, 2), ...
                                         size(curDailyMrsoData, 3)*size(curDailyMrsoData,4)*size(curDailyMrsoData,5)]);
        else
            curDailyTempData = reshape(curDailyTempData, ...
                                   [size(curDailyTempData, 1), size(curDailyTempData, 2), ...
                                   size(curDailyTempData, 3)*size(curDailyTempData,4)*size(curDailyTempData,5)]);
            curDailyMrsoData = reshape(curDailyMrsoData, ...
                                    [size(curDailyMrsoData, 1), size(curDailyMrsoData, 2), ...
                                     size(curDailyMrsoData, 3)*size(curDailyMrsoData,4)*size(curDailyMrsoData,5)]);
        end
        
        dailyTempData = cat(3, dailyTempData, curDailyTempData);
        clear curDailyTempData;
        dailyMrsoData = cat(3, dailyMrsoData, curDailyMrsoData);
        clear curDailyMrsoData;
    end
    
    outputDailyMrsoData = [];
    
    if gridbox
        if size(dailyTempData, 1) == size(dailyMrsoData, 1) & ...
           size(dailyTempData, 2) == size(dailyMrsoData, 2)
            for x = 1:size(dailyTempData, 1)
                for y = 1:size(dailyTempData, 2)
                    gridboxTempAvgCutoff = prctile(dailyTempData(x, y, :), tempPercentile);
                    if summer
                        tempInd = find(dailyTempData(x, y, :) >= gridboxTempAvgCutoff);
                    else
                        tempInd = find(dailyTempData(x, y, :) <= gridboxTempAvgCutoff);
                    end
                    
                    % indices with temperatures < cutoff for calcuating mean zg500
                    notTempInd = 1:size(dailyTempData(x, y, :), 3);
                    notTempInd(tempInd) = [];
                    
                    if strcmp(dataset, 'narccap-gcm') | strcmp(dataset, 'narccap-ncep')
                        dailyMrsoData(x, y, :) = dailyMrsoData(x, y, :) ./ nanmax(dailyMrsoData(x, y, :), [], 3);
                    end
                    
                    dailyMrsoMean = nanmean(dailyMrsoData(x,y,notTempInd), 3);
                    
                    if minusMean
                        outputDailyMrsoData(x, y) = nanmean(dailyMrsoData(x, y, tempInd), 3) - dailyMrsoMean;
                    else
                        outputDailyMrsoData(x, y) = nanmean(dailyMrsoData(x, y, tempInd), 3);
                    end
                end
            end
        else
            ['bad regridding']
            break;
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

        % compute soil moisture fraction for narccap
        if strcmp(dataset, 'narccap-gcm') | strcmp(dataset, 'narccap-ncep')
            dailyMrsoData = dailyMrsoData ./ nanmax(nanmax(nanmax(dailyMrsoData, [], 3), [], 2), [], 1);
        end

        dailyMrsoMean = nanmean(dailyMrsoData(:,:,notTempInd), 3);
        if minusMean
            outputDailyMrsoData = nanmean(dailyMrsoData(:,:,tempInd), 3)-dailyMrsoMean;
        else
            outputDailyMrsoData = nanmean(dailyMrsoData(:,:,tempInd), 3);%-dailyZg500Mean;
        end
    end
    
    [fg,cb] = plotModelData({lat, lon, outputDailyMrsoData}, 'north america', 'caxis', [-0.151 0.15]);
    xlabel(cb, 'fraction', 'FontSize', 18);
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
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

