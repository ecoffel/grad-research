% plot monthly max temperature change alongside mean monthly bowen ratio changes

tasmaxMetric = 'monthly-mean-max';
tasminMetric = 'monthly-mean-min';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

% show the percentage change in bowen ratio or the absolute change
showPercentChange = true;

showLegend = false;

load waterGrid;
load lat;
load lon;
waterGrid = logical(waterGrid);

bowenBaseDir = 'e:\data\projects\bowen\bowen-chg-data\';
tempBaseDir = 'e:\data\projects\bowen\temp-chg-data\';

% all available models for both bowen and tasmax
availModels = {};



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

% load cmip5 historical data
if ~exist('tasmaxCmip5Historical', 'var')
    fprintf('loading cmip5 data...\n');
    
    % dimensions: x, y, month, model
    bowenCmip5Historical = [];
    tasmaxCmip5Historical = [];
    bowenCmip5Future = [];
    tasmaxCmip5Future = [];
    
    tasmaxChg = [];
    bowenChg = [];

    bowenChgRegionsCmip5 = {};
    tasmaxChgRegionsCmip5 = {};

    for m = 1:length(models)

        load([tempBaseDir 'monthly-mean-tasmax-cmip5-historical-' models{m} '-all-years.mat']);
        tasmaxCmip5Historical(:, :, m, :) = squeeze(nanmean(monthlyMeans, 3));
        
        load([tempBaseDir 'monthly-mean-tasmax-cmip5-rcp85-' models{m} '-all-years.mat']);
        tasmaxCmip5Future(:, :, m, :) = squeeze(nanmean(monthlyMeans, 3));

        
        curBowen = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/bowen/regrid/world'], 'bowen', 'yearStart', 1985, 'yearEnd', 2004);
        curBowen{3}(abs(curBowen{3}) > 100) = NaN;
        % average over the years
        bowenCmip5Historical(:, :, m, :) = squeeze(nanmean(curBowen{3}, 3));
        
        curBowen = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/rcp85/bowen/regrid/world'], 'bowen', 'yearStart', 2060, 'yearEnd', 2079);
        curBowen{3}(abs(curBowen{3}) > 100) = NaN;
        % average over the years
        bowenCmip5Future(:, :, m, :) = squeeze(nanmean(curBowen{3}, 3));
        
        tasmaxChg(:, :, m, :) = tasmaxCmip5Future(:, :, m, :) - tasmaxCmip5Historical(:, :,  m, :);
        bowenChg(:, :, m, :) = (bowenCmip5Future(:, :, m, :) - bowenCmip5Historical(:, :, m, :)) ./ bowenCmip5Historical(:, :, m, :) .* 100;
    end

    % loop over regions and extract bowen & tasmax change data
    for i = 1:length(regionNames)
        bowenChgRegionsCmip5{i} = squeeze(bowenChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :)); 
        tasmaxChgRegionsCmip5{i} = squeeze(tasmaxChg(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :)); 
    end
end

% load hottest months
load('2017-bowen/hottest-season.mat');

% plot ----------------------------------------------------

% loop over all regions for plotting
%for i = 1:length(regionNames)
fprintf('processing correlations...\n');

figure('Color', [1,1,1]);
set(gcf, 'Position', get(0,'Screensize'));
h = [];

colors = distinguishable_colors(4);
regionsToShow = [1, 2, 4, 7];
leg = [];

for iind = 1:length(regionsToShow)
    i = regionsToShow(iind);
    
    % calculate the hottest season for this region
    hotSeason = mode(reshape(hottestSeason(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}), ...
                                [numel(hottestSeason(regionLatLonInd{i}{1}, regionLatLonInd{i}{2})), 1]));
    
    
    % mean temperature change across models
    tasmaxCmip5Future = tasmaxChgRegionsCmip5{i};
    bowenCmip5Future = bowenChgRegionsCmip5{i};
    
    seasons = [[12 1 2];
               [3 4 5];
               [6 7 8];
               [9 10 11]];
    
    
    % temp/bowen change for each grid box in each region and for each
    % season
    regionT = {[], [], [], []};
    regionB = {[], [], [], []};
    
    
    % loop over all seasons
    for season = 1:size(seasons, 1)
        row = 1;
        % loop over all gridboxes
        for xlat = 1:size(tasmaxCmip5Future, 1)
            for ylon = 1:size(tasmaxCmip5Future, 2)
                if waterGrid(xlat, ylon)
                    continue;
                end
            
                % list of seasonal mean bowen/temp values for each gridbox
                % in region and for each year
                regionT{season}(row, :) = squeeze(nanmean(tasmaxCmip5Future(xlat, ylon, :, seasons(season, :)), 4));
                regionB{season}(row, :) = squeeze(nanmean(bowenCmip5Future(xlat, ylon, :, seasons(season, :)), 4));
                
                row = row+1;
            end
        end
    end
    
    % plot area average seasonal temp-bowen correlations
    cors = [];
    for season = 1:size(seasons, 1)
        for m = 1:length(models)
            curT = regionT{season}(:, m);
            curB = regionB{season}(:, m);
            nn = find(~isnan(curT) & ~isnan(curB));
            curT = curT(nn);
            curB = curB(nn);
            cors(m, season) = corr(curB, curT);
        end
    end
    
    h(iind) = subplot(1,4,iind);
    hold on;
    axis square;
    grid on;
    box on;
    b = boxplot(cors);
    
    set(b,{'LineWidth', 'Color'},{2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2);
    
    if iind == 1
        ylabel('Correlation', 'FontSize', 24);
    end
    set(gca, 'FontSize', 24);   
    ylim([-1 1])
    
    set(gca, 'XTick', [1,2,3,4], 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});
    xtickangle(45);
    % set hottest season xtick label red
    ax = gca;
    ax.TickLabelInterpreter = 'tex';
    ax.XTickLabels{hotSeason} = ['\color{red} ' ax.XTickLabels{hotSeason}];
    
    title(regionNames{i});
end

spacing = .05;
width = (1-(5*spacing))/4.0;

for i = 1:length(h)
    p(i,:) = get(h(i), 'position');
end

for i = 1:length(h)
    set(h(i), 'position', [(i+.5)*spacing+(i-1)*width p(i,2) width nanmean(p(:,4))]);
end

export_fig(['temp-bowen-corr-future.eps']);
close all;
    