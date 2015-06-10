% Plots number of days above 95th percentile temperatures in base period
% and in a future period. Currently uses NARCCAP ensemble mean (base +
% future), NCEP reanalyis (base), and NARR (base).

airportDb = loadAirportDb('airports.dat');
[code, phxLat, phxLon] = searchAirportDb(airportDb, 'DEN');

obsAirports = {'PHX', 'LGA', 'DCA', 'DEN'};
obsPeriods = {1981:2011, 1981:2011, 1981:2011, 1996:2011};

basePeriod = 1981:1999;
futurePeriod = 2051:2069;
months = [6 7 8];
yearStep = 1; % the number of years loaded at a time for memory  reasons
tempPercentile = 95;
summerLength = 92;

obsDir = 'e:/data/flight/wx/output/daily/tasmax';
% the next three variables must match up sequentially
vars = {'narccap/output/ensemble-mean/gcm', 'ncep-reanalysis/output', 'narr/output', 'narccap/output/ensemble-mean/gcm'};
varPeriods = {basePeriod, 1981:2012, 1981:2012, futurePeriod};
plotColors = {'c', 'b', 'g', 'r'};

cutoffTemps = [];

% can modify these
plotTitle = [code, ' summer days above 1981-1999 ', num2str(tempPercentile), 'th percentile'];
fileTitle = ['compareAirportTemps-', code, '-jja-', num2str(tempPercentile),'.png'];

baseDir = 'e:/';
baseHotDayAnom = {};
narccapBaseCutoff = -1;

for v = 1:length(vars)
    curModel = vars{v};
    
    if length(findstr(curModel, 'narccap')) ~= 0
        tempVar = 'tasmax';
        tempPlev = -1;

        if length(findstr(curModel, 'ensemble-mean')) == 0
            isRegridded = true;
        else
            isRegridded = false;
        end
    elseif length(findstr(curModel, 'narr')) ~= 0
        tempVar = 'tasmax';
        tempPlev = -1;

        isRegridded = false;
    elseif length(findstr(curModel, 'ncep')) ~= 0
        tempVar = 'tmax';
        tempPlev = -1;

        isRegridded = false;
    end

    dailyTempData = [];
    
    ['loading ' curModel '...']
    for y = varPeriods{v}(1):yearStep:varPeriods{v}(end)
        ['year ' num2str(y)]
        
        if isRegridded
            tempStr = [baseDir 'data/' vars{v} '/' tempVar '/regrid'];
        else
            tempStr = [baseDir 'data/' vars{v} '/' tempVar];
        end
        
        if tempPlev ~= -1
            dailyTemp = loadDailyData(tempStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', tempPlev);
        else
            dailyTemp = loadDailyData(tempStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
        end
        
        if length(dailyTemp{1}) == 0
            continue;
        end
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(dailyTemp, [phxLat phxLat], [phxLon phxLon]);
        
        curDailyTempData = dailyTemp{3};
        clear dailyTemp;
        
        curDailyTempData = curDailyTempData(:,:,:,months,:);
        curDailyTempData = reshape(curDailyTempData(latIndexRange, lonIndexRange, :, :, :), ...
                                   [length(latIndexRange), length(lonIndexRange), ...
                                    size(curDailyTempData, 3), size(curDailyTempData,4)*size(curDailyTempData,5)]);
        
        dailyTempData = cat(3, dailyTempData, curDailyTempData);
        clear curDailyTempData;
    end
    dailyTempData = squeeze(dailyTempData);
    dailyTempDataLinear = squeeze(reshape(dailyTempData(1:19,:), [size(dailyTempData(1:19,:), 1)*size(dailyTempData(1:19,:), 2), 1]));
    
    if length(findstr(curModel, 'narccap')) ~= 0 & varPeriods{v} == futurePeriod
        baseTempCutoff = narccapBaseCutoff;
        cutoffTemps(end+1) = baseTempCutoff;
    else
        baseTempCutoff = prctile(dailyTempDataLinear, tempPercentile);
        cutoffTemps(end+1) = baseTempCutoff;
    end
    
    if length(findstr(curModel, 'narccap')) ~= 0 & varPeriods{v} == basePeriod
        narccapBaseCutoff = baseTempCutoff;
    end
    
    baseHotDayAnom{v} = [];
    for y = 1:size(dailyTempData, 1)
        baseHotDayAnom{v} = [baseHotDayAnom{v} length(find(dailyTempData(y,:) >= baseTempCutoff))];
    end
    clear dailyTempData dailyTempDataLinear;
end

% now load the obs at the end
obsStart = obsPeriods{find(strcmp(obsAirports, code))}(1);
obsEnd = obsPeriods{find(strcmp(obsAirports, code))}(end);
obsData = loadDailyData(obsDir, 'yearStart', obsStart, 'yearEnd', obsEnd, 'obs', 'daily', 'obsAirport', code);
obsData = obsData(:, months, :);

obsDataLinRef = reshape(obsData(1:1999-obsStart+1, :, :), [(1999-obsStart+1)*size(obsData,2)*size(obsData,3), 1]);
obsCutoff = prctile(obsDataLinRef, tempPercentile);
cutoffTemps(end+1) = obsCutoff;

obsHotDayAnom = [];
for y = 1:size(obsData,1)
    obsHotDayAnom(y) = length(find(reshape(permute(obsData(y, :, :), [1 3 2]), [1*size(obsData,2)*size(obsData,3), 1]) >= obsCutoff));
end

figure('Color', [1,1,1]);
hold on;
legendText = '';

for v = 1:length(baseHotDayAnom)
    plot(varPeriods{v}, baseHotDayAnom{v}, plotColors{v}, 'LineWidth', 2);
    legendText = [legendText, '''', vars{v}, ''''];
    if v < length(vars)
        legendText = [legendText, ','];
    end
end

% plot observations
plot(obsStart:obsEnd, obsHotDayAnom, 'k', 'LineWidth', 2);
legendText = [legendText, ',''ground observations'''];

% plot expected occurance line
plotLim = get(gca, 'xlim');
plot(plotLim, [(1-(tempPercentile/100.0))*summerLength (1-(tempPercentile/100.0))*summerLength], '--k', 'LineWidth', 1);
legendText = [legendText, ',''expected occurance'''];

title(plotTitle, 'FontSize', 18);
xlabel('year', 'FontSize', 18);
ylabel('# days', 'FontSize', 18);
eval(['l = legend(', legendText, ');']);
set(gcf, 'Position', get(0,'Screensize'));
set(l, 'FontSize', 18, 'Location', 'best');

myaa('publish');
exportfig(fileTitle, 'Width', 16);
close all;
