season = 'all';
basePeriod = 'past';
baseDataset = 'ncep';

baseModels = {''};

% baseModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
%           'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
%           'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
%           'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};
      
baseVar = 'wb';
testVar = 'wb';

baseRegrid = true;

basePeriodYears = 1985:2010;
testPeriodYears = 2020:2080;

baseBiasCorrect = false;

popRegrid = true;

rcp = 'rcp85';
region = 'world';
exposureThreshold = 27;
ssps = 1:5;

% compare the annual mean temperatures or the mean extreme temperatures
exportformat = 'png';

baseDir = 'e:/data/';
yearStep = 1;

if ~baseBiasCorrect
    baseBcStr = '';
else
    baseBcStr = '-bc';
end

if strcmp(season, 'summer')
    findMax = true;
    months = [6 7 8];
    maxMinStr = 'maximum';
elseif strcmp(season, 'winter')
    findMax = false;
    months = [12 1 2];
    maxMinStr = 'minimum';
elseif strcmp(season, 'all')
    findMax = true;
    months = 1:12;
    maxMinStr = 'maximum';
end

if strcmp(region, 'usne')
    latRange = [30 55];
    lonRange = [-100 -62] + 360;
elseif strcmp(region, 'west_africa')
    latRange = [0, 30];
    lonRange = [340, 40];
elseif strcmp(region, 'china')
    latRange = [20, 55];
    lonRange = [75, 135];
elseif strcmp(region, 'world')
    latRange = [-90, 90];
    lonRange = [0, 360];
elseif strcmp(region, 'india')
    latRange = [8, 34];
    lonRange = [67, 90];
end

if strcmp(basePeriod, 'past')
    basePeriod = basePeriodYears;
    baseRcp = 'historical/'
elseif strcmp(basePeriod, 'future')
    basePeriod = testPeriodYears;
    baseRcp = [rcp '/'];
end

baseDatasetStr = baseDataset;
if strcmp(baseDatasetStr, 'cmip5')
    if length(baseModels) == 1
        baseDatasetStr = ['cmip5-' baseModels{1}]
    else
        baseDatasetStr = ['cmip5-mm'];
    end
    
    baseDataDir = 'cmip5/output';
    ensemble = 'r1i1p1/';
elseif strcmp(baseDatasetStr, 'ncep')
    baseDatasetStr = ['ncep'];
    baseDataDir = 'ncep-reanalysis/output';
    ensemble = '';
    baseRcp = '';
end

fileTimeStr = '';
if ~strcmp(testVar, '')
    fileTimeStr = [season '-' num2str(testPeriodYears(1)) '-' num2str(testPeriodYears(end)) '-' baseDataset '-' num2str(basePeriodYears(1)) '-' num2str(basePeriodYears(end))];
else
    fileTimeStr = [season '-' baseDataset '-' num2str(basePeriodYears(1)) '-' num2str(basePeriodYears(end))];
end

plotTitle = ['[' num2str(testPeriodYears(1)) '-' num2str(testPeriodYears(end)) '] yearly ' season ' ' maxMinStr ' - ' baseDataset ' [' num2str(basePeriodYears(1)) '-' num2str(basePeriodYears(end)) ']'];
fileTitle = ['popExposure-' baseVar '-' region '-' fileTimeStr '.' exportformat];

baseExt = {};

lat = [];
lon = [];

basePopCount = [];
constPopCount = [];
constClimateCount = [];

meanBaseSelGrid = [];

for m = 1:length(baseModels)
    if strcmp(baseModels{m}, '')
        curModel = baseModels{m};
    else
        curModel = [baseModels{m} '/'];
    end

    baseExt{m} = {};
    
    ['loading ' curModel ' base']
    for y = basePeriodYears(1):yearStep:basePeriodYears(end)
        ['year ' num2str(y) '...']
        if baseRegrid
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp baseVar '/regrid/' region baseBcStr], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        else
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(baseDaily, latRange, lonRange);
        baseDaily{3} = baseDaily{3}(latIndexRange, lonIndexRange, :, :);
        
        if length(lat) == 0
            lat = baseDaily{1}(latIndexRange, lonIndexRange);
            lon = baseDaily{2}(latIndexRange, lonIndexRange);
        end
        
        baseExtTmp = findYearlyExtremes(baseDaily, months, findMax);
        
        baseExt{m} = {baseExt{m}{:} baseExtTmp{:}};
        baseExtTmp = baseExtTmp{1}{3};
        
        selGrid = zeros(size(lat));
        for xlat = 1:size(baseExtTmp, 1)
            for ylon = 1:size(baseExtTmp, 2)
                if baseExtTmp(xlat, ylon) >= exposureThreshold
                    selGrid(xlat, ylon) = 1;
                end
            end
        end
        
        meanBaseSelGrid(:, :, m, y-basePeriodYears(1)+1) = selGrid;
        
        for ssp = ssps
            basePopCount(m, ssp, y-basePeriodYears(1)+1) = hh_countPop({lat, lon, selGrid}, region, [2010], ssp, popRegrid);
        end
        
        clear baseDaily baseExtTmp;
    end
end

meanBaseSelGrid = nanmean(nanmean(meanBaseSelGrid, 4), 3);

['done loading...']

% average over ensembles, models, and years
%for e = 1:length(ensembles)
    for m = 1:length(baseExt)
        for y = 1:length(baseExt{m})
            baseData(:,:,m,y) = baseExt{m}{y}{3};
        end
    end
%end

clear baseExt;

% average over years in base period
baseData = nanmean(baseData, 4);

futureData = [];

% load projected change data
decCount = 1;
for t = testPeriodYears(1):10:testPeriodYears(end-1)
    load(['chg-data-wb-multi-model-' num2str(t) '-' num2str(t+10) '.mat']);
    
    chgData(chgData > 10) = NaN;
    
    for x = 1:size(chgData, 1)
        for y = 1:size(chgData, 2)
            chgData(x, y, :) = sort(chgData(x, y, :));
        end
    end
    
    for c = 1:size(chgData, 3)
        % compute future scenarios by adding change onto base data
        futureData(:, :, decCount, c) = squeeze(baseData(:, :, 1)) + chgData(:, :, c);
    end
    
    decCount = decCount + 1;
    clear chgData;
end

%count future population
futurePopCount = [];
constPopCount = [];

for d = 1:size(futureData, 3)
    for s = 1:size(futureData, 4)
        selGrid = zeros(size(lat));
        for xlat = 1:size(futureData, 1)
            for ylon = 1:size(futureData, 2)
                if futureData(xlat, ylon, d, s) >= exposureThreshold
                    selGrid(xlat, ylon) = 1;
                end
            end
        end
        
        for ssp = ssps
            futurePopCount(s, d, ssp) = hh_countPop({lat, lon, selGrid}, region, [testPeriodYears(1+((d-1)*10))], ssp, popRegrid);
            constPopCount(s, d, ssp) = hh_countPop({lat, lon, selGrid}, region, [2010], ssp, popRegrid);
        end
        
    end
    
    for ssp = ssps
        constClimateCount(d, ssp) = hh_countPop({lat, lon, meanBaseSelGrid}, region, [testPeriodYears(1+((d-1)*10))], ssp, popRegrid);
    end
    
end

% average over models and ssps
mmBasePopCount = nanmean(nanmean(basePopCount, 3), 1);
mmFuturePopCount = nanmean(nanmean(futurePopCount, 3), 1);
mmConstPopCount = nanmean(nanmean(constPopCount, 3), 1);
mmConstClimateCount = nanmean(constClimateCount, 2);

% exposure rise due to climate alone
climatePopEffect = constPopCount;
% exposure rise due to pop change alone
popPopEffect = constClimateCount;
% exposure rise due to climate & pop
interactionEffect = [];
for i = 1:size(futurePopCount, 2)
    for j = 1:size(futurePopCount, 1)
        interactionEffect(j, i, :) = squeeze(futurePopCount(j, i, :)) - squeeze(climatePopEffect(j, i, :)) - squeeze(popPopEffect(i, :))';
    end
end

prcRange = [25 75];

% calculate uncertainties
climE = [];
popE = [];
intE = [];
futPopE = [];

%for c = 1:size(climatePopEffect, 


climE = [climatePopEffect(round((prcRange(1)/100.0)*size(climatePopEffect, 1)), :); ...
            climatePopEffect(round((prcRange(2)/100.0)*size(climatePopEffect, 1)), :)];

% no uncertainty estimate yet, incorperate multiple SSPs
popE = zeros(length(popPopEffect));

intE = [interactionEffect(round((prcRange(1)/100.0)*size(interactionEffect, 1)), :); ...
           interactionEffect(round((prcRange(2)/100.0)*size(interactionEffect, 1)), :)];
        
futPopE= [futurePopCount(round((prcRange(1)/100.0)*size(futurePopCount, 1)), :); ...
             futurePopCount(round((prcRange(2)/100.0)*size(futurePopCount, 1)), :)];

mmClimatePopEffect = nanmean(climatePopEffect, 1);
mmPopPopEffect = nanmean(popPopEffect, 1);
mmInteractionEffect = nanmean(interactionEffect, 1);
mmFutPopEffect = nanmean(futurePopCount, 1);

% calc decadal means
futureDecX = (testPeriodYears(1))+5:10:(testPeriodYears(end)-5);
mmFutureDecY = [];
mmFutureDecYerr = [];

futureDecY = [];
futureDecYerr = [];

for d = 1:size(mmClimatePopEffect, 2)
    futureDecY(d, 1) = mmPopPopEffect(d);
    futureDecY(d, 2) = mmClimatePopEffect(d);
    futureDecY(d, 3) = mmInteractionEffect(d);
    %futureDecY(d, 4) = popE(d)+climE(d)+intE(d);
    futureDecY(d, 4) = mmFutPopEffect(d);
    
    futureDecYerr(d, 1) = (popE(2, d) - popE(1, d))/2;
    futureDecYerr(d, 2) = (climE(2, d) - climE(1, d))/2;
    futureDecYerr(d, 3) = (intE(2, d) - intE(1, d))/2;
    futureDecYerr(d, 4) = (futPopE(2, d) - futPopE(1, d))/2;
end

plotTitle = ['Exposure to ' num2str(exposureThreshold) 'C wet bulb, global'];
fileTitle = ['heatExposure-' baseDataset '-' baseVar '-' num2str(exposureThreshold) '-ssp' num2str(ssp) '-' region];

saveData = struct('futureDecX', futureDecX, ...
                  'futureDecY', futureDecY, ...
                  'futureDecYerr', futureDecYerr, ...
                  'Xlabel', 'Year', ...
                  'Ylabel', 'Number exposed', ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle);

barChart = true;
              
if barChart

    trace1 = struct('x', { saveData.futureDecX }, ...
                  'y', saveData.futureDecY(:,1), ...
                  'name', 'Population effect', ...
                  'error_y', struct(...
                    'type', 'data', ...
                    'visible', true), ...
                  'type', 'bar');
              
	trace2 = struct('x', { saveData.futureDecX }, ...
                  'y', saveData.futureDecY(:,2), ...
                  'name', 'Climate effect', ...
                  'error_y', struct(...
                    'type', 'data', ...
                    'visible', true), ...
                  'type', 'bar');
    trace3 = struct('x', { saveData.futureDecX }, ...
                  'y', saveData.futureDecY(:,3), ...
                  'name', 'Interaction effect', ...
                  'error_y', struct(...
                    'type', 'data', ...
                    'visible', true), ...
                  'type', 'bar');
              
	trace4 = struct('x', { saveData.futureDecX }, ...
                  'y', saveData.futureDecY(:,4), ...
                  'name', 'Total', ...
                  'error_y', struct(...
                    'type', 'data', ...
                    'visible', true), ...
                  'type', 'bar');
              
    plotlyData = {trace1, trace2, trace3, trace4};
    plotlyLayout = struct('barmode', 'group');
    plotlyResponse = plotly(plotlyData, struct('layout', plotlyLayout, 'filename', ['heat-' num2str(exposureThreshold) 'c-ssp' num2str(ssp)], 'fileopt', 'overwrite'));
    
    figure('Color', [1, 1, 1]);
    hold on;

    B = barwitherr([saveData.futureDecYerr(:,1), saveData.futureDecYerr(:,2), saveData.futureDecYerr(:,3), saveData.futureDecYerr(:,4)], ...
                   saveData.futureDecX, ...
                   [saveData.futureDecY(:,1), saveData.futureDecY(:,2), saveData.futureDecY(:,3), saveData.futureDecY(:,4)]);
    
    set(B(1), 'FaceColor', [181,82,124] ./ 255.0);
    set(B(2), 'FaceColor', [107,169,61] ./ 255.0);
    set(B(3), 'FaceColor', [104,126,171] ./ 255.0);
    set(B(3), 'FaceColor', [170,126,51] ./ 255.0);
    
    title(saveData.plotTitle, 'FontSize', 24);
    xlabel(saveData.Xlabel, 'FontSize', 24);
    ylabel(saveData.Ylabel, 'FontSize', 24);
    set(gca, 'FontSize', 24);
    set(gcf, 'Position', get(0,'Screensize'));
    
    l = legend(B, 'population effect', 'climate effect', 'interaction effect', 'total change');
    set(l, 'FontSize', 24, 'Location', 'best');
    
else
    figure('Color', [1, 1, 1]);
    hold on;
    plot(saveData.dataX1, saveData.dataY1, 'b', 'LineWidth', 2);
    plot(saveData.dataX2, saveData.dataY2, 'r', 'LineWidth', 2);
    plot(saveData.dataX2, saveData.dataY3, '--r', 'LineWidth', 2);
    title(saveData.plotTitle, 'FontSize', 24);
    xlabel(saveData.Xlabel, 'FontSize', 24);
    ylabel(saveData.Ylabel, 'FontSize', 24);
    set(gcf, 'Position', get(0,'Screensize'));
    l = legend('Past', 'Future', 'Constant population');
    set(l, 'FontSize', 24, 'Location', 'best');
end

eval(['export_fig ' saveData.fileTitle '.pdf;']);
save([saveData.fileTitle '.mat'], 'saveData');
%close all;
