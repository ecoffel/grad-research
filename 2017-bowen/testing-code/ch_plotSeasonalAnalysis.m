% plot monthly max temperature change alongside mean monthly bowen ratio changes

tasmaxMetric = 'monthly-mean-max';
tasminMetric = 'monthly-mean-min';
showMaps = false;
showMonthlyMaps = false;
% 
% models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%               'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

% for mrsos
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mri-cgcm3', 'noresm1-m'};
          

% show the percentage change in bowen ratio or the absolute change
showPercentChange = true;

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
    % load historical bowen ratio for this model if it exists
    if exist([bowenBaseDir 'monthly-mean-bowen-cmip5-historical-' models{m} '.mat'], 'file')
        load([bowenBaseDir 'monthly-mean-bowen-cmip5-historical-' models{m} '.mat']);
        curBowenHistorical = monthlyMeans;
        curBowenHistorical(abs(curBowenHistorical) > 100) = NaN;
    end
    
    % load rcp85 bowen ratio for this model if it exists
    if exist([bowenBaseDir 'monthly-mean-bowen-cmip5-rcp85-' models{m} '.mat'], 'file')
        load([bowenBaseDir 'monthly-mean-bowen-cmip5-rcp85-' models{m} '.mat']);
        curBowenRcp85 = monthlyMeans;
        curBowenRcp85(abs(curBowenRcp85) > 100) = NaN;
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
            curBowenHistorical(:, :, month) = curGrid;

            % bowen future
            curGrid = curBowenRcp85(:, :, month);
            curGrid(waterGrid) = NaN;
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

% save seasonal amplification
seasonalAmp = zeros(size(lat,1), size(lat,2), size(tasmaxChg,3));
seasonalAmp(seasonalAmp == 0) = NaN;
for xlat = 1:size(tasmaxChg, 1)
    for ylon = 1:size(tasmaxChg, 2)
        seasonalAmp(xlat, ylon, :) = squeeze(nanmean(tasmaxChg(xlat,ylon,:,seasons(hottestSeason(xlat, ylon), :)), 4)) - squeeze(nanmean(tasmaxChg(xlat, ylon, :, :), 4));
    end
end

save('e:/data/projects/bowen/derived-chg/seasonal-amp.mat', 'seasonalAmp');

% plot ----------------------------------------------------

% loop over all regions for plotting
for i = 1:length(regionNames)
    
    % calculate the hottest season for this region
    hotSeason = mode(reshape(hottestSeason(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}), ...
                                [numel(hottestSeason(regionLatLonInd{i}{1}, regionLatLonInd{i}{2})), 1]));
    
    % list of models to use for this region
    modelSubset = availModels;
    
    % take full range across models
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
    annMeanBowen = nanmean(bowenRegionsChange{i}, 2);
    annMeanTasmax = nanmean(tasmaxRegionsChange{i}, 2);
    annMeanTasmin = nanmean(tasminRegionsChange{i}, 2);
    if showChgAnomalies        
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
    tasmaxY = squeeze(nanmedian(tasmaxRegionsChange{i}, 1));
    tasminY = squeeze(nanmedian(tasminRegionsChange{i}, 1));
    
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

    if showPercentChange
        % average over models and then calculate total prc change
        bowenY = nanmedian(squeeze(bowenRegionsChange{i} ./ bowenRegionsHistorical{i}), 1) .* 100;
        
        % first calculate % change for each model/month
        bowenErr = bowenRegionsChange{i} ./ bowenRegionsHistorical{i} .* 100;
        % now sort by model
        bowenErr = sort(bowenErr, 1);
        % now find range across 25-75% models
        bowenErr = squeeze(range(bowenErr(lowInd:highInd, :), 1) ./ 2.0);
    else
        % calculate mean change across models
        bowenY = squeeze(nanmean(bowenRegionsChange{i}, 1));
        
        % sort, and take range across 25-75%
        bowenRegionsChange{i} = sort(bowenRegionsChange{i}, 1);
        bowenErr = squeeze(range(bowenRegionsChange{i}(lowInd:highInd, :), 1)) ./ 2.0;
    end
    
     % test for significant change in each month at 95th percentile
    bowenSig = [];
    % how many models agree on direction
    bowenSigAgreement = [];
    for month = 1:12
        %bowenSig(month) = kstest2(bowenRegionsChange{i}(:, month), zeros(size(bowenRegionsChange{i}(:, month))));
        bowenSig(month) = length(find(sign(bowenRegionsChange{i}(:, month) ./ bowenRegionsHistorical{i}(:, month)) == sign(bowenY(month)))) >= round(0.75*length(models));
        bowenSigAgreement(month) = length(find(sign(bowenRegionsChange{i}(:, month) ./ bowenRegionsHistorical{i}(:, month)) == sign(bowenY(month))));
    end
    
    % if only one model, err will be 0 so generate an array of zeros
    if bowenErr == 0
        bowenErr = zeros(12, 1);
    end
    
    f = figure('Color',[1,1,1]);
    %hold on;
    grid on;
    box on;

    data = {tasmaxY, nanmean(annMeanTasmax)};
    save(['2017-bowen/warming-' regionAb{i}], 'data');
    
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
    
    % plot hottest month line
    %plot(ax(1), [historicalHottestMonth(i) historicalHottestMonth(i)], [-1 10], 'k--', 'LineWidth', 2);
    % plot txx chg
    plot(ax(1), 1:12, ones(1,12) .* nanmedian(txxRegionsChange{i}), '--', 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 2);
    % and tnn chg
    plot(ax(1), 1:12, ones(1,12) .* nanmedian(tnnRegionsChange{i}), '--', 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 2);
    
    
    [ax2, p3, p4] = shadedErrorBaryy(1:12, tasminY, tasminErr, 'b', ...
                                    1:12, ones(12,1).*1000, zeros(12,1), 'g');
    hold(ax2(1));
    hold(ax2(2));
    box(ax(1), 'on');
    grid(ax(2),'on');
    set(p3.mainLine, 'Color', [85/255.0, 158/255.0, 237/255.0], 'LineWidth', 3);
    set(p3.patch, 'FaceColor', [85/255.0, 158/255.0, 237/255.0]);
    set(p3.edge, 'Color', 'w');
    % this is a copy of the bowen line from p2, so make it invisible
    set(p4.mainLine, 'visible', 'off');
    set(p4.patch, 'visible', 'off');
    set(p4.edge(1), 'visible', 'off');
    set(p4.edge(2), 'visible', 'off');
    axis(ax2(1), 'square');
    axis(ax2(2), 'square');

    if showCorr
        cor = corrcoef(tasmaxY, bowenY);
        cor = cor(2,1);
        
    end
    
    % plot bowen zero line 
    %plot(ax(2), 1:12, zeros(1,12), '--', 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 2);

    if showLegend
        leg = legend([p1.mainLine, p3.mainLine, p2.mainLine], 'Tx', 'Tn', 'Bowen ratio');
        set(leg, 'location', 'northwest', 'FontSize', 32);
    end
    
    % plot significance indicators
    for month = 1:12
        p3 = plot(ax(2), month, bowenY(month), 'o', 'MarkerSize', bowenSigAgreement(month), 'Color', [25/255.0, 158/255.0, 56/255.0], 'MarkerEdgeColor', 'k');
        if bowenSig(month)
            set(p3, 'LineWidth', 3, 'MarkerFaceColor', [25/255.0, 158/255.0, 56/255.0]);
        else
            set(p3, 'LineWidth', 3);
        end
        uistack(p3, 'top');
    end
    
    xlabel('Month', 'FontSize', 36);
    set(ax(1), 'XTick', 1:12, 'XTickLabels', {'J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'});
    set(ax(2), 'XTick', []);
    
    if showPercentChange
        set(ax(2), 'YLim', [-50 150], 'YTick', [-50 0 50 100 150]);
        set(ax2(2), 'YLim', [-50 150], 'YTick', [-50 0 50 100 150]);
        ylabel(ax(2), 'Bowen ratio change (%)', 'FontSize', 36);
    elseif showChgAnomalies
        set(ax(2), 'YLim', [-2 2], 'YTick', -2:2);
        set(ax2(2), 'YLim', [-2 2], 'YTick', -2:2);
        ylabel(ax(2), 'Bowen ratio anomaly change', 'FontSize', 36);
    else
        set(ax(2), 'YLim', [-2 4], 'YTick', [-2 -1 0 1 2 3 4]);
        set(ax2(2), 'YLim', [-2 4], 'YTick', [-2 -1 0 1 2 3 4]);
        ylabel(ax(2), 'Bowen ratio change', 'FontSize', 36);
    end
    set(ax(1), 'YColor', 'k', 'FontSize', 32);
    set(ax2(1), 'YColor', 'k', 'FontSize', 32);
    set(ax(2), 'YColor', 'k', 'FontSize', 32);
    set(ax2(2), 'YColor', 'k', 'FontSize', 32);
    if showChgAnomalies
        ylabel(ax(1), ['Temperature anomaly change (' char(176) 'C)'], 'FontSize', 36);
        set(ax(1), 'YLim', [-3 3], 'YTick', -3:3);
        set(ax2(1), 'YLim', [-3 3], 'YTick', -3:3);
    else
        ylabel(ax(1), ['Temperature change (' char(176) 'C)'], 'FontSize', 36);
        set(ax(1), 'YLim', [0 8.5], 'YTick', 0:8);
        set(ax2(1), 'YLim', [0 8.5], 'YTick', 0:8);
    end
    
    title(regionNames{i}, 'FontSize', 40);
    set(gcf, 'Position', get(0,'Screensize'));
    
    % set hottest season xtick label red
    curax = ax(1);
    curax.TickLabelInterpreter = 'tex';
    for m = 1:length(seasons(hotSeason,:))
        curax.XTickLabels{seasons(hotSeason,m)} = ['\color{red} ' curax.XTickLabels{seasons(hotSeason,m)}];
    end
    
    if showPercentChange
        %export_fig(['seasonal-analysis-' regionAb{i} '-' tasmaxMetric '-' tasminMetric '-' anomalyStr '-percent.png'], '-m4');
        print(['seasonal-analysis-' regionAb{i} '-' tasmaxMetric '-' tasminMetric '-' anomalyStr '-percent.eps'], '-depsc', '-r300');
    else
        %export_fig(['seasonal-analysis-' regionAb{i} '-' tasmaxMetric '-' tasminMetric '-' anomalyStr '-absolute.png'], '-m1');
        print(['seasonal-analysis-' regionAb{i} '-' tasmaxMetric '-' tasminMetric '-' anomalyStr '-absolute.eps'], '-depsc', '-r300');
    end
    close all;
end
