% summer average zg500-temp correlation

% run the correlation year-by-year to conserve memory (used for NARR)
corrFirst = false;
summer = true;

yearStart = 1981;
yearEnd = 1999;
seasonStr = '';
if summer
    months = [6 7 8];
    seasonStr = 'jja';
    tempPercentiles = 98;
else
    months = [12 1 2];
    seasonStr = 'djf';
    tempPercentiles = 2;
end

yearStep = 1; % the number of years loaded at a time for memory  reasons
dataset = 'narccap';

if strcmp(dataset, 'narccap')
    vars = {'narccap/output/ensemble-mean'};
    plotTitle = ['NARCCAP GCM-driven ensemble mean zg500-temp corr at ', num2str(tempPercentiles), ' percentile temperatures'];
    fileTitle = ['zg500TempCorr-past-', seasonStr, '-narccap-gcm-em.png'];
elseif strcmp(dataset, 'narccap-ncep')
    vars = {'narccap/output/ensemble-mean'};
    plotTitle = ['NARCCAP NCEP-driven ensemble mean zg500-temp corr at ', num2str(tempPercentiles), ' percentile temperatures'];
    fileTitle = ['zg500TempCorr-past-', seasonStr, '-narccap-ncep-em.png'];
elseif strcmp(dataset, 'ncep')
    vars = {'ncep-reanalysis/output'};
    plotTitle = ['NCEP zg500-temp corr at ', num2str(tempPercentiles), ' percentile temperatures'];
    fileTitle = ['zg500TempCorr-past-', seasonStr, '-ncep.png'];
elseif strcmp(dataset, 'narr')
    vars = {'narr/output'};
    plotTitle = ['NARR zg500-temp corr at ', num2str(tempPercentiles), ' percentile temperatures'];
    fileTitle = ['zg500TempCorr-past-', seasonStr, '-narr.png'];
end

baseDir = 'e:/';
if length(findstr(vars{1}, 'narccap')) ~= 0
    if summer
        tempVar = 'tasmax';
    else
        tempVar = 'tasmin';
    end
    tempPlev = -1;

    zg500Var = 'zg500';
    zg500Plev = -1;
    
    if length(findstr(vars{1}, 'ensemble-mean')) == 0
        isTempRegridded = true;
        isZg500Regridded = true;
    else
        isZg500Regridded = false;
        isTempRegridded = false;
    end
elseif length(findstr(vars{1}, 'narr')) ~= 0
    if summer
        tempVar = 'tasmax';
    else
        tempVar = 'tasmin';
    end
    tempPlev = -1;

    zg500Var = 'hgt';
    zg500Plev = 2;
    
    isTempRegridded = false;
    isZg500Regridded = false;
elseif length(findstr(vars{1}, 'ncep')) ~= 0
    if summer
        tempVar = 'tmax';
    else
        tempVar = 'tmin';
    end
    tempPlev = -1;

    zg500Var = 'hgt';
    zg500Plev = -1;
    
    isTempRegridded = false;
    isZg500Regridded = true;
end

corrData = [];
varIndex = 1;

lat = [];
lon = [];
baseGrid = {};

tempLatRange = [40 42];
tempLonRange = [285 287];

for v = 1:length(vars)
    curModel = vars{v};
    if ~corrFirst
        tempModelData = [];
        zg500ModelData = [];
    end
    
    ['loading ' curModel '...']
    for y = yearStart:yearStep:yearEnd
        ['year ' num2str(y)]
        
        if isTempRegridded
            tempStr = [baseDir 'data/' vars{v} '/' tempVar '/regrid'];
        else
            tempStr = [baseDir 'data/' vars{v} '/' tempVar];
        end
        
        if isZg500Regridded
            zg500Str = [baseDir 'data/' vars{v} '/' zg500Var '/regrid'];
        else
            zg500Str = [baseDir 'data/' vars{v} '/' zg500Var];
        end
        
        if tempPlev ~= -1
            dailyTemp = loadDailyData(tempStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', tempPlev);
        else
            dailyTemp = loadDailyData(tempStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
        end
        
        if zg500Plev ~= -1
            dailyZg500 = loadDailyData(zg500Str, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', zg500Plev);
        else
            dailyZg500 = loadDailyData(zg500Str, 'yearStart', y, 'yearEnd', y+(yearStep-1));
        end
        
        if length(lat) == 0 | length(lon) == 0
            lat = dailyTemp{1};
            lon = dailyTemp{2};
        end
        
        if length(dailyTemp{1}) == 0 | length(dailyZg500{1}) == 0
            continue;
        end
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(dailyTemp, [tempLatRange(1) tempLatRange(2)], ...
                                                                      [tempLonRange(1) tempLonRange(2)]);
        
        % get daily pt data
        dailyTempData = single(dailyTemp{3});
        dailyTempData = dailyTempData(:,:,:,months,:);
        dailyTempData = reshape(dailyTempData, [size(dailyTempData, 1), size(dailyTempData, 2), ...
                                                size(dailyTempData, 3)*size(dailyTempData, 4)*size(dailyTempData,5)]);
                                            
        curTempModelData = squeeze(nanmean(nanmean(dailyTempData(latIndexRange, lonIndexRange, :), 1), 2));
        
        dailyZg500Data = single(dailyZg500{3});
        dailyZg500Data = dailyZg500Data(:,:,:,months,:);
        dailyZg500Data = reshape(dailyZg500Data, [size(dailyZg500Data, 1), size(dailyZg500Data, 2), ...
                                                size(dailyZg500Data, 3)*size(dailyZg500Data, 4)*size(dailyZg500Data,5)]);
        
        curZg500ModelData = dailyZg500Data(:,:,1:min(size(dailyTempData, 3), size(dailyZg500Data, 3)));
        curTempModelData = curTempModelData(1:size(curZg500ModelData,3));
        
        tempPercentileCutoffs = prctile(curTempModelData, [tempPercentiles]);
        
        if corrFirst
            ['correlating...']
            for p=1:length(tempPercentileCutoffs)
                for xCoord=1:size(curZg500ModelData,1)
                    for yCoord=1:size(curZg500ModelData,2)

                        ind = find((~isnan(curTempModelData(:)) & curTempModelData(:) >= tempPercentileCutoffs(p)) & ~isnan(squeeze(curZg500ModelData(xCoord,yCoord,:))));

                        if length(ind) > 2
                            corrData(xCoord,yCoord,v,p,y-yearStart+1) = corr(curTempModelData(ind), squeeze(curZg500ModelData(xCoord,yCoord,ind)));
                        else
                            corrData(xCoord,yCoord,v,p,y-yearStart+1) = NaN;
                        end

                        clear ind;
                    end
                end
            end
        else
            zg500ModelData = cat(3, zg500ModelData, curZg500ModelData);
            tempModelData = [tempModelData; curTempModelData];
        end
        clear  dailyTemp dailyTempData dailyZg500 dailyZg500Data curZg500ModelData curTempModelData;
    end
    
    if ~corrFirst
        ['correlating...']
        for p=1:length(tempPercentileCutoffs)
            for xCoord=1:size(zg500ModelData,1)
                for yCoord=1:size(zg500ModelData,2)
                    ind = find((~isnan(tempModelData(:)) & tempModelData(:) >= tempPercentileCutoffs(p)) & ~isnan(squeeze(zg500ModelData(xCoord,yCoord,:))));

                    if length(ind) > 2
                        corrData(xCoord,yCoord,v,p) = corr(tempModelData(ind), squeeze(zg500ModelData(xCoord,yCoord,ind)));
                    else
                        corrData(xCoord,yCoord,v,p) = NaN;
                    end

                    clear ind;
                end
            end
        end
        clear zg500ModelData tempModelData;
    end
end

if corrFirst
    corrData = {lat, lon, squeeze(nanmean(nanmean(corrData,5),3))};
else
    corrData = {lat, lon, squeeze(nanmean(corrData,3))};
end

for p=1:length(tempPercentiles)
    corrLat = corrData{1};
    corrLon = corrData{2};
    corrCurData = corrData{3};
    plotModelData({corrLat, corrLon, squeeze(corrCurData(:,:,p))}, 'north america', 'caxis', [-1, 1]);
    title(plotTitle, 'FontSize', 20);
    set(gcf, 'Position', get(0,'Screensize'));
    myaa('publish');
    exportfig(fileTitle, 'Width', 16, 'Color', 'rgb');
    close all;
end


