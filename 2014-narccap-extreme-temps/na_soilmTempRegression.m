summer = true;
testPeriod = 'past';

dataset = {'crcm/ccsm', 'crcm/cgcm3', ...
          'hrm3/gfdl', 'hrm3/hadcm3', 'mm5i/ccsm', ...
          'mm5i/hadcm3', 'rcm3/cgcm3', 'rcm3/gfdl', ...
          'wrfg/ccsm'};

%dataset = {'narr'};

% the temperature reference area
region = 'ne';
plotZone = 'north america';
fileformat = 'pdf';
baseDir = 'e:/';

tempLatRange = [20 50];
tempLonRange = [230 310];

basePeriod = 1981:1998;
futurePeriod = 2051:2069;

if strcmp(testPeriod, 'past')
    varPeriods = {basePeriod};
elseif strcmp(testPeriod, 'future')
    if diff
        varPeriods = {basePeriod, futurePeriod};
    else
        varPeriods = {futurePeriod};
    end
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

dailyData = {};
soilmRegSlopes = [];

for d = 1:length(dataset)
    tempTargetFileStr = '';
    tempTargetPlotStr = '';

    dailyData = {};
    
    if strcmp(dataset{d}, 'narr')
        vars = {'narr/output'};
        modelStr = 'narr';
        plotTitle = ['NARR soilm and tasmax at ', num2str(tempPercentile), ' percentile temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
        fileTitle = ['uaVaTempExtremes-', testPeriod, '-', seasonStr, '-', num2str(tempPercentile), tempTargetFileStr, '-narr.' fileformat];
    else
        modelStr = '';
        if length(dataset) > 1
            modelStr = 'narccap-mm';
        else
            parts = strsplit(dataset{d}, '/');
            modelStr = [parts{1} '-' parts{2}];
        end
        
        vars = {['narccap/output/' dataset{d}]};
        plotTitle = ['NARCCAP ' modelStr ' 850 hPa winds at ', num2str(tempPercentile), ' percentile temps ', tempTargetPlotStr, '[', num2str(varPeriods{1}(1)), '-', num2str(varPeriods{1}(end)) ']'];
        fileTitle = ['uaVaTempExtremes-', testPeriod, '-', seasonStr, '-', num2str(tempPercentile), tempTargetFileStr, '-narccap-' modelStr '.' fileformat];   
    end

    lat = [];
    lon = [];

    for v = 1:length(vars)
        
        if length(findstr(vars{1}, 'narccap')) ~= 0            
            if summer
                dataVars = {'tasmax', 'mrso'};
            else
                dataVars = {'tasmin', 'mrso'};
            end

            varLevels = {-1, -1};
            varRegrid = {true, true};
        elseif length(findstr(vars{1}, 'narr')) ~= 0
            if summer
                dataVars = {'tasmax', 'soilm'};
            else
                dataVars = {'tasmin', 'soilm'};
            end

            varLevels = {-1, -1};
            varRegrid = {false, false};
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
                    data = loadDailyData(varStr, 'yearStart', y, 'yearEnd', y+(yearStep-1), 'plev', varLevels{k});
                else
                    data = loadDailyData(varStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
                end

                if length(data{1}) == 0
                    continue;
                end

                [latIndexRange, lonIndexRange] = latLonIndexRange(data, tempLatRange, tempLonRange);
                
                if length(lat) == 0 | length(lon) == 0
                    lat = data{1}(latIndexRange, lonIndexRange);
                    lon = data{2}(latIndexRange, lonIndexRange);
                end
                
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

                dailyData{v}{k} = cat(3, dailyData{v}{k}, curDailyDataRe);
                clear curDailyDataRe;
            end
        end
    end
    
    dailyData = dailyData{1};
    for x = 1:size(lat,1)
        for y = 1:size(lat,2)
            temp = squeeze(dailyData{1}(x, y, :));
            soilm = squeeze(dailyData{2}(x, y, :));

            ind = intersect(find(~isnan(temp)), find(~isnan(soilm)));

            if length(ind) > 100
                p = polyfit(temp(ind), soilm(ind), 1);
                soilmRegSlopes(x, y, d) = p(1);
            else
                soilmRegSlopes(x, y, d) = 0;
            end

            clear temp soilm;
        end
    end
    soilmRegSlopes(soilmRegSlopes(:,:,d) == 0) = NaN;
    
    clear dailyData;
end

soilmRegSlopes = nanmean(soilmRegSlopes, 3);

[fg,cb] = plotModelData({lat, lon, soilmRegSlopes}, 'north america', 'caxis', [-0.5 0.5]);
xlabel(cb, 'soil moisture vs. temperature regression slope', 'FontSize', 24);
cbPos = get(cb, 'Position');
set(gcf, 'Position', get(0,'Screensize'));
ti = get(gca,'TightInset');
set(gca,'Position',[ti(1) cbPos(2) 1-ti(3)-ti(1) 1-ti(4)-cbPos(2)-cbPos(4)]);
eval(['export_fig soilmTempRegression_' modelStr '.pdf;']);
close all;




