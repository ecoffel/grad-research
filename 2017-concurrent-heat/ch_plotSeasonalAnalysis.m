% plot monthly max temperature change alongside mean monthly bowen ratio changes

modelSubset = 'all';
tempMetric = 'monthly-mean-max';
showMaps = false;
showMonthlyMaps = false;

% show the percentage change in bowen ratio or the absolute change
showPercentChange = false;

load waterGrid;
load lat;
load lon;
waterGrid = logical(waterGrid);

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
bowenHistorical = [];
bowenChg = [];
tasmaxChg = [];

regionNames = {'World', ...
                'Eastern U.S.', ...
                'Western Europe', ...
                'Amazon', ...
                'India', ...
                'China', ...
                'Tropics'};
regionAb = {'world', ...
            'us', ...
            'europe', ...
            'amazon', ...
            'india', ...
            'china', ...
            'tropics'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 48], [-97 -62] + 360]; ...     % USNE
           [[35, 60], [-10+360, 20]]; ...       % Europe
           [[-10, 10], [-70, -40]+360]; ...     % Amazon
           [[8, 28], [67, 90]]; ...             % India
           [[20, 40], [100, 125]]; ...          % China
           [[-20 20], [0 360]]];                % Tropics
           
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
    
    % load pre-computed change data for tasmax under rcp85 in 2070-2080
    if exist([tasmaxBaseDir 'chgData-cmip5-seasonal-' tempMetric '-' models{m} '-rcp85-2070-2080.mat'], 'file')
        load([tasmaxBaseDir 'chgData-cmip5-seasonal-' tempMetric '-' models{m} '-rcp85-2070-2080.mat']);
        curTasmaxRcp85 = chgData;
    end
    
    % if both historical and rcp85 data exist and were loaded for this
    % model, add them to the change data
    if exist('curBowenHistorical') && exist('curBowenRcp85') && exist('curTasmaxRcp85')
        availModels{end+1} = models{m};
        
        % NaN-out all water gridcells
        for month = 1:size(curBowenHistorical, 3)
            % bowen historical
            curGrid = curBowenHistorical(:, :, month);
            curGrid(waterGrid) = NaN;
            curBowenHistorical(:, :, month) = curGrid;

            % bowen future
            curGrid = curBowenRcp85(:, :, month);
            curGrid(waterGrid) = NaN;
            curBowenRcp85(:, :, month) = curGrid;

            % tasmax change
            curGrid = curTasmaxRcp85(:, :, month);
            curGrid(waterGrid) = NaN;
            curTasmaxRcp85(:, :, month) = curGrid;
        end
        
        % record historical bowen
        bowenHistorical(:, :, length(availModels), :) = curBowenHistorical;
        
        % take difference between rcp85 and historical
        % dimensions: x, y, month, model
        bowenChg(:, :, length(availModels), :) = (curBowenRcp85 - curBowenHistorical);
        
        tasmaxChg(:, :, length(availModels), :) = curTasmaxRcp85;
    end
    
    clear curBowenHistorical curBowenRcp85 curTasmaxRcp85;
    
end

% average bowen (absolute) and temperature change over each region
bowenRegionsHistorical = {};
bowenRegionsChange = {};
tasmaxRegionsChange = {};

% loop over regions and extract bowen & tasmax change data
for i = 1:length(regionNames)
    
    if showPercentChange
        % calculate spatial mean historical bowen
        bowenRegionsHistorical{i} = squeeze(nanmean(nanmean(bowenHistorical(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1)); 
        % and spatial mean change
        bowenRegionsChange{i} = squeeze(nanmean(nanmean(bowenChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1)); 
    else
        bowenRegionsChange{i} = squeeze(nanmean(nanmean(bowenChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1)); 
    end
    
    tasmaxRegionsChange{i} = squeeze(nanmean(nanmean(tasmaxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1));
end

% plot maps of change in each region
if showMaps
    for i = 1:length(regionNames)
        curLat = lat(regionLatLonInd{i}{1}, regionLatLonInd{i}{2});
        curLon = lon(regionLatLonInd{i}{1}, regionLatLonInd{i}{2});
        
        % take spatial average over region
        curTasmax = nanmean(nanmean(tasmaxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 4), 3);
        
        [fg,cb] = plotModelData({curLat, curLon, curTasmax}, 'world', 'caxis', [0 8]);
        set(gca, 'Color', 'none');
        title(regionNames{i}, 'FontSize', 24);
        set(gca, 'FontSize', 24);
        xlabel(cb, ['Temperature change (' char(176) 'C)'], 'FontSize', 24);
    end
end

% show maps for each month of bowen ratio change
if showMonthlyMaps
    % historical bowen
%     figure('Color', [1,1,1]);
%     for month = 1:12
%         subplot(3, 4, month);
%         hold on;
%         plotModelData({lat,lon,nanmean(bowenHistorical(:,:,:,month), 3)}, 'world', 'caxis', [0 5], 'nonewfig', true);
%         title(['month ' num2str(month)]);
%     end
%     % reduce spacing between subplots
%     spaceplots(1,[0.005 0.005 0.005 0.005],[0.001 0.001 0.001 0.001]);
%     cb = colorbar('Location', 'southoutside');
    
    % bowen change absolute
    figure('Color', [1,1,1]);
    for month = 1:12
        subplot(3, 4, month);
        hold on;
        plotModelData({lat,lon,nanmean(bowenChg(:,:,:,month), 3)}, 'world', 'caxis', [-2 5], 'nonewfig', true);
        title(['month ' num2str(month)]);
    end
    % reduce spacing between subplots
    spaceplots(1,[0.005 0.005 0.005 0.005],[0.001 0.001 0.001 0.001]);
    cb = colorbar('Location', 'southoutside');
    
    % bowen change percentage
    figure('Color', [1,1,1]);
    for month = 1:12
        subplot(3, 4, month);
        hold on;
        plotModelData({lat,lon,nanmean((bowenChg(:,:,:,month)-bowenHistorical(:,:,:,month)) ./ bowenHistorical(:,:,:,month) .* 100, 3)}, 'world', 'caxis', [-100 100], 'nonewfig', true);
        title(['month ' num2str(month)]);
    end
    % reduce spacing between subplots
    spaceplots(2,[0.005 0.005 0.005 0.005],[0.001 0.001 0.001 0.001]);
    cb = colorbar('Location', 'southoutside');
    
    % temp change
%     figure('Color', [1,1,1]);
%     for month = 1:12
%         subplot(3, 4, month);
%         hold on;
%         plotModelData({lat,lon,nanmean(tasmaxChg(:,:,:,month), 3)}, 'world', 'caxis', [0 8], 'nonewfig', true);
%         title(['month ' num2str(month)]);
%     end
%     % reduce spacing between subplots
%     spaceplots(3,[0.005 0.005 0.005 0.005],[0.001 0.001 0.001 0.001]);
%     cb = colorbar('Location', 'southoutside');
end

% calculate indices for 25th/75th percentile bowen across models
lowInd = max(round(0.25 * length(availModels)), 1);
highInd = min(round(0.75 * length(availModels)), length(models));

% plot ----------------------------------------------------

% loop over all regions for plotting
for i = 1:length(regionNames)
    
    % mean temperature change across models
    tempY = squeeze(nanmean(tasmaxRegionsChange{i}, 1));
    
    % sort models by temperature change to calculate error range
    tasmaxRegionsChange{i} = sort(tasmaxRegionsChange{i}, 1);
    
    % error is range across 25-75% models 
    tempErr = squeeze(range(tasmaxRegionsChange{i}(lowInd:highInd, :), 1)) ./ 2.0;
    
    % if only one model, err will be 0 so generate an array of zeros
    if tempErr == 0
        tempErr = zeros(12, 1);
    end
    
    if showPercentChange
        % average over models and then calculate total prc change
        bowenY = squeeze(nanmean(bowenRegionsChange{i}, 1)) ./ squeeze(nanmean(bowenRegionsHistorical{i}, 1)) .* 100;
        
        % first calculate % change for each model/month
        bowenErr = bowenRegionsChange{i} ./ bowenRegionsHistorical{i} .* 100;
        % now sort by model
        bowenErr = sort(bowenErr, 1);
        % now find range across 25-75% models
        bowenErr = squeeze(range(bowenErr(lowInd:highInd, :), 1) / 2.0);
    else
        % calculate mean change across models
        bowenY = squeeze(nanmean(bowenRegionsChange{i}, 1));
        % sort, and take range across 25-75%
        bowenRegionsChange{i} = sort(bowenRegionsChange{i}, 1);
        bowenErr = squeeze(range(bowenRegionsChange{i}(lowInd:highInd, :), 1)) ./ 2.0;
    end
    
    % if only one model, err will be 0 so generate an array of zeros
    if bowenErr == 0
        bowenErr = zeros(12, 1);
    end
    
    f = figure('Color',[1,1,1]);
    hold on;
    grid on;
    box on;

    [ax, p1, p2] = shadedErrorBaryy(1:12, tempY, tempErr, 'r', ...
                                    1:12, bowenY, bowenErr, 'g');
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
    set(ax(1), 'YLim', [0 7], 'YTick', 0:7);
    if showPercentChange
        set(ax(2), 'YLim', [-50 200], 'YTick', [-50 0 50 100 150 200]);
        ylabel(ax(2), 'Bowen ratio change (percent)', 'FontSize', 24);
    else
        set(ax(2), 'YLim', [-2 3], 'YTick', [-2 -1 0 1 2 3]);
        ylabel(ax(2), 'Bowen ratio change', 'FontSize', 24);
    end
    set(ax(1), 'YColor', [239/255.0, 71/255.0, 85/255.0], 'FontSize', 24);
    set(ax(2), 'YColor', [25/255.0, 158/255.0, 56/255.0], 'FontSize', 24);
    ylabel(ax(1), ['Tx change (' char(176) 'C)'], 'FontSize', 24);
    
    title(regionNames{i}, 'FontSize', 24);
    set(gcf, 'Position', get(0,'Screensize'));
    if showPercentChange
        export_fig(['seasonal-analysis-' regionAb{i} '-' modelSubset '-' tempMetric '-percent.png -m2;']);
    else
        export_fig(['seasonal-analysis-' regionAb{i} '-' modelSubset '-' tempMetric '-absolute.png -m2;']);
    end
    close all;
end
