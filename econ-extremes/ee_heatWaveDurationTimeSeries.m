baseDir = 'e:/';

season = 'summer';
dataset = 'ncep';

yearStart = 1981;
yearEnd = 2012;

% an extreme event is above this threshold
percentileCutoff = 95;

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
    plotRange = [-0.25 0.25];
elseif strcmp(season, 'winter')
    months = [12 1 2];
    plotRange = [-0.5 0.5];
end

fileformat = 'pdf';
fileTitle = ['heatWaveDurationTimeSeries-' season '-' dataset '.' fileformat];
titleStr = [dataset ' ' season ' consec. ', num2str(percentileCutoff), '% events, ' num2str(yearStart) '-' num2str(yearEnd)];

data = [];

yearStep = 1; 
latLimit = [10 11];
lonLimit = [10 11];

lat = [];
lon = [];

tempData = single([]);

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
        
        curData = single(squeeze(daily{3}(latIndexRange, lonIndexRange, :, months, :)));
        clear daily;
        
        if length(tempData) == 0
            tempData = single(ones(size(curData,1), size(curData,2), 93, yearEnd-yearStart+1));
        end
        
        dInd = 1;
        for m = 1:size(curData, 3)
            for d = 1:size(curData, 4)
                for xp = 1:size(curData, 1)
                    for yp = 1:size(curData, 2)                
                        tempData(xp, yp, dInd, y-yearStart+1) = curData(xp,yp,m,d);
                    end
                end
                dInd = dInd+1;
            end
        end
        
        clear curData;
    end
end

tempCutoffs = [];
for xp = 1:size(tempData, 1)
    for yp = 1:size(tempData, 2)
        p = prctile(tempData(xp, yp, :), percentileCutoff);
        tempCutoffs(xp, yp) = p;
    end
end

exceedLength = zeros(size(tempCutoffs,1), size(tempCutoffs,2), size(tempData,4));
for xp = 1:size(tempData, 1)
    for yp = 1:size(tempData, 2)
        for year = 1:size(tempData, 4)
            curCnt = 0;
            for d = 1:size(tempData, 3)
                if tempData(xp,yp,d,year) >= tempCutoffs(xp,yp)
                    curCnt = curCnt+1;
                else
                    if curCnt > exceedLength(xp,yp,year)
                        exceedLength(xp,yp,year) = curCnt;
                    end
                    curCnt = 0;
                end
            end
        end
    end
end

x = yearStart:yearEnd;
y = squeeze(nanmean(nanmean(exceedLength, 2), 1))';

figure('Color', [1,1,1]);
hold on;

plot(x, y, 'k', 'LineWidth', 2);

coeffs = polyfit(x, y, 1);
yFit = polyval(coeffs, x);

plot(x, yFit, 'r');

xlabel('# days above 95th percentile / year', 'FontSize', 20);
title(titleStr, 'FontSize', 20);
set(gcf, 'Position', get(0,'Screensize'));
eval(['export_fig ' fileTitle ';']);
close all;

