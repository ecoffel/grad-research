season = 'all';
basePeriod = 'past';
baseDataset = 'ncep';

baseModels = {''};

% baseModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
%           'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
%           'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
%           'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};
      
baseVar = 'wb-davies-jones-full';
testVar = 'wb-davies-jones-full';

baseRegrid = true;

basePeriodYears = 1985:2010;
testPeriodYears = 2020:2080;

baseBiasCorrect = false;

popRegrid = true;

region = 'world';
rcp = 'rcp85';
exposureThreshold = 30;
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
elseif strcmp(region, 'middle-east')
    latRange = [10, 35];
    lonRange = [35, 60];
end

if strcmp(basePeriod, 'past')
    basePeriod = basePeriodYears;
elseif strcmp(basePeriod, 'future')
    basePeriod = testPeriodYears;
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

%baseExt = {};

lat = [];
lon = [];

basePopCount = [];
constPopCount = [];
constClimateCount = [];

meanBaseSelGrid = [];

latIndexRange = [];
lonIndexRange = [];

baseDataRaw = {};
baseData = [];

for m = 1:length(baseModels)
    if strcmp(baseModels{m}, '')
        curModel = baseModels{m};
    else
        curModel = [baseModels{m} '/'];
    end

    %baseExt{m} = {};
    baseDataRaw{m} = {};
    
    ['loading ' curModel ' base']
    for y = basePeriodYears(1):yearStep:basePeriodYears(end)
        ['year ' num2str(y) '...']
        if baseRegrid
            if strcmp(baseDataset, 'ncep')
                baseDaily = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp baseVar '-mslp' '/regrid/world'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            else
                baseDaily = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp baseVar '/regrid/' region baseBcStr], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            end
        else
            baseDaily = loadDailyData([baseDir baseDataDir '/' curModel ensemble baseRcp baseVar], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        
        if length(latIndexRange) == 0
            [latIndexRange, lonIndexRange] = latLonIndexRange(baseDaily, latRange, lonRange);
        end
        
        
        baseDaily{3} = baseDaily{3}(latIndexRange, lonIndexRange, :, :, :);
        
        % don't do this b/c we need monthly separation
        %baseDaily{3} = reshape(baseDaily{3}, [size(baseDaily{3}, 1), size(baseDaily{3}, 2), ...
        %                                      size(baseDaily{3}, 3)*size(baseDaily{3}, 4)*size(baseDaily{3}, 5)]);
        
        if length(lat) == 0
            lat = baseDaily{1}(latIndexRange, lonIndexRange);
            lon = baseDaily{2}(latIndexRange, lonIndexRange);
        end
        
        baseDataRaw{m}{y-basePeriodYears(1)+1} = baseDaily{3};
        
        % find number of times per grid cell that exposure thresh is
        % reached in historical (NCEP)
        selGrid = zeros(size(lat));
        for xlat = 1:size(baseDaily{3}, 1)
            for ylon = 1:size(baseDaily{3}, 2)
                
                selGrid(xlat, ylon) = selGrid(xlat, ylon) + length(find(baseDaily{3}(xlat, ylon, :, :, :) > exposureThreshold));
                
            end
        end
        
        meanBaseSelGrid(:, :, m, y-basePeriodYears(1)+1) = selGrid;
        
        % count historical pop exposure for each grid cell
        for ssp = ssps
            basePopCount(m, ssp, y-basePeriodYears(1)+1) = hh_countPop({lat, lon, selGrid}, region, [2010], ssp, popRegrid);
        end
        
        clear baseDaily baseExtTmp;
    end
end

meanBaseSelGrid = nanmean(nanmean(meanBaseSelGrid, 4), 3);

['done loading...']

% loop over all years in ncep data and collect in baseData matrix
% baseData will have dims (x, y, year, month, day)
for y = 1:length(baseDataRaw{1})-1
    baseData(:,:,y,:,:) = baseDataRaw{1}{y};
end

clear baseDataRaw;

% average over years in base period
%baseData = nanmean(baseData, 4);

%futureData = [];

%count future population
futurePopCount = [];
constPopCount = [];

% load projected change data
decCount = 1;
for t = testPeriodYears(1):10:testPeriodYears(end-1)
    ['t = ' num2str(t)]
    load(['chg-data/chg-data-wb-davies-jones-full-' rcp '-multi-model-monthly-mean-' num2str(t) '-' num2str(t+10) '.mat']);
    
    chgData(chgData > 10) = NaN;
    
%     for x = 1:size(chgData, 1)
%         for y = 1:size(chgData, 2)
%             for month = 1:size(chgData, 3)
%                 chgData(x, y, month, :) = sort(chgData(x, y, month, :));
%             end
%         end
%     end
    
    for c = 1:size(chgData, 4)
        
        % one sel grid for each scenario
        selGrid = zeros(size(lat));
        
        for year = 1:size(baseData, 3)
            for month = 1:12
                % add change data for current month onto daily data for
                % current NCEP year
                curFutureData = squeeze(baseData(:, :, year, month, :)) + repmat(chgData(latIndexRange, lonIndexRange, month, c), [1, 1, size(baseData, 5)]);
                
                % for each gridcell, add number of exposed days for current
                % month/year
                for xlat = 1:size(chgData, 1)
                    for ylon = 1:size(chgData, 2)
                        selGrid(xlat, ylon) = selGrid(xlat, ylon) + length(find(curFutureData(xlat, ylon, :) > exposureThreshold));
                    end
                end
            end
        end
        
        % divide by number of years to get mean exceedences per year in
        % this scenario & decade (-1 on the # years because final NCEP year
        % has only 11 months so is discarded)
        selGrid = selGrid ./ (size(baseData, 3)-1);
        clear curFutureData;
        
        save(['2015-heat-humidity/selGrid/selGrid-' num2str(t) 's-' rcp '-' num2str(exposureThreshold) 'C-scenario-' num2str(c) '.mat'], 'selGrid');
        
        % loop over scenario 
        for ssp = ssps
            futurePopCount(c, decCount, ssp) = hh_countPop({lat, lon, selGrid}, region, [testPeriodYears(1+((decCount-1)*10))], ssp, popRegrid);
            constPopCount(c, decCount, ssp) = hh_countPop({lat, lon, selGrid}, region, [2010], ssp, popRegrid);
        end
        
        clear selGrid;
        
    end
    
    for ssp = ssps
        constClimateCount(decCount, ssp) = hh_countPop({lat, lon, meanBaseSelGrid}, region, [testPeriodYears(1+((decCount-1)*10))], ssp, popRegrid);
    end
    
    decCount = decCount + 1;
    clear chgData;
end



% decade
% for d = 1:size(futureData, 3)
%     % scenario (model/rcp)
%     for s = 1:size(futureData, 4)
%         selGrid = zeros(size(lat));
%         for xlat = 1:size(futureData, 1)
%             for ylon = 1:size(futureData, 2)
%                 if futureData(xlat, ylon, d, s) >= exposureThreshold
%                     selGrid(xlat, ylon) = 1;
%                 end
%             end
%         end
%         
%         for ssp = ssps
%             futurePopCount(s, d, ssp) = hh_countPop({lat, lon, selGrid}, region, [testPeriodYears(1+((d-1)*10))], ssp, popRegrid);
%             constPopCount(s, d, ssp) = hh_countPop({lat, lon, selGrid}, region, [2010], ssp, popRegrid);
%         end
%         
%     end
%     
%     for ssp = ssps
%         constClimateCount(d, ssp) = hh_countPop({lat, lon, meanBaseSelGrid}, region, [testPeriodYears(1+((d-1)*10))], ssp, popRegrid);
%     end
%     
% end

futurePopCountSorted = [];
constPopCountSorted = [];
constClimateCountSorted = constClimateCount;

% average over models and ssps
%mmBasePopCount = nanmean(nanmean(basePopCount, 3), 1);
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
        for s = 1:size(futurePopCount, 3)
            interactionEffect(j, i, s) = squeeze(futurePopCount(j, i, s)) - squeeze(climatePopEffect(j, i, s)) - squeeze(popPopEffect(i, s))';
        end
    end
end

futurePopCountSorted = [];
climPopEffectSorted = [];
popPopEffectSorted = [];
interactionEffectSorted = [];

% combine ssps, models, & ensembles into scenario list
for d = 1:size(futurePopCount, 2)
    ind = 1;
    for ssp = 1:size(futurePopCount, 3)
        for c = 1:size(futurePopCount, 1)
            futurePopCountSorted(d, ind) = futurePopCount(c, d, ssp);
            climPopEffectSorted(d, ind) = climatePopEffect(c, d, ssp);
            interactionEffectSorted(d, ind) = interactionEffect(c, d, ssp);
            ind = ind + 1;
        end
    end
    
    futurePopCountSorted(d, :) = sort(futurePopCountSorted(d, :));
    climPopEffectSorted(d, :) = sort(climPopEffectSorted(d, :));
    interactionEffectSorted(d, :) = sort(interactionEffectSorted(d, :));
    popPopEffectSorted(d, :) = sort(popPopEffect(d, :));
end

prcRange = [10 90];

% calculate uncertainties
climE = [];
popE = [];
intE = [];
futPopE = [];

climE = [climPopEffectSorted(:, round((prcRange(1)/100.0)*size(climPopEffectSorted, 2))), ...
            climPopEffectSorted(:, round((prcRange(2)/100.0)*size(climPopEffectSorted, 2)))];

popE = [popPopEffectSorted(:, round((prcRange(1)/100.0)*size(popPopEffectSorted, 2))), ...
            popPopEffectSorted(:, round((prcRange(2)/100.0)*size(popPopEffectSorted, 2)))];

intE = [interactionEffectSorted(:, round((prcRange(1)/100.0)*size(interactionEffectSorted, 2))), ...
           interactionEffectSorted(:, round((prcRange(2)/100.0)*size(interactionEffectSorted, 2)))];

futPopE= [futurePopCountSorted(:, round((prcRange(1)/100.0)*size(futurePopCountSorted, 2))), ...
             futurePopCountSorted(:, round((prcRange(2)/100.0)*size(futurePopCountSorted, 2)))];

% save population data
popResult = {{futurePopCountSorted, futPopE}, {climPopEffectSorted, climE}, {popPopEffectSorted, popE}, {interactionEffectSorted, intE}};
save(['population-exposure-' baseVar '-' rcp '-' num2str(exposureThreshold)], 'popResult');
         
mmClimatePopEffect = nanmean(climPopEffectSorted, 2);
mmPopPopEffect = nanmean(popPopEffectSorted, 2);
mmInteractionEffect = nanmean(interactionEffectSorted, 2);
mmFutPopEffect = nanmean(futurePopCountSorted, 2);

% calc decadal means
futureDecX = (testPeriodYears(1))+5:10:(testPeriodYears(end)-5);
mmFutureDecY = [];
mmFutureDecYerr = [];

futureDecY = [];
futureDecYerr = [];

for d = 1:size(mmClimatePopEffect, 1)
    futureDecY(d, 1) = mmPopPopEffect(d);
    futureDecY(d, 2) = mmClimatePopEffect(d);
    futureDecY(d, 3) = mmInteractionEffect(d);
    %futureDecY(d, 4) = popE(d)+climE(d)+intE(d);
    futureDecY(d, 4) = mmFutPopEffect(d);
    
    futureDecYerr(d, 1, :) = [popE(d, 1)-futureDecY(d, 1) popE(d, 2)-futureDecY(d, 1)];
    futureDecYerr(d, 2, :) = [climE(d, 1)-futureDecY(d, 2) climE(d, 2)-futureDecY(d, 2)];
    futureDecYerr(d, 3, :) = [intE(d, 1)-futureDecY(d, 3) intE(d, 2)-futureDecY(d, 3)];
    futureDecYerr(d, 4, :) = [futPopE(d, 1)-futureDecY(d, 4) futPopE(d, 2)-futureDecY(d, 4)];
end

plotTitle = ['Exposure to ' num2str(exposureThreshold) char(176) 'C wet bulb, global'];
fileTitle = ['heatExposure-' baseDataset '-' baseVar '-' num2str(exposureThreshold) '-' rcp '-ssp' num2str(ssp) '-' region];

saveData = struct('futureDecX', futureDecX, ...
                  'futureDecY', futureDecY, ...
                  'futureDecYerr', futureDecYerr, ...
                  'Xlabel', 'Year', ...
                  'Ylabel', 'Number exposed', ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', fileTitle, ...
                  'exportFormat', exportformat);

sendToPlotly = false;
              
if sendToPlotly

    trace1 = struct('x', { saveData.futureDecX }, ...
                  'y', saveData.futureDecY(:,1), ...
                  'name', 'Population effect', ...
                  'error_y', struct(...
                    'type', 'data', ...
                    'symmetric', false, ...
                    'visible', true, ...
                    'array', futureDecYerr(:, 1, 2), ...
                    'arrayminus', abs(futureDecYerr(:, 1, 1))), ...
                  'type', 'bar');
              
	trace2 = struct('x', { saveData.futureDecX }, ...
                  'y', saveData.futureDecY(:,2), ...
                  'name', 'Climate effect', ...
                  'error_y', struct(...
                    'type', 'data', ...
                    'symmetric', false, ...
                    'visible', true, ...
                    'array', futureDecYerr(:, 2, 2), ...
                    'arrayminus', abs(futureDecYerr(:, 2, 1))), ...
                  'type', 'bar');
    trace3 = struct('x', { saveData.futureDecX }, ...
                  'y', saveData.futureDecY(:,3), ...
                  'name', 'Interaction effect', ...
                  'error_y', struct(...
                    'type', 'data', ...
                    'symmetric', false, ...
                    'visible', true, ...
                    'array', futureDecYerr(:, 3, 2), ...
                    'arrayminus', abs(futureDecYerr(:, 3, 1))), ...
                  'type', 'bar');
              
	trace4 = struct('x', { saveData.futureDecX }, ...
                  'y', saveData.futureDecY(:,4), ...
                  'name', 'Total', ...
                  'error_y', struct(...
                    'type', 'data', ...
                    'symmetric', false, ...
                    'visible', true, ...
                    'array', futureDecYerr(:, 4, 2), ...
                    'arrayminus', abs(futureDecYerr(:, 4, 1))), ...
                  'type', 'bar');
              
    plotlyData = {trace1, trace2, trace3, trace4};
    plotlyLayout = struct('barmode', 'group');
    %   plotlyResponse = plotly(plotlyData, struct('layout', plotlyLayout, 'filename', ['heat-' num2str(exposureThreshold) 'c-' rcp '-all-ssp'], 'fileopt', 'overwrite'));
end

figure('Color', [1, 1, 1]);
hold on;
grid on;
axis square;
box on;

[B, E] = barwitherr(saveData.futureDecYerr, saveData.futureDecX, saveData.futureDecY, 'LineWidth', 1, 'BarWidth', 1);

set(B(1), 'FaceColor', [0.122, 0.467, 0.706]);
set(E(1), 'Color', [0.1, 0.1, 0.1]);
set(E(1), 'LineWidth', 2);

set(B(2), 'FaceColor', [1, 0.5, 0.055]);
set(E(2), 'Color', [0.1, 0.1, 0.1]);
set(E(2), 'LineWidth', 2);

set(B(3), 'FaceColor', [0.173, 0.627, 0.173]);
set(E(3), 'Color', [0.1, 0.1, 0.1]);
set(E(3), 'LineWidth', 2);

set(B(4), 'FaceColor', [0.839, 0.153, 0.157]);
set(E(4), 'Color', [0.1, 0.1, 0.1]);
set(E(4), 'LineWidth', 2);

%title(saveData.plotTitle, 'FontSize', 24);
title(['35' char(176) 'C, RCP 8.5'], 'FontSize', 34);
xlabel(saveData.Xlabel, 'FontSize', 36);
ylabel(saveData.Ylabel, 'FontSize', 36);
set(gca, 'FontSize', 32);
set(gcf, 'Position', get(0,'Screensize'));

l = legend(B, 'population effect', 'climate effect', 'combined effect', 'total change');
set(l, 'FontSize', 32, 'Location', 'northwest');

ylim([0, inf]);
    
eval(['export_fig ' saveData.fileTitle '.' saveData.exportFormat ' -m2;']);
save([saveData.fileTitle '.mat'], 'saveData');
close all;
