% plot monthly max temperature change alongside mean monthly bowen ratio changes

tasmaxMetric = 'monthly-mean-max';
tasminMetric = 'monthly-mean-min';
showMaps = false;
showMonthlyMaps = false;

models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                      'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3'};

% show the percentage change in bowen ratio or the absolute change
showPercentChange = true;

% subtact the annual mean change?
showChgAnomalies = false;

showLegend = false;

% show correlation between Tx and Bowen
showCorr = true;

anomalyStr = 'total';
if showChgAnomalies
    anomalyStr = 'anomaly';
end

load waterGrid;
load lat;
load lon;
waterGrid = logical(waterGrid);

bowenBaseDir = 'e:\data\projects\bowen\bowen-chg-data\';
tempBaseDir = 'e:\data\projects\bowen\temp-chg-data\';

% all available models for both bowen and tasmax
availModels = {};

% dimensions: x, y, month, model
bowenHistorical = [];
bowenChg = [];
tasmaxChg = [];
txxChg = [];
tasminChg = [];
tnnChg = [];

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa'};
regionAb = {'world', ...
            'us-east', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[36 45], [-5+360, 40]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[-10 10], [15, 30]]];                % central africa

           
regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

for m = 1:length(models)
    % load historical bowen ratio for this model if it exists
    if exist([bowenBaseDir 'monthly-mean-historical-' models{m} '.mat'], 'file')
        load([bowenBaseDir 'monthly-mean-historical-' models{m} '.mat']);
        curBowenHistorical = monthlyMeans;
    end
    
    % load rcp85 bowen ratio for this model if it exists
    if exist([bowenBaseDir 'monthly-mean-rcp85-' models{m} '.mat'], 'file')
        load([bowenBaseDir 'monthly-mean-rcp85-' models{m} '.mat']);
        curBowenRcp85 = monthlyMeans;
    end
    
    % load txx chg for this model if it exists
    if exist([tempBaseDir 'chgData-cmip5-ann-max-' models{m} '-rcp85-2060-2080.mat'], 'file')
        load([tempBaseDir 'chgData-cmip5-ann-max-' models{m} '-rcp85-2060-2080.mat']);
        curTxxChg = chgData;
    end
    
    % load tnn chg for this model if it exists
    if exist([tempBaseDir 'chgData-cmip5-ann-min-' models{m} '-rcp85-2060-2080.mat'], 'file')
        load([tempBaseDir 'chgData-cmip5-ann-min-' models{m} '-rcp85-2060-2080.mat']);
        curTnnChg = chgData;
    end
    
    % load pre-computed change data for tasmax under rcp85 in 2070-2080
    if exist([tempBaseDir 'chgData-cmip5-seasonal-' tasmaxMetric '-' models{m} '-rcp85-2060-2080.mat'], 'file')
        load([tempBaseDir 'chgData-cmip5-seasonal-' tasmaxMetric '-' models{m} '-rcp85-2060-2080.mat']);
        curTasmaxRcp85 = chgData;
    end
    
    % load pre-computed change data for tasmin under rcp85 in 2070-2080
    if exist([tempBaseDir 'chgData-cmip5-seasonal-' tasminMetric '-' models{m} '-rcp85-2060-2080.mat'], 'file')
        load([tempBaseDir 'chgData-cmip5-seasonal-' tasminMetric '-' models{m} '-rcp85-2060-2080.mat']);
        curTasminRcp85 = chgData;
    end
    
    % if both historical and rcp85 data exist and were loaded for this
    % model, add them to the change data
    if exist('curBowenHistorical') && exist('curBowenRcp85') && exist('curTasmaxRcp85') && exist('curTasminRcp85') && ...
       exist('curTxxChg') && exist('curTnnChg')
        availModels{end+1} = models{m};
        
        % NaN-out all water gridcells
        for month = 1:size(curBowenHistorical, 3)
            % bowen historical
            curGrid = curBowenHistorical(:, :, month);
            curGrid(waterGrid) = NaN;
            % limit unreasonable bowens
            curGrid(curGrid > 10) = NaN;
            curBowenHistorical(:, :, month) = curGrid;

            % bowen future
            curGrid = curBowenRcp85(:, :, month);
            curGrid(waterGrid) = NaN;
            % limit unreasonable bowens
            curGrid(curGrid > 10) = NaN;
            curBowenRcp85(:, :, month) = curGrid;

            % tasmax change
            curGrid = curTasmaxRcp85(:, :, month);
            curGrid(waterGrid) = NaN;
            curTasmaxRcp85(:, :, month) = curGrid;
            
            % tasmin change
            curGrid = curTasminRcp85(:, :, month);
            curGrid(waterGrid) = NaN;
            curTasminRcp85(:, :, month) = curGrid;
        end
                
        % txx and tnn change
        curTxxChg(waterGrid) = NaN;
        curTnnChg(waterGrid) = NaN;
        
        % record txx and tnn chg
        txxChg(:, :, length(availModels)) = curTxxChg;
        tnnChg(:, :, length(availModels)) = curTnnChg;
        
        % record historical bowen
        bowenHistorical(:, :, length(availModels), :) = curBowenHistorical;
        
        % take difference between rcp85 and historical
        % dimensions: x, y, model, month
        bowenChg(:, :, length(availModels), :) = (curBowenRcp85 - curBowenHistorical);
        
        tasmaxChg(:, :, length(availModels), :) = curTasmaxRcp85;
        tasminChg(:, :, length(availModels), :) = curTasminRcp85;
    end
    
    clear curBowenHistorical curBowenRcp85 curTasmaxRcp85 curTasminRcp85 curTxxChg curTnnChg;
    
end

% average bowen (absolute) and temperature change over each region
bowenRegionsHistorical = {};
bowenRegionsChange = {};
tasmaxRegionsChange = {};
tasminRegionsChange = {};
txxRegionsChange = {};
tnnRegionsChange = {};

% loop over regions and extract bowen & tasmax change data
for i = 1:length(regionNames)
    
    % calculate spatial mean historical bowen
    bowenRegionsHistorical{i} = squeeze(nanmean(nanmean(bowenHistorical(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1)); 

    bowenRegionsChange{i} = squeeze(nanmean(nanmean(bowenChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1)); 

    tasmaxRegionsChange{i} = squeeze(nanmean(nanmean(tasmaxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1));
    
    tasminRegionsChange{i} = squeeze(nanmean(nanmean(tasminChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1));
    
    txxRegionsChange{i} = squeeze(nanmean(nanmean(txxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :), 2), 1));
    
    tnnRegionsChange{i} = squeeze(nanmean(nanmean(tnnChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :), 2), 1));
end

% plot ----------------------------------------------------

% loop over all regions for plotting
%for i = 1:length(regionNames)
i = 4;

    
    % cancluate change anomalies if needed
    annMeanBowen = nanmean(bowenRegionsChange{i}, 2);
    annMeanTasmax = nanmean(tasmaxRegionsChange{i}, 2);
    annMeanTasmin = nanmean(tasminRegionsChange{i}, 2);
    if showChgAnomalies        
        bowenRegionsChange{i} = bowenRegionsChange{i} - repmat(annMeanBowen, 1, 12);
        tasmaxRegionsChange{i} = tasmaxRegionsChange{i} - repmat(annMeanTasmax, 1, 12);
        tasminRegionsChange{i} = tasminRegionsChange{i} - repmat(annMeanTasmin, 1, 12);
    end
    
    % mean temperature change across models
    tasmaxChg = tasmaxRegionsChange{i};
    bowenChg = bowenRegionsChange{i};
    
    seasonMonths = [12 1 2];
    
    cMod = [];
    for model = 1:size(tasmaxChg,1)
        cMod(model,1) = corr(tasmaxChg(model,[12 1 2])',bowenChg(model,[12 1 2])');
        cMod(model,2) = corr(tasmaxChg(model,[3 4 5])',bowenChg(model,[3 4 5])');
        cMod(model,3) = corr(tasmaxChg(model,[6 7 8])',bowenChg(model,[6 7 8])');
        cMod(model,4) = corr(tasmaxChg(model,[9 10 11])',bowenChg(model,[9 10 11])');
    end
    
    cMonth = [];
    for month = 1:12
        cMonth(month) = corr(tasmaxChg(:,month),bowenChg(:,month));
    end
    figure('Color', [1,1,1]);
    hold on;
    axis square;
    box on;
    boxplot(cMod);
    set(gca, 'XTick', [1,2,3,4], 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});
    ylabel('T_{max} - Bowen Correlation');
    ylim([-1 1])
    set(gca, 'FontSize', 24);
    
%     figure('Color', [1,1,1]);
%     hold on;
%     axis square;
%     grid on;
%     box on;
%     
%end
