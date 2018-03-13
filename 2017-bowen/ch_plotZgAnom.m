
baseDir = 'e:/data';
var = 'zg';                  
percentChange = false;
warmSeason = true;
warmSeasonAnom = false;

selMonths = [6 7 8];
metric = 'PosAnom';

% models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%               'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

modelId = [1 2 3 4 5 9 10 11];
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm'};%, 'canesm2', ...
%               'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

plotMap = true;

timePeriodHistorical = 1985:2005;
timePeriodFuture = 2060:2080;

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

showRegions =  1;


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

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

% load hottest seasons for each grid cell
load('2017-bowen/hottest-season-ncep.mat');

for region = showRegions
    curLat = regionLatLonInd{region}{1};
    curLon = regionLatLonInd{region}{2};
    
    % historical and future monthly precip, mm/day
    % dims: (x, y, model)
    regionalZgHistorical = zeros(length(curLat), length(curLon), length(models), 21);
    regionalZgHistorical(regionalZgHistorical == 0) = NaN;
    regionalZgFuture = zeros(length(curLat), length(curLon), length(models), 21);
    regionalZgFuture(regionalZgFuture == 0) = NaN;
    
    for model = 1:length(models)
        fprintf('loading %s historical...\n', models{model});
        zg = loadDailyData([baseDir '/cmip5/output/' models{model} '/r1i1p1/historical/' var], 'startYear', timePeriodHistorical(1), 'endYear', timePeriodHistorical(end));
        if strcmp(metric, 'PosAnom')
            zgMetric = squeeze(findPosZgAnom(zg{3}(:, :, :, selMonths, :), -1));
        end
        
        metricRegrid = [];
        for year = 1:size(zgMetric, 3)
            ddr = regridGriddata({zg{1},zg{2},squeeze(zgMetric(:,:,year))},{lat,lon,[]},false);
            metricRegrid(:,:,year) = ddr{3};
        end
        
        regionalZgHistorical(:,:,model,:) = metricRegrid;
        clear zg zgMetric;
        
        fprintf('loading %s future...\n', models{model});
        zg = loadDailyData([baseDir '/cmip5/output/' models{model} '/r1i1p1/rcp85/' var ], 'startYear', timePeriodFuture(1), 'endYear', timePeriodFuture(end));
        if strcmp(metric, 'PosAnom')
            zgMetric = squeeze(findPosZgAnom(zg{3}(:, :, :, selMonths, :), -1));
        end
        
        metricRegrid = [];
        for year = 1:size(zgMetric, 3)
            ddr = regridGriddata({zg{1},zg{2},squeeze(zgMetric(:,:,year))},{lat,lon,[]},false);
            metricRegrid(:,:,year) = ddr{3};
        end
        
        regionalZgFuture(:,:,model,:) = metricRegrid;
        clear zg zgMetric;
    end
    
    % calculate soil change for each model
    chg = [];
    for model = 1:size(regionalZgHistorical, 3)
        tmpHistorical = regionalZgHistorical;
        tmpFuture = regionalZgFuture;
        
        % change in all seasons
        if percentChange
            chg(:, :, model, :) = squeeze((tmpFuture(:,:,model,:)-tmpHistorical(:,:,model,:)) ./ tmpHistorical(:,:,model,:));
        else
            % in w/m2
            chg(:, :, model, :) = squeeze(tmpFuture(:,:,model,:)-tmpHistorical(:,:,model,:));
        end
        
    end
    
    if plotMap
        plotChg = zeros(size(lat,1), size(lat,2), size(chg, 3));
        plotChg(plotChg == 0) = NaN;
        
        % find statistical significance of change over selected months across models
        sigChg = zeros(size(lat,1), size(lat, 2));
        for xlat = 1:size(chg, 1)
            for ylon = 1:size(chg, 2)
                
                months = 1:12;
                
                if warmSeason 
                    months = seasons(hottestSeason(xlat, ylon), :);
                end
                
                % select only non-nan items
                curChg = squeeze(nanmean(chg(xlat, ylon, :, months), 4));
                ind = find(~isnan(curChg) & ~isinf(curChg));
                curChg = curChg(ind);

                % at least 10 non-nan models
                if length(curChg) == length(models)
                    med = nanmedian(curChg);
                    plotChg(xlat, ylon, :) = curChg;

                    % where < 75% models agree on sign
                    sigChg(xlat, ylon) = length(find(sign(curChg) == sign(med))) < round(.75*length(models));
                end
            end
        end

        plotChg(isinf(plotChg)) = NaN;
        % median over models
        if percentChange
            chg = chg .* 100;
            plotChg = plotChg .* 100;
            
            %eval([var 'Chg = chg;']);
            %save(['e:/data/projects/bowen/derived-chg/' var '-chg-all.mat'], [var 'Chg']);
        else
            eval(['zg' metric 'Chg = chg;']);
            save(['e:/data/projects/bowen/derived-chg/zg' metric 'Chg.mat'], ['zg' metric 'Chg']);
        end
%         
%         hflsHistorical = regionalFluxHistorical;
%         save(['e:/data/projects/bowen/derived-chg/hflsHistorical-absolute.mat'], 'hflsHistorical');
%         
%         hflsFuture = regionalFluxFuture;
%         save(['e:/data/projects/bowen/derived-chg/hflsFuture-absolute.mat'], 'hflsFuture');

        plotChg = nanmedian(plotChg, 3);
        plotChg(:,1) = plotChg(:,end);

        result = {lat, lon, plotChg};
        
        sigChg(1:15,:) = 0;
        sigChg(75:90,:) = 0;

        colorScheme = 'Reds';
        if strcmp(var, 'hfls')
            colorScheme = 'RdBu';
        end
        
        saveData = struct('data', {result}, ...
                          'plotRegion', 'world', ...
                          'plotRange', [0 25], ...
                          'cbXTicks', 0:5:25, ...
                          'plotTitle', ['Warm season ' var ' change'], ...
                          'fileTitle', ['dryDay-chg-' num2str(region) '-warm.eps'], ...
                          'plotXUnits', ['Days'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([], colorScheme), ...
                          'statData', sigChg, ...
                          'stippleInterval', 5, ...
                          'boxCoords', {regions([2,4,7,10], :)});
                      
        plotFromDataFile(saveData);
    end
    
    % spatial average
    regionalZgHistorical = squeeze(nanmean(nanmean(regionalZgHistorical, 2), 1));
    regionalZgFuture = squeeze(nanmean(nanmean(regionalZgFuture, 2), 1));
    
    % average over models
    regionalSoilHistoricalMean = nanmean(regionalZgHistorical, 2);
    regionalSoilFutureMean = nanmean(regionalZgFuture, 2);
    
    if percentChange
        % percentage change
        regionalSoilChgStd = nanstd((regionalZgFuture - regionalZgHistorical) ./ regionalZgHistorical .* 100, [], 2);
        regionSoilChg = regionalZgFuture - regionalZgHistorical;
        regionSoilChgMean = (regionalSoilFutureMean - regionalSoilHistoricalMean) ./ regionalSoilHistoricalMean .* 100;
    else
        % absolute change
        % std over models
        regionalSoilChgStd = nanstd(regionalZgFuture - regionalZgHistorical, [], 2);
        regionSoilChg = regionalZgFuture - regionalZgHistorical;
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
    
    p1 = shadedErrorBar(1:length(showMonths), regionSoilChgMean(showMonths), regionalSoilChgStd(showMonths), 'g', 1);
    
    set(p1.mainLine, 'Color', [25/255.0, 158/255.0, 56/255.0], 'LineWidth', 3);
    set(p1.patch, 'FaceColor', [25/255.0, 158/255.0, 56/255.0]);
    set(p1.edge, 'Color', 'w');

    % plot bowen zero line 
    plot(1:12, zeros(1,12), '--', 'Color', 'k', 'LineWidth', 2);

    xlabel('Month', 'FontSize', 36);
    set(gca, 'XLim', [1 length(showMonths)], 'XTick', 1:length(showMonths), 'XTickLabel', showMonths);
    
    if strcmp(var, 'mrso')
        if percentChange
            set(gca, 'YLim', [-20 20], 'YTick', -20:10:20);
            ylabel('Total Snw moisture change (percent)', 'FontSize', 36);
        else
            set(gca, 'YLim', [-1e7 1e7]);
            ylabel('Total Snw moisture change', 'FontSize', 36);
        end
    end
    set(gca, 'FontSize', 36);
    
    title(regionNames{region}, 'FontSize', 40);
    
    for month = 1:length(showMonths)
        p2 = plot(month, regionSoilChgMean(showMonths(month)), 'o', 'MarkerSize', 15, 'Color', [25/255.0, 158/255.0, 56/255.0], 'MarkerEdgeColor', 'k');
        if sigChg(showMonths(month))
            set(p2, 'LineWidth', 3, 'MarkerFaceColor', [25/255.0, 158/255.0, 56/255.0]);
        else
            set(p2, 'LineWidth', 3);
        end
    end
    
    
    set(gcf, 'Position', get(0,'Screensize'));
    
    export_fig([var 'Chg-' regionAb{region} '-' soilVarStr '.png;']);
    
    close all;
    
end






