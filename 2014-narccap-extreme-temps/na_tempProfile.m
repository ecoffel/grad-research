
season = 'winter';
baseTime = 'past';
testTime = 'future';

baseDataset = 'narr';
testDataset = 'narr';

baseModels = {''};
testModels = {''};
%baseModels = {'crcm/ccsm', 'crcm/cgcm3', 'hrm3/gfdl', 'hrm3/hadcm3', 'mm5i/ccsm'};
%testModels = {'crcm/ccsm', 'crcm/cgcm3', 'hrm3/gfdl', 'hrm3/hadcm3', 'mm5i/ccsm'};

baseTimePeriod = 1981:1998;
futureTimePeriod = 2051:2069;

baseVar = 'airmin';
testVar = '';

baseSurfVar = 'tasmin';
testSurfVar = '';

baseRegrid = false;
testRegrid = false;

% load 850, 500, 300, 200
% and load tasmax for the surface
basePlev = 2:5;
testPlev = 2:5;

% compare the annual mean r the mean extreme or both
meanOrExt = 'mean';
if strcmp(season, 'summer')
    findMax = true;
else
    findMax = false;
end

plotRegion = 'usa-exp';
exportformat = 'pdf';

baseDir = 'e:/data/';
baseDataDir = [baseDataset '/output'];
yearStep = 1;

region = 'ne';

if strcmp(region, 'ne')
    latRange = [39 41];
    if strcmp(baseDataset, 'narr')
        lonRange = [-80 -76];
    else
        lonRange = [-80 -76]+360;
    end
elseif strcmp(region, 'sw')
    latRange = [34 36];
    if strcmp(baseDataset, 'narr')
        lonRange = [-112 -108];
    else
        lonRange = [-112 -108]+360;
    end
    
end

months = [];
if strcmp(season, 'summer')
    months = 6:8;
elseif strcmp(season, 'winter')
    months = [12 1 2];
end

if ~strcmp(testVar, '')
    fileTimeStr = [testDataset '-' season '-' meanOrExt '-'  num2str(futureTimePeriod(1)) '-' num2str(futureTimePeriod(end)) '-' baseDataset '-' num2str(baseTimePeriod(1)) '-' num2str(baseTimePeriod(end))];
else
    fileTimeStr = [season '-' meanOrExt '-' baseDataset '-' num2str(baseTimePeriod(1)) '-' num2str(baseTimePeriod(end))];
end

%plotTitle = [baseVar ': ' testTitleStr season ' ' maxMinStr ' - ' baseDataset ' [' num2str(basePeriod(1)) '-' num2str(basePeriod(end)) ']'];
fileTitle = ['tempProfile-' baseVar '-' fileTimeStr '-' region '.' exportformat];

baseProfileData = {};
testProfileData = {};

for m = 1:length(baseModels)
    if ~strcmp(baseModels{m}, '')
        curModel = ['/' baseModels{m} '/'];
    else
        curModel = '/';
    end
    
    ['loading ' baseDataset curModel ' ' baseTime]
    for y = baseTimePeriod(1):yearStep:baseTimePeriod(end)
        ['year ' num2str(y) '...']
        
        if length(baseProfileData) < (y-baseTimePeriod(1)+1)
            baseProfileData{y-baseTimePeriod(1)+1} = [];
        end
        
        % load surface data
        if baseRegrid
            baseSurfDaily = loadDailyData([baseDir baseDataDir curModel baseSurfVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            baseSurfDaily = loadDailyData([baseDir baseDataDir curModel baseSurfVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(baseSurfDaily, latRange, lonRange);
        
        lat = baseSurfDaily{1}(latIndexRange, lonIndexRange);
        lon = baseSurfDaily{2}(latIndexRange, lonIndexRange);
        
        % save surface data
        sz = size(baseSurfDaily{3}(latIndexRange, lonIndexRange, 1, months, :), 5);
        baseSurfDaily{3}(latIndexRange, lonIndexRange, 1, months, sz+1:31) = NaN;
        baseProfileData{y-baseTimePeriod(1)+1}(:, :, :, :, m, 1) = squeeze(baseSurfDaily{3}(latIndexRange, lonIndexRange, 1, months, 1:31)-273.15);

        clear baseSurfDaily;
        
        % load and save plev data
        baseDaily = {};
        for p = basePlev
            if baseRegrid
                baseDaily = loadDailyData([baseDir baseDataDir curModel baseVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1, 'plev', p);
            else
                baseDaily = loadDailyData([baseDir baseDataDir curModel baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1, 'plev', p);
            end
            
            sz = size(baseDaily{3}(latIndexRange, lonIndexRange, 1, months, :), 5);
            baseDaily{3}(latIndexRange, lonIndexRange, 1, months, sz+1:31) = NaN;
            baseProfileData{y-baseTimePeriod(1)+1}(:, :, :, :, m, p) = squeeze(baseDaily{3}(latIndexRange, lonIndexRange, 1, months, 1:31)-273.15);
            
            clear baseDaily;
        end
    end
end

% if we are only looking at one dataset
if ~strcmp(testVar, '')
    for m = 1:length(testModels)
        if ~strcmp(testModels{m}, '')
            curModel = ['/' testModels{m} '/'];
        else
            curModel = '/';
        end
        
        ['loading ' testDataset curModel ' ' testTime]
        for y = futureTimePeriod(1):yearStep:futureTimePeriod(end)
            
            if length(testProfileData) < (y-futureTimePeriod(1)+1)
                testProfileData{y-futureTimePeriod(1)+1} = [];
            end
            
            ['year ' num2str(y) '...']
            
            if testRegrid
                testSurfDaily = loadDailyData([baseDir baseDataDir curModel testSurfVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            else
                testSurfDaily = loadDailyData([baseDir baseDataDir curModel testSurfVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            end

            [latIndexRange, lonIndexRange] = latLonIndexRange(testSurfDaily, latRange, lonRange);
            
            % save surface data
            sz = size(testSurfDaily{3}(latIndexRange, lonIndexRange, 1, months, :), 5);
            testSurfDaily{3}(latIndexRange, lonIndexRange, 1, months, sz+1:31) = NaN;
            testProfileData{y-futureTimePeriod(1)+1}(:, :, :, :, m, 1) = squeeze(testSurfDaily{3}(latIndexRange, lonIndexRange, 1, months, 1:31)-273.15);

            clear testSurfDaily;
            
            % load daily data
            for p = testPlev
                if testRegrid
                    testDaily = loadDailyData([baseDir baseDataDir curModel testVar '/regrid'], 'yearStart', y, 'yearEnd', (y+yearStep)-1, 'plev', p);
                else
                    testDaily = loadDailyData([baseDir baseDataDir curModel testVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1, 'plev', p);
                end
                
                sz = size(testDaily{3}(latIndexRange, lonIndexRange, 1, months, :), 5);
                testDaily{3}(latIndexRange, lonIndexRange, 1, months, sz+1:31) = NaN;
                testProfileData{y-futureTimePeriod(1)+1}(:, :, :, :, m, p) = squeeze(testDaily{3}(latIndexRange, lonIndexRange, 1, months, 1:31)-273.15);
            end
            
            clear testDaily;
        end
    end
end

['done loading...']

if strcmp(meanOrExt, 'mean')
    if ~strcmp(testVar, '')
        testProfile = [];
        for y = 1:length(testProfileData)
            testProfile(y, :) = nanmean(nanmean(nanmean(nanmean(nanmean(testProfileData{y}(:, :, :, :, :, :), 5), 4), 3), 2), 1);
        end
        testProfile = squeeze(nanmean(testProfile, 1));
    end
    
    baseProfile = [];
    for y = 1:length(baseProfileData)
        baseProfile(y, :) = nanmean(nanmean(nanmean(nanmean(nanmean(baseProfileData{y}(:, :, :, :, :, :), 5), 4), 3), 2), 1);
    end
    baseProfile = squeeze(nanmean(baseProfile, 1));
    
elseif strcmp(meanOrExt, 'ext')
    if ~strcmp(testVar, '')
        testProfile = [];
        for m = 1:length(testModels)
            for y = 1:length(testProfileData)
                for xlat = 1:size(testProfileData{y}, 1)
                    for ylon = 1:size(testProfileData{y}, 2)
                        index = [];
                        startingPlev = 0;
                        while length(index) == 0
                            startingPlev = startingPlev + 1;
                            curYearProfile(:, :) = reshape(squeeze(testProfileData{y}(xlat, ylon, :, :, m, :)), ...
                                                            [1, size(testProfileData{y}, 3)*size(testProfileData{y}, 4), 1, size(testProfileData{y}, 6)]);
                            if findMax
                                index = find(squeeze(curYearProfile(:, startingPlev)) == nanmax(squeeze(curYearProfile(:, startingPlev))));
                            else
                                index = find(squeeze(curYearProfile(:, startingPlev)) == nanmin(squeeze(curYearProfile(:, startingPlev))));
                            end
                        end

                        if length(index) > 0
                            level = [];
                            for i = 1:startingPlev-1
                                level(i) = NaN;
                            end
                            level = [level squeeze(nanmean(curYearProfile(index, startingPlev:5), 1))];
                            testProfile(xlat, ylon, y, m, :) = level;
                        else
                            testProfile(xlat, ylon, y, m, :) = [NaN NaN NaN NaN NaN];
                        end
                    end
                end
            end
        end
        testProfile = squeeze(nanmean(nanmean(nanmean(nanmean(testProfile, 4), 3), 2), 1));
    end
    
    baseProfile = [];
    for m = 1:length(baseModels)
        for y = 1:length(baseProfileData)
            for xlat = 1:size(baseProfileData{y}, 1)
                for ylon = 1:size(baseProfileData{y}, 2)
                    index = [];
                    startingPlev = 0;
                    while length(index) == 0
                        startingPlev = startingPlev + 1;
                        curYearProfile(:, :) = reshape(squeeze(baseProfileData{y}(xlat, ylon, :, :, m, :)), ...
                                                        [1, size(baseProfileData{y}, 3)*size(baseProfileData{y}, 4), 1, size(baseProfileData{y}, 6)]);
                        if findMax
                            index = find(squeeze(curYearProfile(:, startingPlev)) == nanmax(squeeze(curYearProfile(:, startingPlev))));
                        else
                            index = find(squeeze(curYearProfile(:, startingPlev)) == nanmin(squeeze(curYearProfile(:, startingPlev))));
                        end
                    end

                    if length(index) > 0
                        level = [];
                        for i = 1:startingPlev-1
                            level(i) = NaN;
                        end
                        level = [level squeeze(nanmean(curYearProfile(index, startingPlev:5), 1))];
                        baseProfile(xlat, ylon, y, m, :) = level;
                    else
                        baseProfile(xlat, ylon, y, m, :) = [NaN NaN NaN NaN NaN];
                    end
                end
            end
        end
    end
    baseProfile = squeeze(nanmean(nanmean(nanmean(nanmean(baseProfile, 4), 3), 2), 1));

end

if strcmp(testVar, '')
    result = baseProfile;
    Xrange = [-60 40];
else
    result = testProfile-baseProfile;
    Xrange = [-5 5];
end

result(isnan(result)) = 0;

yAxis = [1000; 850; 500; 300; 200];

plotTitle = ['NARR NE winter mean temperature profile'];
Xlabel = 'Temperature (degrees C)';
Ylabel = 'Pressure (hPa)';

saveData = struct('dataX', yAxis, ...
                  'dataY', result, ...
                  'Xlabel', Xlabel, ...
                  'Ylabel', Ylabel, ...
                  'Xrange', Xrange, ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle);

figure('Color', [1, 1, 1]);
hold on;
set(gca,'YDir','reverse');
hAx = plot(saveData.dataY, saveData.dataX, 'r', 'LineWidth', 2);

xlim(saveData.Xrange);

title(saveData.plotTitle, 'FontSize', 24);
xlabel(saveData.Xlabel, 'FontSize', 24);
ylabel(saveData.Ylabel, 'FontSize', 24);

set(gcf, 'Position', get(0,'Screensize'));
eval(['export_fig ' saveData.fileTitle ';']);

fileTitleParts = strsplit(saveData.fileTitle, '.');
save([fileTitleParts{1} '.mat'], 'saveData');
close all;

