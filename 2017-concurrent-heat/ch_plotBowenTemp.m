
% mean bowen ratio at each temperature bin
bowenTempRelHistorical = [];
bowenTempRelRcp85 = [];

% number of data points in each temperatuer bin
bowenTempCntHistorical = [];
bowenTempCntRcp85 = [];

regionInd = 10;

regionNames = {'World', ...
                'Central U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'India', ...
                'China', ...
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
            'china', ...
            'africa', ...
            'tropics'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[35 46], [-105 -90] + 360]; ...     % central us
           [[25 35], [-90 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[36 45], [-15+360, 35]]; ...        % Med
           [[0 15], [-90 -45]+360]; ...         % Northern SA
           [[-15, 0], [-60, -35]+360]; ...      % Amazon
           [[8, 26], [67, 90]]; ...             % India
           [[20, 40], [100, 125]]; ...          % China
           [[-10 10], [15, 30]]; ...            % central Africa
           [[-20 20], [0 360]]];                % Tropics

if strcmp(regionAb{regionInd}, 'amazon') || strcmp(regionAb{regionInd}, 'sa-n')
    % in amazon leave out csiro, canesm2, ipsl
    models = {'access1-0', 'access1-3', 'bnu-esm', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};
elseif strcmp(regionAb{regionInd}, 'india')
    % in india leave out csiro and mri-cgcm3
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
elseif strcmp(regionAb{regionInd}, 'africa')
    % leave out 'mri-cgcm3'
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
elseif strcmp(regionAb{regionInd}, 'us-cent') || strcmp(regionAb{regionInd}, 'us-se') || ...
        strcmp(regionAb{regionInd}, 'europe') || strcmp(regionAb{regionInd}, 'med')
    % leave out mri-cgcm3, gfdl-esm2m, gfdl-esm2g' due to bad temp performance
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr'};
else
    % leave out 'bcc-csm1-1-m' and 'inmcm4' due to bad bowen performance
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                  'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};
end

% models = {'hadgem2-es'};

load lat;
load lon;

regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

curLat = regionLatLonInd{regionInd}{1};
curLon = regionLatLonInd{regionInd}{2};
              
% mean bowen values at each temperature percentile, for each gridcell in
% the selected region
% dims: (x, y, model, percentile)
bowenHistorical = [];
bowenFuture = [];

% loop over all models and load bowen-temp relationship files
for model = 1:length(models)
    ['loading ' models{model} '...']
    load(['e:\data\bowen-temp\bowenTemp-' models{model} '-historical-1981-2004.mat']);
    bowenHistoricalData = bowenTemp;
    clear bowenTemp;
    
    % load future data
    load(['e:\data\bowen-temp\bowenTemp-' models{model} '-rcp85-2060-2080.mat']);
    bowenFutureData = bowenTemp;
    clear bowenTemp;
    
    for xlat = 1:length(curLat)
        for ylon = 1:length(curLon)
            % process historical data
            curGridcell = bowenHistoricalData{1}{curLat(xlat)}{curLon(ylon)};
            
            % if this is not a water grid
            if length(curGridcell) > 0
                % loop over percentiles
                for p = 1:length(curGridcell)
                    % set mean bowen for this percentile if enough data
                    % points
                    if length(curGridcell{p}) > 500
                        curGridcell{p} = abs(curGridcell{p});
                        
                        % only take bowens < 100 - otherwise probably a bad
                        % value
                        ind = find(curGridcell{p} < 100);
                        
                        bowenHistorical(xlat, ylon, model, p) = nanmean(curGridcell{p}(ind));
                    else
                        bowenHistorical(xlat, ylon, model, p) = NaN;
                    end
                end
            end
            
            % and the same for the future
            curGridcell = bowenFutureData{1}{curLat(xlat)}{curLon(ylon)};
            
            % if this is not a water grid
            if length(curGridcell) > 0
                % loop over percentiles
                for p = 1:length(curGridcell)
                    % set mean bowen for this percentile if enough data
                    % points
                    if length(curGridcell{p}) > 500
                        curGridcell{p} = abs(curGridcell{p});
                        
                        % only take bowens < 100 - otherwise probably a bad
                        % value
                        ind = find(curGridcell{p} < 100);

                        bowenFuture(xlat, ylon, model, p) = nanmean(curGridcell{p}(ind));
                    else
                        bowenFuture(xlat, ylon, model, p) = NaN;
                    end
                end
            end
        end
    end
    
    clear bowenHistoricalData bowenFutureData;
end

% take mean across models and region for historical and future, will be
% left with (model, percentile)
bowenHistoricalMean = squeeze(nanmean(nanmean(bowenHistorical, 2), 1));
bowenFutureMean = squeeze(nanmean(nanmean(bowenFuture, 2), 1));

% calculate the mean and percentage change
bowenAbsoluteChg = bowenFutureMean - bowenHistoricalMean;
bowenPercentChg = (bowenFutureMean - bowenHistoricalMean) ./ bowenHistoricalMean .* 100;

% mean
bowenAbsoluteChg = squeeze(nanmean(bowenAbsoluteChg, 1));
bowenPercentChg = squeeze(nanmean(bowenPercentChg, 1));

figure('Color', [1,1,1]);
hold on;
grid on;

[ax, p1, p2] = plotyy(10:10:100, bowenAbsoluteChg, 10:10:100, bowenPercentChg);
hold(ax(1));
hold(ax(2));

%plot(ax(1), 1:12, zeros(1,12), 'k--', 'LineWidth', 2);

set(p1, 'Color', 'k', 'LineWidth', 2);
set(p2, 'Color', 'r', 'LineWidth', 2);

box(ax(1), 'on');
axis(ax(1), 'square');
axis(ax(2), 'square');

set(ax(1), 'XTick', 10:10:100);
set(ax(2), 'XTick', 10:10:100);
set(ax(1), 'XLim', [5 105]);
set(ax(2), 'XLim', [5 105]);
set(ax(1), 'YLim', [-2 10], 'YTick', [-2:2:10]);
set(ax(2), 'YLim', [-50 250], 'YTick', [-50 0 50 100 150 200 250]);
set(ax(2), 'YColor', 'r', 'FontSize', 24);
set(ax(1), 'YColor', 'k', 'FontSize', 24);

xlabel(['Temperature percentile'], 'FontSize', 24);
ylabel(ax(1), 'Change in mean bowen ratio', 'FontSize', 24);
ylabel(ax(2), 'Change mean bowen ratio', 'FontSize', 24);
set(gca, 'FontSize', 24);
title(regionNames{regionInd}, 'FontSize', 24);

set(gcf, 'Position', get(0,'Screensize'));
export_fig(['bowenTemp-percentile-' regionAb{regionInd} '-percent.png'], '-m2');


