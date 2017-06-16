
models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                      'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3'};

baseDir = 'e:/data/cmip5/output';
                  
timePeriodHistorical = 1985:2005;
timePeriodFuture = 2060:2080;

load lat;
load lon;

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
           [[25 35], [-103 -75] + 360]; ...      % southeast us
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

for region = 1:length(regionLatLonInd)
    % historical and future monthly precip, mm/day
    % dims: (x, y, month, model)
    regionalPrChg = [];
    
    curLat = regionLatLonInd{region}{1};
    curLon = regionLatLonInd{region}{2};
    
    for model = 1:length(models)
        
        % this will load the variable 'prChg'
        load(['f:/data/bowen/monthly-pr/monthlyPrChg-cmip5-historical-' models{model} '-2060-2080.mat']);

        regionalPrChg(:, :, :, model) = prChg(curLat, curLon, :);

    end
    
    % spatial average
    regionalPrChg = squeeze(nanmean(nanmean(regionalPrChg, 2), 1));
    
    % average over models
    regionalPrChgMean = nanmean(regionalPrChg, 2);
    
    % std over models
    regionalPrChgStd = nanstd(regionalPrChg, [], 2);
    
    % test if different from zero at 95th percentile
    sigChg = [];
    for month = 1:12
        sigChg(month) = ttest(regionalPrChg(month, :), 0, 'Alpha', 0.05);
    end
    
    f = figure('Color',[1,1,1]);
    hold on;
    grid on;
    box on;
    axis square;
    
    p1 = shadedErrorBar(1:12, regionalPrChgMean, regionalPrChgStd, 'g', 1);
    
    set(p1.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
    set(p1.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
    set(p1.edge, 'Color', 'w');

    % plot bowen zero line 
    plot(1:12, zeros(1,12), '--', 'Color', 'k', 'LineWidth', 2);

    xlabel('Month', 'FontSize', 24);
    set(gca, 'XLim', [1 12], 'XTick', 1:12);

    set(gca, 'YLim', [-4 4], 'YTick', -4:1:4);
    ylabel('Precip change (mm/day)', 'FontSize', 24);
    set(gca, 'FontSize', 24);
    
    title(regionNames{region}, 'FontSize', 24);
    
    for month = 1:12
        p2 = plot(month, regionalPrChgMean(month), 'o', 'MarkerSize', 15, 'Color', [25/255.0, 158/255.0, 56/255.0], 'MarkerEdgeColor', 'k');
        if sigChg(month)
            set(p2, 'LineWidth', 3, 'MarkerFaceColor', [25/255.0, 158/255.0, 56/255.0]);
        else
            set(p2, 'LineWidth', 3);
        end
        uistack(p2, 'bottom');
    end
    
    set(gcf, 'Position', get(0,'Screensize'));
    
    export_fig(['prChg-' regionAb{region} '-absolute.png;']);
    
    close all;
    
end






