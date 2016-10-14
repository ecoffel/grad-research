testPeriod = 'past';

models = {'access1-0', 'access1-3', 'bnu-esm', 'bcc-csm1-1-m', ...
          'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};

%models = {'access1-0', 'gfdl-cm3'};

dataset = 'cmip5';

testVar = 'tos';
testRcp = 'historical';
baseVar = 'wb';
baseRcp = 'historical'

plotEachModel = true;

% look at correlation for ssts to wet bulbs above this percentile
percentileThreshold = 90;

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
testRegrid = false;

if strcmp(region, 'us-ne')
    % right around NYC
    latBounds = [34 36];
    lonBounds = [-82 -80] + 360;
elseif strcmp(region, 'india')
    latBounds = [23 25];
    lonBounds = [80 82];   
elseif strcmp(region, 'west-africa')
    latBounds = [6 8];
    lonBounds = [-3 -1] + 360;   
elseif strcmp(region, 'china')
    latBounds = [26 28];
    lonBounds = [116 118];   
end

if strcmp(testVar, 'tos') || strcmp(testVar, 'sst')
    gridbox = false;
    plotRange = [-1 1]
    plotXUnits = 'correlation coefficient';
end

tempDispStr = [num2str(percentileThreshold) 'p']

yearStep = 1; % the number of years loaded at a time for memory  reasons

wbData = {};
sstData = {};
corrData = {};
sstLatData = {};
sstLonData = {};

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
        
        % take spatial average over gridboxes - do this up to twice,
        % depending on size of selected area
        if size(curDailyBaseData, 1) > 1
            curDailyBaseData = squeeze(nanmean(curDailyBaseData, 1));
            if size(curDailyBaseData, 1) > 1
                curDailyBaseData = squeeze(nanmean(curDailyBaseData, 1));
            end
        end
                               
        clear dailyBase;

        
        % find values above thresh
        baseInd = find(curDailyBaseData > prctile(curDailyBaseData, percentileThreshold));
        curDailyBaseData = curDailyBaseData(baseInd);
        
        dailyTest = loadDailyData(testStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));

        sstLatData{d} = dailyTest{1};
        sstLonData{d} = dailyTest{2};
        
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
        
        wbData{d} = cat(1, wbData{d}, curDailyBaseData');
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
    
        result = {sstLatData{d}, sstLonData{d}, corrData{d}};
        saveData = struct('data', {result}, ...
                      'plotRegion', plotRegion, ...
                      'plotRange', plotRange, ...
                      'plotTitle', plotTitle, ...
                      'fileTitle', fileTitle, ...
                      'plotXUnits', plotXUnits, ...
                      'plotCountries', false, ...
                      'plotStates', false, ...
                      'blockWater', false, ...
                      'blockLand', true);

        plotFromDataFile(saveData);
        
%         % plotting code
%         [fg,cb] = plotModelData(, plotRegion, 'caxis', plotRange);
%         set(gca, 'Color', 'none');
%         xlabel(cb, plotXUnits, 'FontSize', 18);
%         cbPos = get(cb, 'Position');
%         title(plotTitle, 'FontSize', 18);
%         set(gcf, 'Position', get(0,'Screensize'));
%         set(gcf, 'Units', 'normalized');
%         set(gca, 'Units', 'normalized');
% 
%         ti = get(gca,'TightInset');
%         set(gca,'Position',[ti(1) cbPos(2) 1-ti(3)-ti(1) 1-ti(4)-cbPos(2)-cbPos(4)]);
%         eval(['export_fig ' fileTitle ';']);
%         close all;
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
    
