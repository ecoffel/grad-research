
baseDir = 'e:/data/projects/bowen';
SnwVar = 'snw';                  
percentChange = true;
warmSeason = false;

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

plotMap = true;

timePeriodHistorical = 1985:2005;
timePeriodFuture = 2060:2080;

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

showMonths = [12 1 2];
showRegions =  1;

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

SnwVarStr = 'absolute';
if percentChange
    SnwVarStr = 'percent';
end

% load snow mask from ERA
fprintf('building snow mask...\n');
snowMask = zeros(size(lat));
sdHistorical = loadDailyData('E:\data\era-interim\output\sd\regrid\world', 'yearStart', 1985, 'yearEnd', 2004);
for xlat = 1:size(sdHistorical{1}, 1)
    for ylon = 1:size(sdHistorical{1}, 2)
        % get current time series for DJF
        curSd = permute(squeeze(sdHistorical{3}(xlat, ylon, :, [12 1 2], :)), [3 2 1]);
        if nanmedian(curSd) > 0
            snowMask(xlat, ylon) = 1;
        end
    end
end
snowMask = logical(snowMask);

for region = showRegions
    % historical and future monthly precip, mm/day
    % dims: (x, y, month, model)
    regionalSnwHistorical = [];
    regionalSnwFuture = [];
    
    curLat = regionLatLonInd{region}{1};
    curLon = regionLatLonInd{region}{2};
    
    fprintf('loading cmip5 data...\n');
    for model = 1:length(models)
        % load historical and future Snw data
        load([baseDir '/snw-chg-data/monthly-mean-snw-cmip5-historical-' models{model} '.mat']);
        % rename variable from file
        SnwHistorical = monthlyMeans;
        clear monthlyMeans;
        
        % remove water tiles
        for month = 1:12
            curGrid = SnwHistorical(:, :, month);
            curGrid(waterGrid) = NaN;
            % mask regions without historical snow
            curGrid(~snowMask) = NaN;
            SnwHistorical(:, :, month) = curGrid;
        end
        
        % some partial water tiles have very large values - remove
        %SnwHistorical(SnwHistorical > maxVal) = NaN;
        
        regionalSnwHistorical(:, :, model, :) = SnwHistorical(curLat, curLon, :);
        
        load([baseDir '/snw-chg-data/monthly-mean-snw-cmip5-rcp85-' models{model} '.mat']);
        % rename variable from file
        SnwFuture = monthlyMeans;
        clear monthlyMeans;
        
        % remove water tiles
        for month = 1:12
            curGrid = SnwFuture(:, :, month);
            curGrid(waterGrid) = NaN;
            curGrid(~snowMask) = NaN;
            SnwFuture(:, :, month) = curGrid;
        end
        
        regionalSnwFuture(:, :, model, :) = SnwFuture(curLat, curLon, :);

    end
    
    % calculate snow change for each model
    chg = [];
    for model = 1:size(regionalSnwHistorical, 3)
        tmpHistorical = regionalSnwHistorical;
        tmpFuture = regionalSnwFuture;
        
        chg(:, :, model, :) = (tmpFuture(:,:,model,:)-tmpHistorical(:,:,model,:)) ./ tmpHistorical(:,:,model,:);
    end
    
    if plotMap
        % find statistical significance of change over selected months across models
        sigChg = zeros(size(lat,1), size(lat, 2));
        for xlat = 1:size(chg, 1)
            for ylon = 1:size(chg, 2)

                % select only non-nan items
                curChg = squeeze(nanmean(chg(xlat, ylon, :, [12 1 2]), 4));
                ind = find(~isnan(curChg) & ~isinf(curChg));
                curChg = curChg(ind);

                % at least 10 non-nan models
                if length(curChg >= round(.75*length(models)))
                    med = nanmedian(curChg);

                    % where fewer 75% models agree on sign
                    sigChg(xlat, ylon) = length(find(sign(curChg) == sign(med))) < round(.75*length(models));
                end
            end
        end

        sigChg(~snowMask) = 0;
        % kill off hatching in antarctica to speed rendering
        sigChg(1:45, :) = 0;
        chg(isinf(chg)) = NaN;
        
        chg = chg .* 100;
        
        snwChg = chg;
        save('e:/data/projects/bowen/derived-chg/snw-chg-all.mat', 'snwChg');
        
        % median over models
        chg = nanmedian(chg, 3);
        chg(:,1) = chg(:,end);

        result = {lat, lon, chg};

        saveData = struct('data', {result}, ...
                          'plotRegion', 'world', ...
                          'plotRange', [-100 100], ...
                          'cbXTicks', -100:50:100, ...
                          'plotTitle', ['DJF Snow mass change'], ...
                          'fileTitle', ['snw-chg-' num2str(region) '.png'], ...
                          'plotXUnits', ['%'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([], 'BrBG'), ...
                          'statData', sigChg, ...
                          'stippleInterval', 5, ...
                          'magnify', '3', ...
                          'vector', true, ...
                          'boxCoords', {regions([2,4,7], :)});
        plotFromDataFile(saveData);
    end
    
    % spatial average
    regionalSnwHistorical = squeeze(nanmean(nanmean(regionalSnwHistorical, 2), 1));
    regionalSnwFuture = squeeze(nanmean(nanmean(regionalSnwFuture, 2), 1));
    
    % average over models
    regionalSnwHistoricalMean = nanmean(regionalSnwHistorical, 2);
    regionalSnwFutureMean = nanmean(regionalSnwFuture, 2);
    
    if percentChange
        % percentage change
        regionalSnwChgStd = nanstd((regionalSnwFuture - regionalSnwHistorical) ./ regionalSnwHistorical .* 100, [], 2);
        regionSnwChg = regionalSnwFuture - regionalSnwHistorical;
        regionSnwChgMean = (regionalSnwFutureMean - regionalSnwHistoricalMean) ./ regionalSnwHistoricalMean .* 100;
    else
        % absolute change
        % std over models
        regionalSnwChgStd = nanstd(regionalSnwFuture - regionalSnwHistorical, [], 2);
        regionSnwChg = regionalSnwFuture - regionalSnwHistorical;
        regionSnwChgMean = regionalSnwFutureMean - regionalSnwHistoricalMean;
    end
    
    % test if different from zero at 95th percentile
    sigChg = [];
    for month = 1:12
        sigChg(month) = ttest(regionSnwChg(month, :), 0, 'Alpha', 0.05);
    end
    
    f = figure('Color',[1,1,1]);
    hold on;
    grid on;
    box on;
    axis square;
    
    p1 = shadedErrorBar(1:length(showMonths), regionSnwChgMean(showMonths), regionalSnwChgStd(showMonths), 'g', 1);
    
    set(p1.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
    set(p1.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
    set(p1.edge, 'Color', 'w');

    % plot bowen zero line 
    plot(1:12, zeros(1,12), '--', 'Color', 'k', 'LineWidth', 2);

    xlabel('Month', 'FontSize', 36);
    set(gca, 'XLim', [1 length(showMonths)], 'XTick', 1:length(showMonths), 'XTickLabel', showMonths);
    
    if strcmp(SnwVar, 'mrso')
        if percentChange
            set(gca, 'YLim', [-20 20], 'YTick', -20:10:20);
            ylabel('Total Snw moisture change (percent)', 'FontSize', 36);
        else
            set(gca, 'YLim', [-1e7 1e7]);
            ylabel('Total Snw moisture change', 'FontSize', 36);
        end
    elseif strcmp(SnwVar, 'mrsos')
        if percentChange
            set(gca, 'YLim', [-50 50], 'YTick', -50:20:50);
            ylabel('Surface Snw moisture change (percent)', 'FontSize', 36);
        else
            set(gca, 'YLim', [-1e6 1e6]);
            ylabel('Surface Snw moisture change', 'FontSize', 36);
        end
    elseif strcmp(SnwVar, 'snw')
        set(gca, 'YLim', [-100 20], 'YTick', -100:20:20);
        ylabel('Snow mass change (percent)', 'FontSize', 36);
    end
    set(gca, 'FontSize', 36);
    
    title(regionNames{region}, 'FontSize', 40);
    
    for month = 1:length(showMonths)
        p2 = plot(month, regionSnwChgMean(showMonths(month)), 'o', 'MarkerSize', 15, 'Color', [25/255.0, 158/255.0, 56/255.0], 'MarkerEdgeColor', 'k');
        if sigChg(showMonths(month))
            set(p2, 'LineWidth', 3, 'MarkerFaceColor', [25/255.0, 158/255.0, 56/255.0]);
        else
            set(p2, 'LineWidth', 3);
        end
    end
    
    
    set(gcf, 'Position', get(0,'Screensize'));
    
    export_fig([SnwVar 'Chg-' regionAb{region} '-' SnwVarStr '.png;']);
    
    close all;
    
end






