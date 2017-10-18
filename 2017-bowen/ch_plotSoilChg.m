
baseDir = '2017-bowen/bowen';
soilVar = 'mrso';                  
percentChange = true;

if strcmp(soilVar, 'mrso')
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                          'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                          'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                          'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                          'mpi-esm-mr', 'mri-cgcm3'};
    maxVal = 1e9;
elseif strcmp(soilVar, 'mrsos')
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                      'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'ipsl-cm5a-mr', ...
                      'mri-cgcm3'};
    maxVal = 1e9;
end

timePeriodHistorical = 1985:2005;
timePeriodFuture = 2060:2080;

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

showMonths = [7 8 9];
showRegions = 1;

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

soilVarStr = 'absolute';
if percentChange
    soilVarStr = 'percent';
end

for region = showRegions
    % historical and future monthly precip, mm/day
    % dims: (x, y, month, model)
    regionalSoilHistorical = [];
    regionalSoilFuture = [];
    
    curLat = regionLatLonInd{region}{1};
    curLon = regionLatLonInd{region}{2};
    
    for model = 1:length(models)
        % load historical and future soil data
        load([baseDir '/monthly-soil/monthlySoilChg-cmip5-historical-' soilVar '-' models{model} '-1985-2005.mat']);
        
        % remove water tiles
        for month = 1:12
            curGrid = soilHistorical(:, :, month);
            curGrid(waterGrid) = NaN;
            soilHistorical(:, :, month) = curGrid;
        end
        
        % some partial water tiles have very large values - remove
        soilHistorical(soilHistorical > maxVal) = NaN;
        
        regionalSoilHistorical(:, :, :, model) = soilHistorical(curLat, curLon, :);
        
        load([baseDir '/monthly-soil/monthlySoilChg-cmip5-future-' soilVar '-' models{model} '-2060-2080.mat']);
        
        % remove water tiles
        for month = 1:12
            curGrid = soilFuture(:, :, month);
            curGrid(waterGrid) = NaN;
            soilFuture(:, :, month) = curGrid;
        end
        
        % some partial water tiles have very large values - remove
        soilFuture(soilFuture > maxVal) = NaN;
        
        regionalSoilFuture(:, :, :, model) = soilFuture(curLat, curLon, :);

    end
    
    % calculate soil change for each model
    chg = [];
    for model = 1:size(regionalSoilHistorical, 4)
        chg(:, :, :, model) = (regionalSoilFuture(:,:,showMonths,model)-regionalSoilHistorical(:,:,showMonths,model)) ./ regionalSoilHistorical(:,:,showMonths,model);
    end
    
    % find statistical significance of change over selected months across models
    sigChg = [];
    for xlat = 1:size(chg, 1)
        for ylon = 1:size(chg, 2)
            for month = 1:size(chg, 3)
                
                % select only non-nan items
                curChg = squeeze(chg(xlat, ylon, month, :));
                ind = find(~isnan(curChg) & ~isinf(curChg));
                curChg = curChg(ind);
                
                % for each grid cell and month, calculate sig across models
                if length(curChg) > 5
                    if ttest(curChg)
                        sigChg(xlat, ylon, month) = 1;
                    else
                        sigChg(xlat, ylon, month) = 0;
                    end
                end
            end
        end
    end
    
    % average over months - will give the fraction of months that are
    % signficant
    sigChg = nanmean(sigChg, 3);
    
    % with >= 2/3 of months sig, stipple it
    sigChg(sigChg >= 0.66) = 1;
    sigChg(sigChg < 0.66) = 0;
    
    % exclude bad values and don't show zeros or increasing
    chg(chg < -1 | chg > 1 | isinf(chg)) = NaN;
    chg = nanmean(nanmean(chg, 4), 3);
    chg = chg .* 100;
    chg(:,1) = chg(:,end);
    
    result = {lat, lon, chg};

    saveData = struct('data', {result}, ...
                      'plotRegion', 'world', ...
                      'plotRange', [-25 0], ...
                      'cbXTicks', -25:5:0, ...
                      'plotTitle', ['SOND Soil moisture mass change'], ...
                      'fileTitle', ['soil-chg-' num2str(region) '.png'], ...
                      'plotXUnits', ['Percent'], ...
                      'blockWater', true, ...
                      'colormap', cmocean('-turbid'), ...
                      'statData', sigChg, ...
                      'stippleInterval', 5, ...
                      'magnify', '2', ...
                      'boxCoords', {regions([2,4,7], :)});
    plotFromDataFile(saveData);
    
    
    
    % spatial average
    regionalSoilHistorical = squeeze(nanmean(nanmean(regionalSoilHistorical, 2), 1));
    regionalSoilFuture = squeeze(nanmean(nanmean(regionalSoilFuture, 2), 1));
    
    % average over models
    regionalSoilHistoricalMean = nanmean(regionalSoilHistorical, 2);
    regionalSoilFutureMean = nanmean(regionalSoilFuture, 2);
    
    if percentChange
        % percentage change
        regionalSoilChgStd = nanstd((regionalSoilFuture - regionalSoilHistorical) ./ regionalSoilHistorical .* 100, [], 2);
        regionSoilChg = regionalSoilFuture - regionalSoilHistorical;
        regionSoilChgMean = (regionalSoilFutureMean - regionalSoilHistoricalMean) ./ regionalSoilHistoricalMean .* 100;
    else
        % absolute change
        % std over models
        regionalSoilChgStd = nanstd(regionalSoilFuture - regionalSoilHistorical, [], 2);
        regionSoilChg = regionalSoilFuture - regionalSoilHistorical;
        regionSoilChgMean = regionalSoilFutureMean - regionalSoilHistoricalMean;
    end
    
    % test if different from zero at 95th percentile
    sigChg = [];
    for month = 1:12
        sigChg(month) = ttest(regionSoilChg(month, :), 0, 'Alpha', 0.05);
    end
    
    f = figure('Color',[1,1,1]);
    hold on;
    grid on;
    box on;
    axis square;
    
    p1 = shadedErrorBar(1:12, regionSoilChgMean, regionalSoilChgStd, 'g', 1);
    
    set(p1.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
    set(p1.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
    set(p1.edge, 'Color', 'w');

    % plot bowen zero line 
    plot(1:12, zeros(1,12), '--', 'Color', 'k', 'LineWidth', 2);

    xlabel('Month', 'FontSize', 24);
    set(gca, 'XLim', [1 12], 'XTick', 1:12);
    
    if strcmp(soilVar, 'mrso')
        if percentChange
            set(gca, 'YLim', [-20 20], 'YTick', -20:10:20);
            ylabel('Total soil moisture change (percent)', 'FontSize', 24);
        else
            set(gca, 'YLim', [-1e7 1e7]);
            ylabel('Total soil moisture change', 'FontSize', 24);
        end
    elseif strcmp(soilVar, 'mrsos')
        if percentChange
            set(gca, 'YLim', [-50 50], 'YTick', -50:20:50);
            ylabel('Surface soil moisture change (percent)', 'FontSize', 24);
        else
            set(gca, 'YLim', [-1e6 1e6]);
            ylabel('Surface soil moisture change', 'FontSize', 24);
        end
    elseif strcmp(soilVar, 'snw')
        set(gca, 'YLim', [-100 50], 'YTick', -100:50:50);
        ylabel('Snow mass change (percent)', 'FontSize', 24);
    end
    set(gca, 'FontSize', 24);
    
    title(regionNames{region}, 'FontSize', 24);
    
    for month = 1:12
        p2 = plot(month, regionSoilChgMean(month), 'o', 'MarkerSize', 15, 'Color', [25/255.0, 158/255.0, 56/255.0], 'MarkerEdgeColor', 'k');
        if sigChg(month)
            set(p2, 'LineWidth', 3, 'MarkerFaceColor', [25/255.0, 158/255.0, 56/255.0]);
        else
            set(p2, 'LineWidth', 3);
        end
    end
    
    set(gcf, 'Position', get(0,'Screensize'));
    
    export_fig([soilVar 'Chg-' regionAb{region} '-' soilVarStr '.png;']);
    
    close all;
    
end






