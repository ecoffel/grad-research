% plot monthly max temperature change alongside mean monthly bowen ratio changes

modelSubset = 'all';
tempMetric = 'monthly-max';

if strcmp(modelSubset, 'all')
    % all models
    models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};

elseif strcmp(modelSubset, 'esm-only')
    % ESMs only
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cnrm-cm5', 'gfdl-esm2g', 'gfdl-esm2m', ...
                  'hadgem2-es', 'miroc-esm', ...
                  'mpi-esm-mr'};
elseif strcmp(modelSubset, 'no-esm')
    % no ESMs
    models = {'bcc-csm1-1-m', 'cmcc-cm', 'cmcc-cms', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'hadgem2-cc', 'inmcm4', 'ipsl-cm5a-mr', 'mri-cgcm3'};
end

bowenBaseDir = '2017-concurrent-heat\bowen\';
tasmaxBaseDir = '2017-concurrent-heat\tasmax\';

% all available models for both bowen and tasmax
availModels = {};

% dimensions: x, y, month, model
bowenChg = [];
tasmaxChg = [];

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
    
    % load pre-computed change data for tasmax under rcp85 in 2070-2080
    if exist([tasmaxBaseDir 'chgData-cmip5-seasonal-' tempMetric '-' models{m} '-rcp85-2070-2080.mat'], 'file')
        load([tasmaxBaseDir 'chgData-cmip5-seasonal-' tempMetric '-' models{m} '-rcp85-2070-2080.mat']);
        curTasmaxRcp85 = chgData;
    end
    
    % if both historical and rcp85 data exist and were loaded for this
    % model, add them to the change data
    if exist('curBowenHistorical') && exist('curBowenRcp85') && exist('curTasmaxRcp85')
        availModels{end+1} = models{m};
        
        % take difference between rcp85 and historical
        % dimensions: x, y, month, model
        bowenChg(:, :, length(availModels), :) = curBowenRcp85 - curBowenHistorical;
        
        tasmaxChg(:, :, length(availModels), :) = curTasmaxRcp85;
    end
    
    clear curBowenHistorical curBowenRcp85 curTasmaxRcp85;
    
end
          
load waterGrid;
load lat;
load lon;
waterGrid = logical(waterGrid);

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Europe', ...
                'Amazon', ...
                'India', ...
                'Tropics'};
regionAb = {'world', ...
            'us', ...
            'europe', ...
            'amazon', ...
            'india', ...
            'tropics'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 55], [-100 -62] + 360]; ...     % USNE
           [[35, 60], [-10+360, 40]]; ...       % Europe
           [[-20, 10], [-70, -40]+360]; ...     % Amazon
           [[8, 34], [67, 90]]; ...             % India
           [[-20 20], [0 360]]];                % Tropics
           
regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

% sort change data by model
bowenChg = sort(bowenChg, 3);
tasmaxChg = sort(tasmaxChg, 3);

% NaN-out all water gridcells
for model = 1:size(bowenChg, 3)
    for month = 1:size(bowenChg, 4)
        % bowen
        curGrid = bowenChg(:, :, model, month);
        curGrid(waterGrid) = NaN;
        bowenChg(:, :, model, month) = curGrid;
        
        % tasmax
        curGrid = tasmaxChg(:, :, model, month);
        curGrid(waterGrid) = NaN;
        tasmaxChg(:, :, model, month) = curGrid;
    end
end

% average bowen and temperature change over each region
bowenRegionsChange = {};
tasmaxRegionsChange = {}

% loop over regions and extract bowen & tasmax change data
for i = 1:length(regionNames)
    bowenRegionsChange{i} = squeeze(nanmean(nanmean(bowenChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1));
    tasmaxRegionsChange{i} = squeeze(nanmean(nanmean(tasmaxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1));
end

% calculate indices for 25th/75th percentile bowen across models
lowInd = round(0.25 * length(availModels));
highInd = round(0.75 * length(availModels));

% plot ----------------------------------------------------

% loop over all regions for plotting
for i = 1:length(regionNames)

    f = figure('Color',[1,1,1]);
    hold on;
    grid on;
    box on;

    [ax, p1, p2] = shadedErrorBaryy(1:12, squeeze(nanmean(tasmaxRegionsChange{i}, 1)), squeeze(range(tasmaxRegionsChange{i}(lowInd:highInd, :), 1)) ./ 2.0, 'r', ...
                                    1:12, squeeze(nanmean(bowenRegionsChange{i}, 1)), squeeze(range(bowenRegionsChange{i}(lowInd:highInd, :), 1)) ./ 2.0, 'g');
    hold(ax(1));
    hold(ax(2));
    box(ax(1), 'on');
    set(p1.mainLine, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
    set(p1.patch, 'FaceColor', [239/255.0, 71/255.0, 85/255.0]);
    set(p1.edge, 'Color', 'w');
    set(p2.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
    set(p2.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
    set(p2.edge, 'Color', 'w');
    axis(ax(1), 'square');
    axis(ax(2), 'square');

    % plot bowen zero line 
    plot(ax(2), 1:12, zeros(1,12), '--', 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 2);

    xlabel('Month', 'FontSize', 24);
    set(ax(1), 'XTick', 1:12);
    set(ax(2), 'XTick', []);
    set(ax(1), 'YLim', [0 8], 'YTick', 0:8);
    set(ax(2), 'YLim', [-2 5], 'YTick', -2:5);
    set(ax(1), 'YColor', [239/255.0, 71/255.0, 85/255.0], 'FontSize', 24);
    set(ax(2), 'YColor', [25/255.0, 158/255.0, 56/255.0], 'FontSize', 24);
    ylabel(ax(1), ['Tx change (' char(176) 'C)'], 'FontSize', 24);
    ylabel(ax(2), 'Bowen ratio change', 'FontSize', 24);
    title(regionNames{i}, 'FontSize', 24);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['seasonal-analysis-' regionAb{i} '-' modelSubset '-' tempMetric '.png -m2;']);
    close all;
end
