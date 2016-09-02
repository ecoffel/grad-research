testPeriod = 'past';

% models = {'access1-0', 'access1-3', 'bnu-esm', 'bcc-csm1-1-m', ...
%           'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
%           'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
%           'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};

models = {'bnu-esm'};

dataset = 'cmip5';

testVar = 'tos';
testRcp = 'historical';
baseVar = 'wb';
baseRcp = 'historical'

plotEachModel = true;

% look at correlation for ssts to wet bulbs above this percentile
percentileThreshold = 10;

% the temperature reference area
region = 'india';
plotRegion = 'world';
fileformat = 'png';

baseDir = 'e:/data/';
ensemble = 'r1i1p1';
modelDir = 'cmip5/output';

timePeriod = [];
if strcmp(testPeriod, 'past')
    timePeriod = 1985:2005;
elseif strcmp(testPeriod, 'future')
    timePeriod = 2060:2080;
end

baseRegrid = true;
testRegrid = true;

if strcmp(region, 'us-ne')
    % right around NYC
    latBounds = [40 40];
    lonBounds = [-75 -75] + 360;
elseif strcmp(region, 'india')
    latBounds = [25 26];
    lonBounds = [82 83];   
elseif strcmp(region, 'west-africa')
    latBounds = [34.5 36.5];
    lonBounds = [256 260];   
elseif strcmp(region, 'china')
    latBounds = [35 35];
    lonBounds = [256 256];   
end

if strcmp(testVar, 'tos')
    gridbox = false;
    plotRange = [-1 1]
    plotXUnits = 'correlation coefficient';
end

tempDispStr = [num2str(percentileThreshold) 'p']

yearStep = 1; % the number of years loaded at a time for memory  reasons

wbData = {};
sstData = {};
corrData = {};


lat = [];
lon = [];

for d = 1:length(models)
    
    tempTargetFileStr = '';
    tempTargetPlotStr = '';

    if length(models) > 2
        modelStr = 'cmip5';
    else
        modelStr = models{d};
    end

    baseGrid = {};
    yearLengths = [];
    
    monthlySSTMeans = [];
    extremeSSTVals = [];
    
    ['loading ' models{d} '...']
    for y = timePeriod(1):yearStep:timePeriod(end)
        ['year ' num2str(y)]

        if baseRegrid
            baseStr = [baseDir modelDir '/' models{d} '/' ensemble '/' baseRcp '/' baseVar '/regrid/world'];
        else
            baseStr = [baseDir modelDir '/' models{d} '/' ensemble '/' baseRcp '/' baseVar];
        end

        if testRegrid
            testStr = [baseDir modelDir '/' models{d} '/' ensemble '/' testRcp '/' testVar '/regrid/world'];
        else
            testStr = [baseDir modelDir '/' models{d} '/' ensemble '/' testRcp '/' testVar];
        end

        dailyBase = loadDailyData(baseStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));

        if length(lat) == 0 | length(lon) == 0
            lat = dailyBase{1};
            lon = dailyBase{2};
        end

        if strcmp(baseVar, 'tos')
            dailyBase{3} = dailyBase{3} - 273.15;
        end
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(dailyBase, latBounds, lonBounds);
        
        % select region and reshape to 1D array
        curDailyBaseData = dailyBase{3}(latIndexRange, lonIndexRange, :, :, :);
        curDailyBaseData = squeeze(reshape(curDailyBaseData, ...
                                   [length(latIndexRange), ...
                                   length(lonIndexRange), ...
                                   size(curDailyBaseData, 3)*size(curDailyBaseData,4)*size(curDailyBaseData,5)]));
        
        clear dailyBase;

        
        % find values above thresh
        baseInd = find(curDailyBaseData > prctile(curDailyBaseData, percentileThreshold));
        curDailyBaseData = curDailyBaseData(baseInd);
        
        dailyTest = loadDailyData(testStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));

        if strcmp(testVar, 'tos')
            dailyTest{3} = dailyTest{3} - 273.15;
        end

        curDailyTestData = dailyTest{3};
        clear dailyTest;

        
        curDailyTestData = reshape(curDailyTestData, ...
                                    [size(curDailyTestData, 1), size(curDailyTestData, 2), ...
                                     size(curDailyTestData, 3)*size(curDailyTestData,4)*size(curDailyTestData,5)]);

        % select sst values that correspond to the wb indices
        curDailyTestData = curDailyTestData(:, :, baseInd);
        
        if length(wbData) < d
            wbData{d} = [];
            sstData{d} = [];
        end
        
        wbData{d} = cat(1, wbData{d}, curDailyBaseData);
        sstData{d} = cat(3, sstData{d}, curDailyTestData);
                                 
        clear curDailyBaseData;
        clear curDailyTestData;
    end

    corrData{d} = [];
    for x = 1:size(sstData{d}, 1)
        for y = 1:size(sstData{d}, 2)
            sst = squeeze(sstData{d}(x,y,:));
            wb = wbData{d};
            
            notnanInd = find(~isnan(sst) & ~isnan(wb));
            c = corrcoef(sst(notnanInd), wb(notnanInd));
            corrData{d}(x, y) = c(1,2);
        end
    end
    
    
end

if plotEachModel
    for d = 1:length(models)
        
        plotTitle = ['SST correlations on > ' num2str(percentileThreshold) 'p WB days (' region ', ' models{d} ')'];
        fileTitle = [testVar 'WbCorr-', testPeriod, '-', region, '-', tempDispStr, tempTargetFileStr, '-' models{d} '.' fileformat];
    
        % plotting code
        [fg,cb] = plotModelData({lat, lon, corrData{d}}, plotRegion, 'caxis', plotRange);
        set(gca, 'Color', 'none');
        xlabel(cb, plotXUnits, 'FontSize', 18);
        cbPos = get(cb, 'Position');
        title(plotTitle, 'FontSize', 18);
        set(gcf, 'Position', get(0,'Screensize'));
        set(gcf, 'Units', 'normalized');
        set(gca, 'Units', 'normalized');

        ti = get(gca,'TightInset');
        set(gca,'Position',[ti(1) cbPos(2) 1-ti(3)-ti(1) 1-ti(4)-cbPos(2)-cbPos(4)]);
        eval(['export_fig ' fileTitle ';']);
        close all;
    end
else
    
    plotTitle = ['SST correlations on > ' num2str(percentileThreshold) 'p WB days (' region ', CMIP5 mean)'];
    fileTitle = [testVar 'WbCorr-', testPeriod, '-', region, '-', tempDispStr, tempTargetFileStr, '-' modelStr '.' fileformat];
    
    % average over all models
    finalOutputTestData = [];
    for d = 1:length(models)
        finalOutputTestData(:,:,d) = corrData{d};
    end
    finalOutputTestData = nanmean(finalOutputTestData, 3);

    % plotting code
    [fg,cb] = plotModelData({lat, lon, double(finalOutputTestData)}, plotRegion, 'caxis', plotRange);
    set(gca, 'Color', 'none');
    xlabel(cb, plotXUnits, 'FontSize', 18);
    cbPos = get(cb, 'Position');
    title(plotTitle, 'FontSize', 18);
    set(gcf, 'Position', get(0,'Screensize'));
    set(gcf, 'Units', 'normalized');
    set(gca, 'Units', 'normalized');

    ti = get(gca,'TightInset');
    set(gca,'Position',[ti(1) cbPos(2) 1-ti(3)-ti(1) 1-ti(4)-cbPos(2)-cbPos(4)]);
    eval(['export_fig ' fileTitle ';']);
    close all;
end
    
