baseDir = 'e:/';

% 'max', 'min', 'mean', or 'all'
calcMethod = 'max';
season = 'summer';
dataset = 'ncep';

yearStart = 1981;
yearEnd = 2012;

%vars = {'narr/output/tasmax'};
%vars = {'narccap/output/ensemble-mean/gcm/swe'};
%vars = {'narr/output/tasmax'};

if strcmp(dataset, 'ncep')
    if strcmp(season, 'summer')
        vars = {'ncep-reanalysis/output/tmax'};
    elseif strcmp(season, 'winter')
        vars = {'ncep-reanalysis/output/tmin'};
    end
elseif strcmp(dataset, 'narr')
    if strcmp(season, 'summer')
        vars = {'narr/output/tasmax'};
    elseif strcmp(season, 'winter')
        vars = {'narr/output/tasmin'};
    end
end

if strcmp(season, 'summer')
    months = [6 7 8];
    plotRange = [-0.15 0.15];
elseif strcmp(season, 'winter')
    months = [12 1 2];
    plotRange = [-0.5 0.5];
end

fileformat = 'pdf';
fileTitle = ['extremesPointRegression-' season '-' dataset '-' calcMethod '.' fileformat];
titleStr = [dataset ' ' season ' ' calcMethod ' regression slopes, ' num2str(yearStart) '-' num2str(yearEnd)];

data = [];

yearStep = 1; 
latLimit = [-60 60];
lonLimit = [0 360];

lat = [];
lon = [];

for v = 1:length(vars)
    curModelDir = [baseDir 'data/' vars{v}];
    curDataMax = [];
    
    ['loading ' curModelDir]
    for y = yearStart:yearStep:yearEnd
        ['year ' num2str(y)]
        daily = loadDailyData(curModelDir, 'yearStart', y, 'yearEnd', y+(yearStep-1));
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(daily, latLimit, lonLimit);
        
        if length(lat) == 0
            lat = daily{1}(latIndexRange, lonIndexRange);
            lon = daily{2}(latIndexRange, lonIndexRange);
        end
        
        curData = daily{3}(latIndexRange, lonIndexRange, :, months, :);
        
        if strcmp(calcMethod, 'max')
            tempData = [];
            i = 1;
            for m = 1:size(curData,4)
                for d = 1:size(curData,5)
                    tempData(:,:,i) = curData(:,:,1,m,d);
                    i = i+1;
                end
            end
            data(:,:,y-yearStart+1) = nanmax(tempData, [], 3);
            clear tempData;
        elseif strcmp(calcMethod, 'min')
            tempData = [];
            i = 1;
            for m = 1:size(curData,4)
                for d = 1:size(curData,5)
                    tempData(:,:,i) = curData(:,:,1,m,d);
                    i = i+1;
                end
            end
            data(:,:,y-yearStart+1) = nanmin(tempData, [], 3);
            clear tempData;
        elseif strcmp(calcMethod, 'mean')
            tempData = [];
            i = 1;
            for m = 1:size(curData,4)
                for d = 1:size(curData,5)
                    tempData(:,:,i) = curData(:,:,1,m,d);
                    i = i+1;
                end
            end
            data(:,:,y-yearStart+1) = nanmean(tempData, 3);
            clear tempData;
        elseif strcmp(calcMethod, 'all')
            i = 1;
            for m = 1:size(curData,4)
                for d = 1:size(curData,5)
                    data(:,:,y-yearStart+1,v,i) = curData(:,:,1,m,d);
                    i = i+1;
                end
            end
        end
        
        clear daily curData;
    end
end

% regressions for each point
regSlopes = [];
for x=1:size(data, 1)
    for y=1:size(data, 2)
        
        % regression
        boxTrend = squeeze(data(x,y,:));
        boxTrend(isnan(boxTrend)) = [];
        
        if length(boxTrend) >= 10
            rx = 1:length(boxTrend);
            mdl = fit(rx', boxTrend, 'poly1');
            regSlopes(x,y) = mdl.p1;
        else
            regSlopes(x,y) = NaN;
        end
    end
end

regSlopes = {lat, lon, regSlopes};

[fg,cb] = plotModelData(regSlopes, 'usa-exp', 'caxis', plotRange);
xlabel(cb, 'degrees C / year', 'FontSize', 20);
title(titleStr, 'FontSize', 20);
set(gcf, 'Position', get(0,'Screensize'));
eval(['export_fig ' fileTitle ';']);
close all;

