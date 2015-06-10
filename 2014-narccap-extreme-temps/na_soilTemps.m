summer = true;
testPeriod = 'future';

% dataset = {'crcm/ccsm', 'hrm3/gfdl'};

% soil moisture
dataset = {'crcm/ccsm', 'crcm/cgcm3', ... %'hrm3/gfdl', 'hrm3/hadcm3', 
          'mm5i/ccsm', ...
          'mm5i/hadcm3', 'rcm3/cgcm3', ...%'rcm3/gfdl', ...
          'wrfg/ccsm'};

% dataset = {'crcm/ccsm', 'crcm/cgcm3', 'ecp2/gfdl', ...
%           'hrm3/gfdl', 'hrm3/hadcm3', 'mm5i/ccsm', ...
%           'mm5i/hadcm3', 'rcm3/cgcm3', 'rcm3/gfdl', ...
%           'wrfg/ccsm', 'wrfg/cgcm3'};
      
%dataset = {'narr'};

% the temperature reference area
region = 'ne';
plotZone = 'north america';
fileformat = 'pdf';
baseDir = 'e:/';

% nyc: 40-42, 285-287
% il: 39-40, 269-271
% az: 33-35, 247-249
if strcmp(region, 'ne')
    tempLatRange = [40 42];
    tempLonRange = [285 287];
elseif strcmp(region, 'nc')
    tempLatRange = [39 41];
    tempLonRange = [269 271];
elseif strcmp(region, 'sw')
    tempLatRange = [33 35];
    tempLonRange = [247 249];
elseif strcmp(region, 'se')
    tempLatRange = [34 36];
    tempLonRange = [266 268];
end

basePeriod = 1981:1998;
futurePeriod = 2051:2069;
seasonLength = -1;

if strcmp(testPeriod, 'past')
    varPeriods = {basePeriod};
elseif strcmp(testPeriod, 'future')
    varPeriods = {futurePeriod};
end

tempPercentile = -1;
seasonStr = '';
if summer
    months = [6 7 8];
    seasonStr = 'jja';
    if tempPercentile == -1
        tempPercentile = 99;
    end
else
    months = [12 1 2];
    seasonStr = 'djf';
    if tempPercentile == -1
        tempPercentile = 1;
    end
end

yearStep = 1;       % the number of years loaded at a time for memory  reasons

soilmRegSlopes = [];
percentiles = 0:5:100;

percentilePlot = true;
mrsoLevels = [];

scatterPlot = true;
fullTemp = [];
fullMrso = [];
soilTempPlots = true;

zeroPrecipDays = [];

for d = 1:length(dataset)
    tempTargetFileStr = '';
    tempTargetPlotStr = '';
    
    if strcmp(dataset{d}, 'narr')
        vars = {'narr/output'};
        modelStr = 'narr';
        curModelStr = 'narr';
        plotTitle = ['NARR soilm and tasmax at ', num2str(tempPercentile), ' percentile temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
        fileTitle = ['uaVaTempExtremes-', testPeriod, '-', seasonStr, '-', num2str(tempPercentile), tempTargetFileStr, '-narr.' fileformat];
    else
        parts = strsplit(dataset{d}, '/');
        modelStr = '';
        if length(dataset) > 1
            modelStr = 'narccap-mm';
        else
            modelStr = [parts{1} '-' parts{2}];
        end
        
        curModelStr = [parts{1} '-' parts{2}];
        vars = {['narccap/output/' dataset{d}]};
        plotTitle = ['NARCCAP ' modelStr ' 850 hPa winds at ', num2str(tempPercentile), ' percentile temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
        fileTitle = ['uaVaTempExtremes-', testPeriod, '-', seasonStr, '-', num2str(tempPercentile), tempTargetFileStr, '-narccap-' modelStr '.' fileformat];   
    end

    lat = [];
    lon = [];

    dailyData = {};

    for v = 1:length(vars)
        
        if length(findstr(vars{1}, 'narccap')) ~= 0            
            if summer
                dataVars = {'tasmax', 'mrso', 'pr'};
            else
                dataVars = {'tasmin', 'mrso', 'pr'};
            end

            varLevels = {-1, -1, -1};
            varRegrid = {true, true, false};
            varMult = {1, 8, 8};
            varMultMethod = {'', 'mean', 'sum'};
        elseif length(findstr(vars{1}, 'narr')) ~= 0
            if summer
                dataVars = {'apcp'};
            else
                dataVars = {'tasmin', 'soilm', 'apcp'};
            end

            varLevels = {-1};
            varRegrid = {false};
            varMult = {1};
            varMultMethod = {''};
        end
        
        if find(strcmp('tasmax', dataVars)) & ...
                (find(strcmp('mrso', dataVars)) | find(strcmp('soilm', dataVars)))
            soilTempPlots = true;
        end
        
        dailyData{v} = {};
        
        for k = 1:length(dataVars)
            dailyData{v}{k} = [];
        end

        ['loading ' vars{v} '...']
        for y = varPeriods{v}(1):yearStep:varPeriods{v}(end)
            ['year ' num2str(y)]

            for k = 1:length(dataVars)
                if varRegrid{k}
                    varStr = [baseDir 'data/' vars{v} '/' dataVars{k} '/regrid'];
                else
                    varStr = [baseDir 'data/' vars{v} '/' dataVars{k}];
                end
                
                if varLevels{k} ~= -1
                    data = loadDailyData(varStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', varLevels{k}, 'mult', varMult{k}, 'multMethod', varMultMethod{k});
                else
                    data = loadDailyData(varStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'mult', varMult{k}, 'multMethod', varMultMethod{k});
                end

                if length(lat) == 0 | length(lon) == 0
                    lat = data{1};
                    lon = data{2};
                end

                if length(data{1}) == 0
                    continue;
                end

                [latIndexRange, lonIndexRange] = latLonIndexRange(data, tempLatRange, tempLonRange);

                curDailyData = data{3};
                clear data;
                
                % select months
                curDailyData = single(curDailyData(latIndexRange,lonIndexRange,:,months,:));

                curDailyDataRe = [];

                % permute to maintain order after reshaping
                for i = 1:size(curDailyData, 1)
                    for j = 1:size(curDailyData, 2)
                        curDailyDataRe(i, j, :) = reshape(permute(squeeze(curDailyData(i, j, :, :, :)), [2 1]), [size(curDailyData, 4)*size(curDailyData, 5), 1]);
                    end
                end

                clear curDailyData;

                if seasonLength == -1
                    seasonLength = size(curDailyDataRe, 3);
                end
                
                curDailyDataRe = nanmean(nanmean(curDailyDataRe, 2), 1);

                dailyData{v}{k} = cat(3, dailyData{v}{k}, curDailyDataRe);
                clear curDailyDataRe;
            end
        end
    end

    
    if length(findstr(vars{1}, 'narccap')) ~= 0
        pr = squeeze(dailyData{1}{3}) .* 3600*24;
    else
        pr = squeeze(dailyData{1}{3});
    end
    
    yearCount = 1;
    for i = 1:seasonLength:length(pr)
        zeroPrecipDays(yearCount, d) = length(find(isnan(pr(i:min(i+seasonLength, length(pr)))) | pr(i:min(i+seasonLength, length(pr))) < 0.15));
        yearCount = yearCount+1;
    end
    
    if soilTempPlots
        temp = squeeze(dailyData{1}{1}) - 273.15;
        mrso = squeeze(dailyData{1}{2});

        temp = temp(1:min(length(temp), length(mrso))) - nanmean(temp);
        mrso = mrso(1:min(length(temp), length(mrso))) - nanmean(mrso);
        nonNanInd = intersect(find(~isnan(temp)), find(~isnan(mrso)));

        figure('Color', [1, 1, 1]);
        hold on;
        plot(temp(nonNanInd), mrso(nonNanInd), 'k.');
        title([dataset{d} ' soil moisture vs temp percentile (' region ')'], 'FontSize', 22);
        xlabel('temperature anomaly (degrees C)', 'FontSize', 20);
        ylabel('soil moisture anomaly (kg/m^2)', 'FontSize', 20);

        p = polyfit(temp(nonNanInd), mrso(nonNanInd), 1);
        plot(linspace(min(temp(nonNanInd)), max(temp(nonNanInd)), length(temp(nonNanInd))), ...
             polyval(p, linspace(min(temp(nonNanInd)), max(temp(nonNanInd)), length(temp(nonNanInd)))), 'm', 'LineWidth', 2);

        xlim([-20 20]);
        ylim([-250 250]);

        set(gcf, 'Position', get(0,'Screensize'));
        drawnow;
        eval(['export_fig soilmTemp_' region '_' curModelStr '_' testPeriod '.pdf;']);
        close all;
        drawnow;

        if percentilePlot
            for p = 1:length(percentiles)
                tp = prctile(temp, percentiles(p));
                ind = find(temp > tp);
                mrsoLevels(p, d) = nanmean(mrso(ind));
            end        
        end

        fullTemp = [fullTemp; temp];
        fullMrso = [fullMrso; mrso];
    end
end

%zeroPrecipDays = nanmean(zeroPrecipDays, 2);

figure('Color', [1, 1, 1]);
hold on;
myMap = hsv(length(dataset));
for d = 1:length(dataset)
    if d == 1
        plot(varPeriods{3}, zeroPrecipDays(:,d)', 'k', 'LineWidth', 2);
    else
        plot(varPeriods{3}, zeroPrecipDays(:,d)', 'Color', myMap(d,:));
    end
end

plot(varPeriods{3}, nanmean(zeroPrecipDays(:, 2:end), 2), 'r', 'LineWidth', 2);

p = polyfit(varPeriods{3}', zeroPrecipDays, 1);
plot(varPeriods{3}, polyval(p, varPeriods{3}), 'm', 'LineWidth', 2);

xlabel('year', 'FontSize', 20);
ylabel('zero precip days', 'FontSize', 20);
title(modelStr, 'FontSize', 20);
set(gcf, 'Position', get(0,'Screensize'));
eval(['export_fig zeroPrecip_' modelStr '_' region '_' testPeriod '.pdf;']);
close all;

if soilTempPlots
    if scatterPlot
        figure('Color', [1, 1, 1]);
        hold on;

        t50 = prctile(fullTemp, 50);
        t90 = prctile(fullTemp, 90);
        t99 = prctile(fullTemp, 99);

        tempInd0 = find(fullTemp<t50);
        tempInd50 = find(fullTemp>=t50 & fullTemp<t90);
        tempInd90 = find(fullTemp>=t90 & fullTemp<t99);
        tempInd99 = find(fullTemp>=t99);

        plot(fullTemp(tempInd0), fullMrso(tempInd0), 'k.');
        plot(fullTemp(tempInd50), fullMrso(tempInd50), 'b.');
        plot(fullTemp(tempInd90), fullMrso(tempInd90), 'g.');
        plot(fullTemp(tempInd99), fullMrso(tempInd99), 'r.');

        ind = intersect(find(~isnan(fullTemp)), find(~isnan(fullMrso)));
        xvals = fullTemp(ind);
        yvals = fullMrso(ind);

        p = polyfit(xvals, yvals, 2);
        plot(linspace(min(xvals), max(xvals), length(xvals)), polyval(p, linspace(min(xvals), max(xvals), length(xvals))), 'm', 'LineWidth', 2);

        xlim(gca, [-20 20]);%min(xvals)-0.5 max(xvals)+0.5])
        ylim(gca, [-250 250]);%min(yvals)-10 max(yvals)+10]);

        xlabel('temperature (degrees C)', 'FontSize', 20);
        ylabel('soil moisture (kg/m^2)', 'FontSize', 20);
        title(['temp vs. soil moisture (' region ')'], 'FontSize', 20);
        set(gcf, 'Position', get(0,'Screensize'));
        eval(['export_fig soilmTempScatter_' region '_' modelStr '_' testPeriod '.pdf;']);
    end

    mrsoLevels = nanmean(mrsoLevels, 2);
    if percentilePlot
        figure('Color', [1,1,1]);
        plot(percentiles, mrsoLevels, 'k', 'LineWidth', 2);
        title(['soil moisture vs temp percentile (' region ')'], 'FontSize', 22);
        xlabel('temperature percentile', 'FontSize', 20);
        ylabel('soil moisture anomaly (kg/m^2)', 'FontSize', 20);
        ylim([-150 0]);
        set(gcf, 'Position', get(0,'Screensize'));
        eval(['export_fig soilmTemp_' region '_' modelStr '_' testPeriod '.pdf;']);
    end
end

close all;


