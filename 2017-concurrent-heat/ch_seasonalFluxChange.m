% plot monthly max temperature change alongside mean monthly bowen ratio changes

tempMetric = 'monthly-mean-max';

models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                      'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3'};

% show the percentage change in bowen ratio or the absolute change
showPercentChange = false;

% subtact the annual mean change?
showChgAnomalies = true;

anomalyStr = 'total';
if showChgAnomalies
    anomalyStr = 'anomaly';
end

load waterGrid;
load lat;
load lon;
waterGrid = logical(waterGrid);

dataBaseDir = 'f:/data/bowen/monthly-flux-temp';

% all available models for both bowen and tasmax
availModels = {};

regionNames = {'World', ...
                'Central U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'India', ...
                'West Africa', ...
                'Central Africa', ...
                'Tropics'};
regionAb = {'world', ...
            'us-cent', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'india', ...
            'africa-west', ...
            'africa-cent', ...
            'tropics'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[35 46], [-107 -88] + 360]; ...     % central us
           [[25 35], [-103 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[36 45], [-5+360, 40]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 1], [-75, -53]+360]; ...      % Amazon
           [[8, 26], [67, 90]]; ...             % India
           [[7, 20], [-15 + 360, 15]]; ...          % west Africa
           [[-10 10], [15, 30]]; ...            % central Africa
           [[-20 20], [0 360]]];                % Tropics

           
regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

% spatial mean temp change for each month
% dimensions: x, y, month, model
tasmaxChg = [];
% sensible heat flux
sFluxChg = [];
sFluxHistorical = [];
% latent heat flux
lFluxChg = [];
lFluxHistorical = [];

for model = 1:length(models)

    ['processing ' models{model} '...']
    
    % store current model flux data
    monthlyFluxTempHistorical = {};
    monthlyFluxTempRcp85 = {};

    % load historical bowen ratio for this model if it exists
    if exist([dataBaseDir '/monthlyFluxTemp-cmip5-historical-' models{model} '-1985-2004.mat'], 'file')
        load([dataBaseDir '/monthlyFluxTemp-cmip5-historical-' models{model} '-1985-2004.mat']);
        % temp, sflux, lflux
        monthlyFluxTempHistorical = monthlyFluxTemp;
    end

    % load rcp85 bowen ratio for this model if it exists
    if exist([dataBaseDir '/monthlyFluxTemp-cmip5-rcp85-' models{model} '-2060-2080.mat'], 'file')
        load([dataBaseDir '/monthlyFluxTemp-cmip5-rcp85-' models{model} '-2060-2080.mat']);
        % temp, sflux, lflux
        monthlyFluxTempRcp85 = monthlyFluxTemp;
    end

    % loaded data for historical and future
    if length(monthlyFluxTempHistorical) > 0 && length(monthlyFluxTempRcp85) > 0
        availModels{end+1} = models{model};

        for month = 1:12
            for xlat = 1:length(monthlyFluxTempHistorical{1}{month})
                for ylon = 1:length(monthlyFluxTempHistorical{1}{month}{1})
                    % historical temps for all years
                    curTempHistorical = monthlyFluxTempHistorical{1}{month}{xlat}{ylon};
                    % and future
                    curTempFuture = monthlyFluxTempRcp85{1}{month}{xlat}{ylon};
                    % calculate change or set to nan if no data (water
                    % grid)
                    if length(curTempHistorical) > 0 && length(curTempFuture) > 0
                        tasmaxChg(xlat, ylon, month, model) = nanmean(curTempFuture) - nanmean(curTempHistorical);
                    else
                        tasmaxChg(xlat, ylon, month, model) = NaN;
                    end

                    % s flux
                    curSFluxHistorical = monthlyFluxTempHistorical{2}{month}{xlat}{ylon};
                    curSFluxFuture = monthlyFluxTempRcp85{2}{month}{xlat}{ylon};
                    if length(curSFluxHistorical) > 0 && length(curSFluxFuture) > 0
                        sFluxChg(xlat, ylon, month, model) = nanmean(curSFluxFuture) - nanmean(curSFluxHistorical);
                        sFluxHistorical(xlat, ylon, month, model) = nanmean(curSFluxHistorical);
                    else
                        sFluxChg(xlat, ylon, month, model) = NaN;
                        sFluxHistorical(xlat, ylon, month, model) = NaN;
                    end

                    % l flux
                    curLFluxHistorical = monthlyFluxTempHistorical{3}{month}{xlat}{ylon};
                    curLFluxFuture = monthlyFluxTempRcp85{3}{month}{xlat}{ylon};
                    if length(curLFluxHistorical) > 0 && length(curLFluxFuture) > 0
                        lFluxChg(xlat, ylon, month, model) = nanmean(curLFluxFuture) - nanmean(curLFluxHistorical);
                        lFluxHistorical(xlat, ylon, month, model) = nanmean(curLFluxHistorical);
                    else
                        lFluxChg(xlat, ylon, month, model) = NaN;
                        lFluxHistorical(xlat, ylon, month, model) = NaN;
                    end
                end
            end
        end
    end

    clear monthlyFluxTempRcp85 monthlyFluxTempHistorical;

end

% average bowen (absolute) and temperature change over each region
lFluxRegionsHistorical = {};
lFluxRegionsChange = {};
sFluxRegionsHistorical = {};
sFluxRegionsChange = {};
tasmaxRegionsChange = {};

% loop over regions and extract bowen & tasmax change data
for i = 1:length(regionNames)
    
    if showPercentChange
        % calculate spatial mean historical bowen
        lFluxRegionsHistorical{i} = squeeze(nanmean(nanmean(lFluxHistorical(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1)); 
        sFluxRegionsHistorical{i} = squeeze(nanmean(nanmean(sFluxHistorical(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1)); 
        % and spatial mean change
        lFluxRegionsChange{i} = squeeze(nanmean(nanmean(lFluxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1)); 
        sFluxRegionsChange{i} = squeeze(nanmean(nanmean(sFluxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1)); 
    else
        lFluxRegionsChange{i} = squeeze(nanmean(nanmean(lFluxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1)); 
        sFluxRegionsChange{i} = squeeze(nanmean(nanmean(sFluxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1)); 
    end
    
    tasmaxRegionsChange{i} = squeeze(nanmean(nanmean(tasmaxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :), 2), 1));
end

% plot ----------------------------------------------------

% loop over all regions for plotting
for i = 1:length(regionNames)
    
    % list of models to use for this region
    modelSubset = availModels;
    
    switch regionAb{i}

        %         {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
    %               'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
    %               'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
    %               'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
    %               'mpi-esm-mr', 'mri-cgcm3'};


        case 'us-cent'
            modelSubset = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
    %         models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
    %               'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
    %               'hadgem2-cc', 'ipsl-cm5a-mr', 'miroc-esm'};
        case 'us-se'
            modelSubset = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
    %         models = {'access1-0', 'access1-3', 'bnu-esm', ...
    %               'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
    %               'gfdl-cm3', 'hadgem2-cc', ...
    %               'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
    %               'mpi-esm-mr'};
        case 'europe'
            modelSubset = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
    %         models = {'access1-0', 'access1-3', 'canesm2', ...
    %               'gfdl-cm3', 'hadgem2-cc', ...
    %               'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm'};
        case 'med'
            modelSubset = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
    %         models = {'bnu-esm', ...
    %               'csiro-mk3-6-0', 'gfdl-cm3', 'hadgem2-cc', ...
    %               'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm'};
        case 'sa-n'
            modelSubset = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};
        case 'amazon'
            modelSubset = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};
    %         models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
    %               'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
    %               'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
    %               'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
    %               'mpi-esm-mr', 'mri-cgcm3'};
        case 'india'
            modelSubset = {'bnu-esm', 'cnrm-cm5', ...
                      'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', ...
                      'ipsl-cm5a-mr', 'miroc-esm'};
        case 'africa-west'
            modelSubset = {'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-esm2g', 'gfdl-esm2m'};
        case 'africa-central'
            modelSubset = {'access1-0', 'access1-3', 'bnu-esm', ...
                      'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                      'mpi-esm-mr'};
    end
    
    % calculate indices for 25th/75th percentile bowen across models
    lowInd = max(round(0.25 * length(modelSubset)), 1);
    highInd = min(round(0.75 * length(modelSubset)), length(models));

    % indices of models for this region
    modelInd = [];
    
    for model = 1:length(availModels)
        % check if current model is a member of subset for this region
        if ismember(availModels{model}, modelSubset)
            modelInd(end+1) = model;
        end
    end

    % cancluate change anomalies if needed
    if showChgAnomalies
        annMeanLFlux = nanmean(lFluxRegionsChange{i}, 1);
        annMeanSFlux = nanmean(sFluxRegionsChange{i}, 1);
        annMeanTemp = nanmean(tasmaxRegionsChange{i}, 1);
        lFluxRegionsChange{i} = lFluxRegionsChange{i} - repmat(annMeanLFlux, size(lFluxRegionsChange{i}, 1), 1);
        sFluxRegionsChange{i} = sFluxRegionsChange{i} - repmat(annMeanSFlux, size(sFluxRegionsChange{i}, 1), 1);
        tasmaxRegionsChange{i} = tasmaxRegionsChange{i} - repmat(annMeanTemp, size(tasmaxRegionsChange{i}, 1), 1);
    end
    
    % limit to models for this region
    tasmaxRegionsChange{i} = tasmaxRegionsChange{i}(:, modelInd);
    if showPercentChange
        lFluxRegionsHistorical{i} = lFluxRegionsHistorical{i}(:, modelInd);
        sFluxRegionsHistorical{i} = sFluxRegionsHistorical{i}(:, modelInd);
    end
    lFluxRegionsChange{i} = lFluxRegionsChange{i}(:, modelInd);
    sFluxRegionsChange{i} = sFluxRegionsChange{i}(:, modelInd);
    
    % mean temperature change across models
    tempY = squeeze(nanmean(tasmaxRegionsChange{i}, 2));
    
    % sort models by temperature change to calculate error range
    tasmaxRegionsChange{i} = sort(tasmaxRegionsChange{i}, 2);
    
    % error is range across 25-75% models 
    tempErr = squeeze(range(tasmaxRegionsChange{i}(:, lowInd:highInd), 2)) ./ 2.0;
    
    % if only one model, err will be 0 so generate an array of zeros
    if tempErr == 0
        tempErr = zeros(12, 1);
    end
    
    if showPercentChange
        % average over models and then calculate total prc change
        lFluxY = squeeze(nanmean(lFluxRegionsChange{i}, 2)) ./ squeeze(nanmean(lFluxRegionsHistorical{i}, 2)) .* 100;
        sFluxY = squeeze(nanmean(sFluxRegionsChange{i}, 2)) ./ squeeze(nanmean(sFluxRegionsHistorical{i}, 2)) .* 100;
        
        % first calculate % change for each model/month
        lFluxErr = lFluxRegionsChange{i} ./ lFluxRegionsHistorical{i} .* 100;
        sFluxErr = sFluxRegionsChange{i} ./ sFluxRegionsHistorical{i} .* 100;
        % now sort by model
        lFluxErr = sort(lFluxErr, 2);
        sFluxErr = sort(sFluxErr, 2);
        % now find range across 25-75% models
        lFluxErr = squeeze(range(lFluxErr(:, lowInd:highInd), 2) / 2.0);
        sFluxErr = squeeze(range(sFluxErr(:, lowInd:highInd), 2) / 2.0);
    else
        
        
        % calculate mean change across models
        lFluxY = squeeze(nanmean(lFluxRegionsChange{i}, 2));
        sFluxY = squeeze(nanmean(sFluxRegionsChange{i}, 2));
        % sort, and take range across 25-75%
        lFluxRegionsChange{i} = sort(lFluxRegionsChange{i}, 2);
        sFluxRegionsChange{i} = sort(sFluxRegionsChange{i}, 2);
        lFluxErr = squeeze(range(lFluxRegionsChange{i}(:, lowInd:highInd), 2)) ./ 2.0;
        sFluxErr = squeeze(range(sFluxRegionsChange{i}(:, lowInd:highInd), 2)) ./ 2.0;
    end
    
    % if only one model, err will be 0 so generate an array of zeros
    if lFluxErr == 0
        lFluxErr = zeros(12, 1);
    end
    if sFluxErr == 0
        sFluxErr = zeros(12, 1);
    end
    
    f = figure('Color',[1,1,1]);
    hold on;
    grid on;
    box on;

    [ax, p1, p2] = shadedErrorBaryy(1:12, tempY, tempErr, 'r', ...
                                    1:12, lFluxY, lFluxErr, 'g');
    [ax2, p3, p4] = shadedErrorBaryy(1:12, tempY, tempErr, 'r', ...
                                        1:12, sFluxY, sFluxErr, 'b');
    hold(ax(1));
    hold(ax(2));
    hold(ax2(1));
    hold(ax2(2));
    box(ax(1), 'on');
    set(p1.mainLine, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
    set(p1.patch, 'FaceColor', [239/255.0, 71/255.0, 85/255.0]);
    set(p1.edge, 'Color', 'w');
    set(p2.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
    set(p2.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
    set(p2.edge, 'Color', 'w');
    axis(ax(1), 'square');
    axis(ax(2), 'square');
    
    set(p3.mainLine, 'Color', [239/255.0, 71/255.0, 85/255.0], 'LineWidth', 3);
    set(p3.patch, 'FaceColor', [239/255.0, 71/255.0, 85/255.0]);
    set(p3.edge, 'Color', 'w');
    set(p4.mainLine, 'Color', [66/255.0, 170/255.0, 244/255.0], 'LineWidth', 3);
    set(p4.patch, 'FaceColor', [66/255.0, 170/255.0, 244/255.0]);
    set(p4.edge, 'Color', 'w');
    axis(ax2(1), 'square');
    axis(ax2(2), 'square');

    % plot bowen zero line 
    plot(ax(2), 1:12, zeros(1,12), '--', 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 2);

    xlabel('Month', 'FontSize', 24);
    set(ax(1), 'XTick', 1:12);
    set(ax(2), 'XTick', []);
    set(ax2(1), 'XTick', 1:12);
    set(ax2(2), 'XTick', []);
    if showChgAnomalies
        set(ax(1), 'YLim', [-3 3], 'YTick', -3:3);
        set(ax2(1), 'YLim', [-3 3], 'YTick', -3:3);
    else
        set(ax(1), 'YLim', [0 7], 'YTick', 0:7);
        set(ax2(1), 'YLim', [0 7], 'YTick', 0:7);
    end
    
    if showPercentChange
        set(ax(2), 'YLim', [-50 100], 'YTick', []);
        set(ax2(2), 'YLim', [-50 100], 'YTick', [-50 0 50 100]);
        ylabel(ax2(2), 'Flux change (percent)', 'FontSize', 24);
    elseif showChgAnomalies
        set(ax(2), 'YLim', [-14 14], 'YTick', []);
        set(ax2(2), 'YLim', [-14 14], 'YTick', -14:2:14);
        ylabel(ax2(2), 'Flux change (anomaly)', 'FontSize', 24);
    else
        set(ax(2), 'YLim', [-20 20], 'YTick', []);
        set(ax2(2), 'YLim', [-20 20], 'YTick', -20:5:20);
        ylabel(ax2(2), 'Flux change', 'FontSize', 24);
    end
    set(ax(1), 'YColor', 'k', 'FontSize', 24);
    set(ax(2), 'YColor', 'k', 'FontSize', 24);
    set(ax2(1), 'YColor', 'k', 'FontSize', 24);
    set(ax2(2), 'YColor', 'k', 'FontSize', 24);
    if showChgAnomalies
        ylabel(ax(1), ['Tx change anomaly (' char(176) 'C)'], 'FontSize', 24);
    else
        ylabel(ax(1), ['Tx change (' char(176) 'C)'], 'FontSize', 24);
    end
    
    title(regionNames{i}, 'FontSize', 24);
    leg = legend([p1.mainLine p2.mainLine p4.mainLine], 'Temperature', 'Latent heat flux', 'Sensible heat flux');
    set(gcf, 'Position', get(0,'Screensize'));
    set(leg, 'FontSize', 24, 'location', 'southwest');
    if showPercentChange
        export_fig(['flux-seasonal-analysis-' regionAb{i} '-' tempMetric '-' anomalyStr '-percent.png;']);
    else
        export_fig(['flux-seasonal-analysis-' regionAb{i} '-' tempMetric '-' anomalyStr '-absolute.png;']);
    end
    close all;
end
