% Updated 3/6/14 
% Plots 95th percentile temperatures from models (NARCCAP +
% CMIP5) for base and future periods and for observations (airport 5-min
% ASOS). Also computes correction factor between each model and
% observations, and plots corrected model temperatures for base and future
% periods.

airportDb = loadAirportDb('airports.dat');
[code, airportLat, airportLon] = searchAirportDb(airportDb, 'DEN');

obsAirports = {'PHX', 'LGA', 'DCA', 'DEN'};
obsPeriods = {1981:1999, 1981:1999, 1981:1999, 1996:1999};

basePeriod = 1981:1999;
futurePeriod = 2051:2069;
months = [6 7 8];
yearStep = 1;
tempPercentile = 95;

obsDir = 'e:/data/flight/wx/output/daily/tasmax';

% must be arranged such that any future periods comes directly after the
% corresponding base period
vars = {'narccap/output/ensemble-mean/gcm', 'narccap/output/ensemble-mean/gcm', ...
        'cmip5/output/gfdl-cm3/r1i1p1/historical', 'cmip5/output/gfdl-cm3/r1i1p1/rcp85'};
varPeriods = {basePeriod, futurePeriod, basePeriod, futurePeriod};
plotColors = {'b', 'r', 'g', 'm'};
cutoffTemps = [];
plotTitle = [code, ' ', num2str(tempPercentile), 'th percentile temperatures'];
fileTitle = ['airportTempsCorrected-', code, '.png'];

baseDir = 'e:/';
yearlyTempUncorr = {};
yearlyTempCorr = {};
yearlyTempObs = {};

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
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(dailyTemp, [airportLat airportLat], [airportLon airportLon]);
        
        curDailyTempData = dailyTemp{3};
        clear dailyTemp;
        
        curDailyTempData = curDailyTempData(:,:,:,months,:);
        curDailyTempData = reshape(curDailyTempData(latIndexRange, lonIndexRange, :, :, :), ...
                                   [length(latIndexRange), length(lonIndexRange), ...
                                    size(curDailyTempData, 3), size(curDailyTempData,4)*size(curDailyTempData,5)]);
        if length(yearlyTempUncorr) < v
            yearlyTempUncorr{v} = [];
        end
        yearlyTempUncorr{v} = [yearlyTempUncorr{v}; prctile(squeeze(curDailyTempData), tempPercentile)-273.15];
                                
        dailyTempData = cat(3, dailyTempData, curDailyTempData);
        clear curDailyTempData;
    end
    dailyTempData = squeeze(dailyTempData);
    dailyTempDataLinear = squeeze(reshape(dailyTempData(1:19,:), [size(dailyTempData(1:19,:), 1)*size(dailyTempData(1:19,:), 2), 1]));
    
    clear dailyTempData dailyTempDataLinear;
end

% now load the obs at the end
obsStart = obsPeriods{find(strcmp(obsAirports, code))}(1);
obsEnd = obsPeriods{find(strcmp(obsAirports, code))}(end);
obsData = loadDailyData(obsDir, 'yearStart', obsStart, 'yearEnd', obsEnd, 'obs', 'daily', 'obsAirport', code);
obsData = obsData(:, months, :);

yearlyTempObs{1} = [];
for y = 1:size(obsData, 1)
    yearlyTempObs{1} = [yearlyTempObs{1}; prctile(reshape(permute(obsData(y, :, :), [1 3 2]), [size(obsData, 2)*size(obsData, 3), 1]), tempPercentile)];
end
curObsPeriod = obsPeriods{find(strcmp(obsAirports, code))};

corrVal = 0;
for v = 1:length(vars)
    if varPeriods{v} == basePeriod
        corrVal = mean(yearlyTempObs{1}(1:min(length(yearlyTempObs{1}), 19))) - mean(yearlyTempUncorr{v}(1:19));
        yearlyTempCorr{v} = yearlyTempUncorr{v} + corrVal;
    elseif varPeriods{v} == futurePeriod
        yearlyTempCorr{v} = yearlyTempUncorr{v} + corrVal;
    end
end

figure('Color', [1, 1, 1]);
hold on;
legendText = '';
for v = 1:length(vars)
    plot(varPeriods{v}, yearlyTempUncorr{v}(1:19), plotColors{v}, 'LineWidth', 2);
    plot(varPeriods{v}, yearlyTempCorr{v}(1:19), ['--' plotColors{v}], 'LineWidth', 2);
    legendText = [legendText, '''', vars{v}, ' uncorrected'','];
    legendText = [legendText, '''', vars{v}, ' corrected'''];
    if v < length(vars)
        legendText = [legendText, ','];
    end
end
plot(curObsPeriod, yearlyTempObs{1}(curObsPeriod-curObsPeriod(1)+1), 'k', 'LineWidth', 2);
legendText = [legendText, ',''ground obs'''];
l = eval(['legend(' legendText ');']);

title(plotTitle, 'FontSize', 18);
xlabel('year', 'FontSize', 18);
ylabel('degrees C', 'FontSize', 18);
set(gcf, 'Position', get(0,'Screensize'));
set(l, 'FontSize', 18, 'Location', 'best');

myaa('publish');
exportfig(fileTitle, 'Width', 16);
close all;




        