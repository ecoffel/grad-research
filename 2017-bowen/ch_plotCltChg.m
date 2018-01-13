
baseDir = 'e:/data';
var = 'clt';                  
percentChange = false;
warmSeason = true;
warmSeasonAnom = false;


% models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%               'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
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
    regionalCltHistorical = zeros(length(curLat), length(curLon), length(models), 12);
    regionalCltHistorical(regionalCltHistorical == 0) = NaN;
    regionalCltFuture = zeros(length(curLat), length(curLon), length(models), 12);
    regionalCltFuture(regionalCltFuture == 0) = NaN;
    
    for model = 1:length(models)
        fprintf('loading %s historical...\n', models{model});
        clt = loadMonthlyData([baseDir '/cmip5/output/' models{model} '/mon/r1i1p1/historical/' var '/regrid/world'], var, 'startYear', 1981, 'endYear', 2005);
        clt{3} = squeeze(nanmean(clt{3}, 3));
        
        % remove water tiles
        for month = 1:size(clt{3}, 4)
            curGrid = clt{3}(:, :, month);
            curGrid(waterGrid) = NaN;
            clt{3}(:, :, month) = curGrid;
        end
        
        % loop over all grid cells and select hottest season flux
        for xlat = 1:length(curLat)
            for ylon = 1:length(curLon)
                if waterGrid(curLat(xlat), curLon(ylon))
                    continue;
                end
                
                regionalCltHistorical(curLat(xlat), curLon(ylon), model, :) = clt{3}(curLat(xlat), curLon(ylon), :);
            end
        end
        
        clear flux;
        
        fprintf('loading %s future...\n', models{model});
        clt = loadMonthlyData([baseDir '/cmip5/output/' models{model} '/mon/r1i1p1/rcp85/' var '/regrid/world'], var, 'startYear', 2060, 'endYear', 2079);
        clt{3} = squeeze(nanmean(clt{3}, 3));
        
        % remove water tiles
        for month = 1:size(clt{3}, 4)
            curGrid = clt{3}(:, :, month);
            curGrid(waterGrid) = NaN;
            clt{3}(:, :, month) = curGrid;
        end
        
        % loop over all grid cells and select hottest season flux
        for xlat = 1:length(curLat)
            for ylon = 1:length(curLon)
                if waterGrid(curLat(xlat), curLon(ylon))
                    continue;
                end
                
                regionalCltFuture(curLat(xlat), curLon(ylon), model, :) = clt{3}(curLat(xlat), curLon(ylon), :);

            end
        end
    end
    
    % calculate soil change for each model
    chg = [];
    for model = 1:size(regionalCltHistorical, 3)
        tmpHistorical = regionalCltHistorical;
        tmpFuture = regionalCltFuture;
        
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
            
            eval([var 'Chg = chg;']);
            save(['e:/data/projects/bowen/derived-chg/' var '-Chg.mat'], [var 'Chg']);
        else
            eval([var 'Chg = chg;']);
            save(['e:/data/projects/bowen/derived-chg/' var 'Chg-absolute.mat'], [var 'Chg']);
        end
        
        cltHistorical = regionalCltHistorical;
        save(['e:/data/projects/bowen/derived-chg/cltHistorical-absolute.mat'], 'cltHistorical');

        plotChg = nanmedian(plotChg, 3);
        plotChg(:,1) = plotChg(:,end);

        result = {lat, lon, plotChg};
        
        sigChg(1:15,:) = 0;
        sigChg(75:90,:) = 0;

        colorScheme = 'RdBu';
        
        saveData = struct('data', {result}, ...
                          'plotRegion', 'world', ...
                          'plotRange', [-10 10], ...
                          'cbXTicks', -10:2:10, ...
                          'plotTitle', ['Warm season ' var ' change'], ...
                          'fileTitle', [var '-chg-' num2str(region) '-warm.eps'], ...
                          'plotXUnits', ['Fraction'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([], colorScheme), ...
                          'statData', sigChg, ...
                          'stippleInterval', 5, ...
                          'boxCoords', {regions([2,4,7], :)});
                      
        plotFromDataFile(saveData);
    end
    
    % spatial average
    regionalCltHistorical = squeeze(nanmean(nanmean(regionalCltHistorical, 2), 1));
    regionalCltFuture = squeeze(nanmean(nanmean(regionalCltFuture, 2), 1));
    
    % average over models
    regionalSoilHistoricalMean = nanmean(regionalCltHistorical, 2);
    regionalSoilFutureMean = nanmean(regionalCltFuture, 2);
    
    if percentChange
        % percentage change
        regionalSoilChgStd = nanstd((regionalCltFuture - regionalCltHistorical) ./ regionalCltHistorical .* 100, [], 2);
        regionSoilChg = regionalCltFuture - regionalCltHistorical;
        regionSoilChgMean = (regionalSoilFutureMean - regionalSoilHistoricalMean) ./ regionalSoilHistoricalMean .* 100;
    else
        % absolute change
        % std over models
        regionalSoilChgStd = nanstd(regionalCltFuture - regionalCltHistorical, [], 2);
        regionSoilChg = regionalCltFuture - regionalCltHistorical;
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






