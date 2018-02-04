% plot monthly max temperature change alongside mean monthly bowen ratio changes

tasmaxMetric = 'monthly-mean-max';
tasminMetric = 'monthly-mean-min';
showMaps = false;
showMonthlyMaps = false;


models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          

% show the percentage change in bowen ratio or the absolute change
showPercentChange = false;

% subtact the annual mean change?
showChgAnomalies = false;

showLegend = true;

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
tasmaxChg = [];
tasmaxHistorical = [];
tasmaxFuture = [];
txxChg = [];

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
           [[-10, 7], [-75, -62]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]; ...              % north africa
           [[22 40], [105 122]]];               % china

regionLatLonInd = {};

% load hottest seasons data...
seasons = [[12 1 2];
               [3 4 5];
               [6 7 8];
               [9 10 11]];
load('2017-bowen/hottest-season-ncep.mat');

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

for m = 1:length(models)

    % load seasonal historical & future data
    load([tempBaseDir 'monthly-mean-tasmax-cmip5-historical-' models{m} '.mat']);
    curHistorical = monthlyMeans;
    load([tempBaseDir 'monthly-mean-tasmax-cmip5-rcp85-' models{m} '.mat']);
    curFuture = monthlyMeans;
    
    % load txx chg for this model 
    load([tempBaseDir 'chgData-cmip5-ann-max-' models{m} '-rcp85-2060-2080.mat']);
    curTxxChg = chgData;
    
    load([tempBaseDir 'chgData-cmip5-seasonal-' tasmaxMetric '-' models{m} '-rcp85-2060-2080.mat']);
    curTasmaxRcp85 = chgData;
    
    % if both historical and rcp85 data exist and were loaded for this
    % model, add them to the change data
    availModels{end+1} = models{m};

    % NaN-out all water gridcells
    for month = 1:size(curTasmaxRcp85, 3)
        % tasmax change
        curGrid = curTasmaxRcp85(:, :, month);
        curGrid(waterGrid) = NaN;
        curTasmaxRcp85(:, :, month) = curGrid;
    end

    % txx and tnn change
    curTxxChg(waterGrid) = NaN;

    % record txx and tnn chg
    txxChg(:, :, m) = curTxxChg;

    tasmaxChg(:, :, m, :) = curTasmaxRcp85;
    tasmaxHistorical(:, :, m, :) = curHistorical;
    tasmaxFuture(:, :, m, :) = curFuture;
    
    clear curTasmaxRcp85 curTxxChg curHistorical curFuture;
    
end

% average bowen (absolute) and temperature change over each region
tasmaxRegionsChange = {};
tasmaxRegionsHistorical = {};
tasmaxRegionsFuture = {};
txxRegionsChange = {};

% loop over regions and extract bowen & tasmax change data
for i = 1:length(regionNames)
    tasmaxRegionsChange{i} = squeeze(nanmean(nanmean(tasmaxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1));
    tasmaxRegionsHistorical{i} = squeeze(nanmean(nanmean(tasmaxHistorical(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1));
    tasmaxRegionsFuture{i} = squeeze(nanmean(nanmean(tasmaxFuture(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1));
    txxRegionsChange{i} = squeeze(nanmean(nanmean(txxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :), 2), 1));
end

% plot ----------------------------------------------------

% loop over all regions for plotting
for i = 4%1:length(regionNames)
    
    % calculate the hottest season for this region
    hotSeason = mode(reshape(hottestSeason(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}), ...
                                [numel(hottestSeason(regionLatLonInd{i}{1}, regionLatLonInd{i}{2})), 1]));
    
    % take full range across models
    lowInd = round(0.25 * length(models));
    highInd = round(0.75 * length(models));

    % mean temperature change across models
    tasmaxHistorical = squeeze(nanmedian(tasmaxRegionsHistorical{i}, 1));
    tasmaxFuture = squeeze(nanmedian(tasmaxRegionsFuture{i}, 1));
    tasmaxChg = squeeze(nanmedian(tasmaxRegionsChange{i}, 1));
    txxChg = squeeze(nanmedian(txxRegionsChange{i}, 1));
    
    f = figure('Color',[1,1,1]);
    hold on;
    box on;
    grid on;
    axis square;
    
    set(f, 'defaultAxesColorOrder', [[0 0 0]; [0 0 0]]);
    
    yyaxis left;
    p1 = plot(1:12, tasmaxHistorical, '-', 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 3);
    p2 = plot(1:12, tasmaxFuture, '-', 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
    ylabel(['Tx (' char(176) 'C)']);
    ylim([0 50]);
    set(gca, 'YTick', [0 10 20 30]);
    
    yyaxis right;
    p3 = plot(1:12, tasmaxChg, 'LineWidth', 3, 'Color', [249, 84, 244] ./ 255.0);
    plot([1 12], [txxChg txxChg], '--', 'Color', [249, 84, 244] ./ 255.0, 'LineWidth', 3);
    ylabel(['Tx change (' char(176) 'C)']);
    ylim([0 6]);
    set(gca, 'YTick', [3 4 5 6]);

    xlabel('Month', 'FontSize', 36);
    set(gca, 'XTick', 1:12, 'XTickLabels', {'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'});
    xlim([.5 12.5])
    
    ax = gca;
    ax.YAxis(1).Color = 'k';
    ax.YAxis(2).Color = [249, 84, 244] ./ 255.0;
    set(gca, 'FontSize', 36);
    legend([p1 p2 p3], {'Historical', 'Future', 'Change'});
    
    title(regionNames{i});
    set(gcf, 'Position', get(0,'Screensize'));
    
    export_fig seasonal-chg-4.eps;
    
    close all;
end
