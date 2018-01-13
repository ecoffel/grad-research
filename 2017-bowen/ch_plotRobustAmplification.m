
% should we look at changes in monthly temperature or changes in the annual
% maximum vs. the mean daily maximum
monthly = false;

showAllModels = true;

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

% ann-max: change in annual maximum minus change in mean daily maximum
% ann-min: change in annual minimum minus change in mean daily minimum
% ann-max-min: change in annual max minus change in annual min
% daily-max-min: change in daily max minus change in daily min
% warm-season-anom: warm season Tx change minus annual Tx change
chgMetric = 'ann-max';

modelSubset = 'all';

rcp = 'rcp85';
timePeriod = '2060-2080';
% 
modelsAll = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

% % for mrsos
% modelsAll = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%               'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
%               'mri-cgcm3', 'noresm1-m'};
          
          
% modelsBowen = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%               'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3'};
%           
% modelsSoil = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%                           'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%                           'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%                           'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%                           'mpi-esm-mr', 'mri-cgcm3'};
% 
% modelsSnow = {'access1-0', 'access1-3', 'bnu-esm', ...
%                   'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%                   'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%                   'hadgem2-es', 'mpi-esm-mr', 'mri-cgcm3'};

if strcmp(modelSubset, 'bowen')
    models = modelsBowen;
elseif strcmp(modelSubset, 'soil')
    models = modelsSoil;
elseif strcmp(modelSubset, 'snow')
    models = modelsSnow;
elseif strcmp(modelSubset, 'all')
    models = modelsAll;
end
            
regionNames = {'World', ...
                'Eastern U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa', ...
                'North Africa', ...
                'China'};
regionAb = {'world', ...
            'us-east', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent', ...
            'n-africa', ...
            'china'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[35 50], [-10+360 45]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]; ...              % north africa
           [[22 40], [105 122]]];               % china
                      
% if monthly
%     % monthly-mean-max or monthly-max
%     tempMetric = 'monthly-mean-max';
% 
%     tasmaxBaseDir = '2017-concurrent-heat\tasmax\';
%     dailyChg = [];
% 
%     % load temp change data for all models
%     for m = 1:length(models)
%         % load pre-computed monthly change data for tasmax under rcp85 in 2070-2080
%         if exist([tasmaxBaseDir 'chgData-cmip5-seasonal-' tempMetric '-' models{m} '-rcp85-2060-2080.mat'], 'file')
%             load([tasmaxBaseDir 'chgData-cmip5-seasonal-' tempMetric '-' models{m} '-rcp85-2060-2080.mat']);
%             curDailyChg = chgData;
% 
%             % NaN-out all water gridcells
%             for month = 1:size(curDailyChg, 3)
%                 % tasmax change
%                 curGrid = curDailyChg(:, :, month);
%                 curGrid(waterGrid) = NaN;
%                 curDailyChg(:, :, month) = curGrid;
%             end
% 
%             dailyChg(:, :, m, :) = curDailyChg;
%         end
% 
%         clear curTasmaxRcp85;
%     end
% 
%     % compute amplification - difference between month that warms the most and
%     % month that warms the least
%     amp = nanmax(dailyChg, [], 4) - nanmean(dailyChg, 4);
% else

% first change variable
chg1 = [];
% second change variable - subtracted from frst
chg2 = [];

for m = 1:length(models)
    
    % load and process change 1
    if strcmp(chgMetric, 'ann-max')
        load(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-ann-max-' models{m} '-' rcp '-' timePeriod '.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'ann-min')
        load(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-ann-min-' models{m} '-' rcp '-' timePeriod '.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'ann-max-min')
        load(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-ann-max-' models{m} '-' rcp '-' timePeriod '.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'daily-max-min')
        load(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-daily-max-' models{m} '-' rcp '-' timePeriod '.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'warm-season-anom')
        load(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-warm-season-tx-' models{m} '-' rcp '-' timePeriod '.mat']);
        curChg = chgData;        
    end

    % NaN-out all water gridcells
    for month = 1:size(curChg, 3)
        % tasmax change
        curGrid = curChg(:, :, month);
        curGrid(waterGrid) = NaN;
        curChg(:, :, month) = curGrid;
    end

    chg1(:, :, m, :) = curChg;


    clear curChg chgData;

    % load and process change 2
    if strcmp(chgMetric, 'ann-max')
        load(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-daily-max-' models{m} '-' rcp '-' timePeriod '.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'ann-min')
        load(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-daily-min-' models{m} '-' rcp '-' timePeriod '.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'ann-max-min')
        load(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-ann-min-' models{m} '-' rcp '-' timePeriod '.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'daily-max-min')
        load(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-daily-min-' models{m} '-' rcp '-' timePeriod '.mat']);
        curChg = chgData;
    elseif strcmp(chgMetric, 'warm-season-anom')
        load(['e:/data/projects/bowen/temp-chg-data/chgData-cmip5-daily-max-' models{m} '-' rcp '-' timePeriod '.mat']);
        curChg = chgData;
    end

    % NaN-out all water gridcells
    for month = 1:size(curChg, 3)
        % tasmax change
        curGrid = curChg(:, :, month);
        curGrid(waterGrid) = NaN;
        curChg(:, :, month) = curGrid;
    end

    chg2(:, :, m, :) = curChg;

    clear curChg chgData;
end

amp = chg1 - chg2;

% if strcmp(chgMetric, 'ann-max')
%     save('e:/data/projects/bowen/derived-chg/txxAmp.mat', 'amp');
% elseif strcmp(chgMetric, 'ann-min')
%     save('e:/data/projects/bowen/derived-chg/tnnAmp.mat', 'amp');
% end

% threshold in deg C to test for model agreement, if set to -1, search for
% max threshold that still allows for specified level of model agreement
ampThresh = -1;

% fraction of models that must agree on dir of change
prcAgree = 0.75;

if strcmp(chgMetric, 'ann-max') || strcmp(chgMetric, 'ann-min') || strcmp(chgMetric, 'daily-max-min')
    ampLevels = -3:0.5:3;
elseif strcmp(chgMetric, 'ann-max-min')
    ampLevels = -10:2:10;
end
%end

% how many models agree on change greater than threshold
ampLevel = zeros(size(lat, 1), size(lat, 2));
ampLevel(ampLevel == 0) = NaN;

% is the dir of change sig at the model grid box
ampAgree = zeros(size(lat, 1), size(lat, 2));

for xlat = 1:size(amp, 1)
    for ylon = 1:size(amp, 2)
        data = squeeze(amp(xlat, ylon, :));
        nn = find(~isnan(data));
        data = data(nn);
        
        if length(data) > 10
            med = median(data);
            ampLevel(xlat, ylon) = med;
            % show where not enough models agree
            ampAgree(xlat, ylon) = length(find(sign(data) == sign(med))) < round(prcAgree*size(amp,3));
        else
            ampLevel(xlat, ylon) = NaN;
        end
            
        
    end
end

ampAgree(1:15,:) = 0;
ampAgree(80:90,:) = 0;

% convert to percentage of mondels
%ampLevel = ampLevel ./ size(amp, 3) .* 100;

% don't display below 2/3 agreement
%ampCount(ampCount < 66) = NaN;

if showAllModels
    for m = 1:size(amp, 3)
        

        showColorbar = false;
        if m == 1
            showColorbar = true;
        end
        
        result = {lat, lon, amp(:,:,m)};
        saveData = struct('data', {result}, ...
                          'plotRegion', 'world', ...
                          'plotRange', [ampLevels(1) ampLevels(end)], ...
                          'cbXTicks', ampLevels, ...
                          'plotTitle', ['Amplification - ' models{m}], ...
                          'fileTitle', ['ampAgreement-' rcp '-' num2str(size(amp, 3)) '-cmip5-' chgMetric '-' models{m} '-' timePeriod '.eps'], ...
                          'plotXUnits', ['Amplification (' char(176) 'C)'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([],'*RdBu'), ...
                          'showColorbar', showColorbar, ...
                          'boxCoords', {regions([2,4,7,10], :)});
        plotFromDataFile(saveData);
        
        
        result = {lat, lon, chg1(:,:,m)};
        saveData = struct('data', {result}, ...
                          'plotRegion', 'world', ...
                          'plotRange', [0 10], ...
                          'cbXTicks', 0:10, ...
                          'plotTitle', ['TXx change - ' models{m}], ...
                          'fileTitle', ['txx-chg-' rcp '-' num2str(size(amp, 3)) '-cmip5-' chgMetric '-' models{m} '-' timePeriod '.eps'], ...
                          'plotXUnits', ['(' char(176) 'C)'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([],'YlOrRd'), ...
                          'showColorbar', showColorbar, ...
                          'boxCoords', {regions([2,4,7,10], :)});
        plotFromDataFile(saveData);
        
        
        
        result = {lat, lon, chg2(:,:,m)};
        saveData = struct('data', {result}, ...
                          'plotRegion', 'world', ...
                          'plotRange', [0 10], ...
                          'cbXTicks', 0:10, ...
                          'plotTitle', ['Tx change - ' models{m}], ...
                          'fileTitle', ['tx-chg-' rcp '-' num2str(size(amp, 3)) '-cmip5-' chgMetric '-' models{m} '-' timePeriod '.eps'], ...
                          'plotXUnits', ['(' char(176) 'C)'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([],'YlOrRd'), ...
                          'showColorbar', showColorbar, ...
                          'boxCoords', {regions([2,4,7,10], :)});
        plotFromDataFile(saveData);
    end
else
    
    result = {lat, lon, ampLevel};

    saveData = struct('data', {result}, ...
                      'plotRegion', 'world', ...
                      'plotRange', [ampLevels(1) ampLevels(end)], ...
                      'cbXTicks', ampLevels, ...
                      'plotTitle', ['Amplification'], ...
                      'fileTitle', ['ampAgreement-' rcp '-' num2str(size(amp, 3)) '-cmip5-' chgMetric '-' modelSubset '-' timePeriod '.eps'], ...
                      'plotXUnits', ['Amplification (' char(176) 'C)'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([],'*RdBu'), ...
                      'statData', ampAgree, ...
                      'boxCoords', {regions([2,4,7,10], :)});
    plotFromDataFile(saveData);
end
%plotModelData({lat, lon, nanmean(amp, 3)}, 'world', 'caxis', [-4 4]);

