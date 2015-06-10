baseDir = 'e:/';

dataset = 'ncep';

yearStart = 1985;
yearEnd = 2005;

% an extreme event is above this threshold
percentileCutoff = 90;

trendOrMedian = 'median';

if strcmp(dataset, 'ncep')
    vars = {'ncep-reanalysis/output/tmax'};
end

months = 1:12;
blockWater = true;
plotRegion = 'west africa';

if strcmp(trendOrMedian, 'trend')
    plotRange = [-0.25 0.25];
    plotXUnits = ['# days above ' num2str(percentileCutoff) 'th percentile / year'];
elseif strcmp(trendOrMedian, 'median')
    plotRange = [0 20];
    plotXUnits = ['median # consec. days above ' num2str(percentileCutoff) 'th percentile'];
end

fileformat = 'pdf';
fileTitle = ['heatWaveDuration-' dataset '-' num2str(percentileCutoff) '-' trendOrMedian '.' fileformat];

data = [];

yearStep = 1; 
latLimit = [0 30];
lonLimit = [340 40];

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
        
        curData = single(daily{3}(latIndexRange, lonIndexRange, :, months, :));
        clear daily;
        
        if length(tempData) == 0
            tempData = single(ones(size(curData,1), size(curData,2), 93, yearEnd-yearStart+1));
        end
        
        dInd = 1;
        for m = 1:size(curData, 4)
            for d = 1:size(curData, 5)
                for xp = 1:size(curData, 1)
                    for yp = 1:size(curData, 2)                
                        tempData(xp, yp, dInd, y-yearStart+1) = curData(xp,yp,1,m,d);
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

if strcmp(trendOrMedian, 'trend')
% regressions for each point
result = [];
for x=1:size(exceedLength, 1)
    for y=1:size(exceedLength, 2)
        
        % regression
        boxTrend = squeeze(exceedLength(x,y,:));
        boxTrend(isnan(boxTrend)) = [];
        
        if length(boxTrend) >= 1
            rx = 1:length(boxTrend);
            mdl = fit(rx', boxTrend, 'poly1');
            result(x,y) = mdl.p1;
        else
            result(x,y) = NaN;
        end
    end
end
elseif strcmp(trendOrMedian, 'median')
    result = nanmedian(exceedLength, 3);
end

result = {lat, lon, result};

plotTitle = ['NCEP consec. days above 90th % [1985-2005]'];

saveData = struct('data', {result}, ...
                  'plotRegion', plotRegion, ...
                  'plotRange', plotRange, ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'plotXUnits', plotXUnits, ...
                  'blockWater', blockWater);

plotFromDataFile(saveData);

