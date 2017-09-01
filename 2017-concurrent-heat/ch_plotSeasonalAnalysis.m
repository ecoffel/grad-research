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

anomalyStr = 'total';
if showChgAnomalies
    anomalyStr = 'anomaly';
end


load waterGrid;
load lat;
load lon;
waterGrid = logical(waterGrid);

bowenBaseDir = '2017-concurrent-heat\bowen\';
tempBaseDir = '2017-concurrent-heat\bowen\temp-chg-data\';

% all available models for both bowen and tasmax
availModels = {};

% dimensions: x, y, month, model
bowenHistorical = [];
bowenChg = [];
tasmaxChg = [];
tasminChg = [];

regionNames = {'World', ...
                'Central U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa'};
regionAb = {'world', ...
            'us-cent', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[35 46], [-107 -88] + 360]; ...     % central us
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
    if exist('curBowenHistorical') && exist('curBowenRcp85') && exist('curTasmaxRcp85') && exist('curTasminRcp85')
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
        
        % record historical bowen
        bowenHistorical(:, :, length(availModels), :) = curBowenHistorical;
        
        % take difference between rcp85 and historical
        % dimensions: x, y, month, model
        bowenChg(:, :, length(availModels), :) = (curBowenRcp85 - curBowenHistorical);
        
        tasmaxChg(:, :, length(availModels), :) = curTasmaxRcp85;
        tasminChg(:, :, length(availModels), :) = curTasminRcp85;
    end
    
    clear curBowenHistorical curBowenRcp85 curTasmaxRcp85 curTasminRcp85;
    
end

% average bowen (absolute) and temperature change over each region
bowenRegionsHistorical = {};
bowenRegionsChange = {};
tasmaxRegionsChange = {};
tasminRegionsChange = {};

% loop over regions and extract bowen & tasmax change data
for i = 1:length(regionNames)
    
    % calculate spatial mean historical bowen
    bowenRegionsHistorical{i} = squeeze(nanmean(nanmean(bowenHistorical(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1)); 

    bowenRegionsChange{i} = squeeze(nanmean(nanmean(bowenChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1)); 

    tasmaxRegionsChange{i} = squeeze(nanmean(nanmean(tasmaxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1));
    
    tasminRegionsChange{i} = squeeze(nanmean(nanmean(tasminChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1));
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



% plot ----------------------------------------------------

% loop over all regions for plotting
for i = 1:length(regionNames)
    
    % list of models to use for this region
    modelSubset = availModels;
    
%     switch regionAb{i}
% 
%         %         {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%     %               'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%     %               'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%     %               'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%     %               'mpi-esm-mr', 'mri-cgcm3'};
% 
% 
%         case 'us-cent'
%             modelSubset = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%                   'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%                   'gfdl-cm3', 'hadgem2-cc', ...
%                   'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%                   'mpi-esm-mr'};
%         case 'us-se'
%             modelSubset = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%                   'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%                   'gfdl-cm3', 'hadgem2-cc', ...
%                   'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%                   'mpi-esm-mr'};
%         case 'europe'
%             modelSubset = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%                   'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%                   'gfdl-cm3', 'hadgem2-cc', ...
%                   'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%                   'mpi-esm-mr'};
%         case 'med'
%             modelSubset = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%                   'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%                   'gfdl-cm3', 'hadgem2-cc', ...
%                   'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%                   'mpi-esm-mr'};
%         case 'sa-n'
%             modelSubset = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%                   'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%                   'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%                   'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%                   'mpi-esm-mr', 'mri-cgcm3'};
%         case 'amazon'
%             modelSubset = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%                   'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%                   'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%                   'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%                   'mpi-esm-mr', 'mri-cgcm3'};
%         case 'africa-central'
%             modelSubset = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
%                       'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%                       'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%                       'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
%                       'mpi-esm-mr', 'mri-cgcm3'};
%     end

    
    % calculate indices for 25th/75th percentile bowen across models
    lowInd = max(round(0.25 * length(modelSubset)), 1);
    highInd = min(round(0.75 * length(modelSubset)), length(models));

    % indices of models for this region
    modelInd = [];
    
    for m = 1:length(availModels)
        % check if current model is a member of subset for this region
        if ismember(availModels{m}, modelSubset)
            modelInd(end+1) = m;
        end
    end
    
    % cancluate change anomalies if needed
    if showChgAnomalies
        annMeanBowen = nanmean(bowenRegionsChange{i}, 2);
        annMeanTasmax = nanmean(tasmaxRegionsChange{i}, 2);
        annMeanTasmin = nanmean(tasminRegionsChange{i}, 2);
        bowenRegionsChange{i} = bowenRegionsChange{i} - repmat(annMeanBowen, 1, 12);
        tasmaxRegionsChange{i} = tasmaxRegionsChange{i} - repmat(annMeanTasmax, 1, 12);
        tasminRegionsChange{i} = tasminRegionsChange{i} - repmat(annMeanTasmin, 1, 12);
    end
    
    % limit to models for this region
    tasmaxRegionsChange{i} = tasmaxRegionsChange{i}(modelInd, :);
    tasminRegionsChange{i} = tasminRegionsChange{i}(modelInd, :);
    if showPercentChange
        bowenRegionsHistorical{i} = bowenRegionsHistorical{i}(modelInd, :);
    end
    bowenRegionsChange{i} = bowenRegionsChange{i}(modelInd, :);
    
    % mean temperature change across models
    tasmaxY = squeeze(nanmean(tasmaxRegionsChange{i}, 1));
    tasminY = squeeze(nanmean(tasminRegionsChange{i}, 1));
    
    % sort models by temperature change to calculate error range
    tasmaxRegionsChange{i} = sort(tasmaxRegionsChange{i}, 1);
    tasminRegionsChange{i} = sort(tasminRegionsChange{i}, 1);
    
    % error is full range across models
    tasmaxErr = squeeze(range(tasmaxRegionsChange{i}(lowInd:highInd, :), 1)) ./ 2.0;
    tasminErr = squeeze(range(tasmaxRegionsChange{i}(lowInd:highInd, :), 1)) ./ 2.0;
    
    % if only one model, err will be 0 so generate an array of zeros
    if tasmaxErr == 0
        tasmaxErr = zeros(12, 1);
    end
    
    if tasminErr == 0
        tasminErr = zeros(12, 1);
    end

    % test for significant change in each month at 95th percentile
    bowenSig = [];
    for month = 1:12
        bowenSig(month) = ttest(bowenRegionsChange{i}(:, month), 0, 'Alpha', 0.05);
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
    %hold on;
    grid on;
    box on;

    [ax, p1, p2] = shadedErrorBaryy(1:12, tasmaxY, tasmaxErr, 'r', ...
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
    
    [ax2, p3, p4] = shadedErrorBaryy(1:12, tasminY, tasminErr, 'b', ...
                                    1:12, bowenY, bowenErr, 'g');
    hold(ax2(1));
    hold(ax2(2));
    box(ax(1), 'on');
    set(p3.mainLine, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 3);
    set(p3.patch, 'FaceColor', [85/255.0, 158/255.0, 237/255.0]);
    set(p3.edge, 'Color', 'w');
    % this is a copy of the bowen line from p2, so make it invisible
    set(p4.mainLine, 'visible', 'off');
    set(p4.patch, 'visible', 'off');
    set(p4.edge, 'visible', 'off');
    axis(ax2(1), 'square');
    axis(ax2(2), 'square');

    % plot bowen zero line 
    plot(ax(2), 1:12, zeros(1,12), '--', 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 2);

    if showLegend
        leg = legend([p1.mainLine, p3.mainLine, p2.mainLine], 'Tx', 'Tn', 'Bowen ratio');
        set(leg, 'location', 'northwest', 'FontSize', 30);
    end
    
    % plot significance indicators
    for month = 1:12
        p3 = plot(ax(2), month, bowenY(month), 'o', 'MarkerSize', 15, 'Color', [25/255.0, 158/255.0, 56/255.0], 'MarkerEdgeColor', 'k');
        if bowenSig(month)
            set(p3, 'LineWidth', 3, 'MarkerFaceColor', [25/255.0, 158/255.0, 56/255.0]);
        else
            set(p3, 'LineWidth', 3);
        end
        uistack(p3, 'top');
    end

    xlabel('Month', 'FontSize', 30);
    set(ax(1), 'XTick', 1:12);
    set(ax(2), 'XTick', []);
    
    if showPercentChange
        set(ax(2), 'YLim', [-50 200], 'YTick', [-50 0 50 100 150 200]);
        set(ax2(2), 'YLim', [-50 200], 'YTick', [-50 0 50 100 150 200]);
        ylabel(ax(2), 'Bowen ratio change (percent)', 'FontSize', 30);
    elseif showChgAnomalies
        set(ax(2), 'YLim', [-2 2], 'YTick', -2:2);
        set(ax2(2), 'YLim', [-2 2], 'YTick', -2:2);
        ylabel(ax(2), 'Bowen ratio anomaly change', 'FontSize', 30);
    else
        set(ax(2), 'YLim', [-2 4], 'YTick', [-2 -1 0 1 2 3 4]);
        set(ax2(2), 'YLim', [-2 4], 'YTick', [-2 -1 0 1 2 3 4]);
        ylabel(ax(2), 'Bowen ratio change', 'FontSize', 30);
    end
    set(ax(1), 'YColor', [239/255.0, 71/255.0, 85/255.0], 'FontSize', 24);
    set(ax2(1), 'YColor', [239/255.0, 71/255.0, 85/255.0], 'FontSize', 24);
    set(ax(2), 'YColor', [25/255.0, 158/255.0, 56/255.0], 'FontSize', 24);
    set(ax2(2), 'YColor', [25/255.0, 158/255.0, 56/255.0], 'FontSize', 24);
    if showChgAnomalies
        ylabel(ax(1), ['Temperature anomaly change (' char(176) 'C)'], 'FontSize', 30);
        set(ax(1), 'YLim', [-3 3], 'YTick', -3:3);
        set(ax2(1), 'YLim', [-3 3], 'YTick', -3:3);
    else
        ylabel(ax(1), ['Temperature change (' char(176) 'C)'], 'FontSize', 30);
        set(ax(1), 'YLim', [0 8], 'YTick', 0:8);
        set(ax2(1), 'YLim', [0 8], 'YTick', 0:8);
    end
    
    title(regionNames{i}, 'FontSize', 34);
    set(gcf, 'Position', get(0,'Screensize'));
    if showPercentChange
        export_fig(['seasonal-analysis-' regionAb{i} '-' tasmaxMetric '-' tasminMetric '-' anomalyStr '-percent.png'], '-m1');
    else
        export_fig(['seasonal-analysis-' regionAb{i} '-' tasmaxMetric '-' tasminMetric '-' anomalyStr '-absolute.png'], '-m1');
    end
    close all;
end
