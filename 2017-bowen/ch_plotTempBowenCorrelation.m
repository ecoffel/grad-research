% plot monthly max temperature change alongside mean monthly bowen ratio changes

dataset = 'reanalysis';

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

% show correlation between Tx and Bowen
showCorr = true;

load waterGrid;
load lat;
load lon;
waterGrid = logical(waterGrid);

bowenBaseDir = 'e:\data\projects\bowen\temp-chg-data\';
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

% load ncep/era data if needed and conver to monthly mean
if ~exist('tasmaxNcep', 'var')
    fprintf('loading reanalysis data...\n');
    tasmaxNcep = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'yearStart', 1985, 'yearEnd', 2005);
    tasmaxNcep{3} = tasmaxNcep{3} - 273.15;
    tasmaxNcep = dailyToMonthly(tasmaxNcep);
    
    bowenNcep = loadDailyData('e:/data/ncep-reanalysis/output/bowen/regrid/world', 'yearStart', 1985, 'yearEnd', 2005);
    bowenNcep{3}(bowenNcep{3} > 100) = NaN;
    %bowenNcep{3}(bowenNcep{3} < 0) = NaN;
    bowenNcep = dailyToMonthly(bowenNcep);
    
    tasmaxEra = loadDailyData('e:/data/era-interim/output/mx2t/regrid/world', 'yearStart', 1985, 'yearEnd', 2005);
    tasmaxEra{3} = tasmaxEra{3} - 273.15;
    tasmaxEra = dailyToMonthly(tasmaxEra);
    
    bowenEra = loadDailyData('e:/data/era-interim/output/bowen/regrid/world', 'yearStart', 1985, 'yearEnd', 2005);
    bowenEra{3}(bowenEra{3} > 100) = NaN;
    %bowenEra{3}(bowenEra{3} < 0) = NaN;
    bowenEra = dailyToMonthly(bowenEra);
    
    for year = 1:size(tasmaxNcep{3}, 3)
        for month = 1:size(tasmaxNcep{3}, 4)
            curGrid = tasmaxNcep{3}(:, :, year, month);
            curGrid(waterGrid) = NaN;
            tasmaxNcep{3}(:, :, year, month) = curGrid;
            
            curGrid = bowenNcep{3}(:, :, year, month);
            curGrid(waterGrid) = NaN;
            bowenNcep{3}(:, :, year, month) = curGrid;
            
            curGrid = tasmaxEra{3}(:, :, year, month);
            curGrid(waterGrid) = NaN;
            tasmaxEra{3}(:, :, year, month) = curGrid;
            
            curGrid = bowenEra{3}(:, :, year, month);
            curGrid(waterGrid) = NaN;
            bowenEra{3}(:, :, year, month) = curGrid;
        end
    end
    
    % select data and average over years
    tasmaxNcep = tasmaxNcep{3};
    bowenNcep = bowenNcep{3};
    tasmaxEra = tasmaxEra{3};
    bowenEra = bowenEra{3};

    % average bowen (absolute) and temperature change over each region
    bowenRegionsNcep = {};
    tasmaxRegionsNcep = {};

    bowenRegionsEra = {};
    tasmaxRegionsEra = {};

    for i = 1:length(regionNames)

        % calculate spatial mean historical bowen
        bowenRegionsNcep{i} = squeeze(bowenNcep(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :)); 
        tasmaxRegionsNcep{i} = squeeze(tasmaxNcep(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :)); 

        bowenRegionsEra{i} = squeeze(bowenEra(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :)); 
        tasmaxRegionsEra{i} = squeeze(tasmaxEra(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :)); 
        
    end
end

% load cmip5 historical data
if ~exist('tasmaxCmip5', 'var')
    fprintf('loading cmip5 data...\n');
    
    % dimensions: x, y, month, model
    bowenCmip5 = [];
    tasmaxCmip5 = [];

    bowenRegionsCmip5 = {};
    tasmaxRegionsCmip5 = {};

    for m = 1:length(models)

        load([tempBaseDir 'monthly-mean-tasmax-cmip5-historical-' models{m} '-all-years.mat']);
        tasmaxCmip5(:, :, m, :, :) = monthlyMeans;

        %load([bowenBaseDir 'monthly-mean-bowen-cmip5-historical-' models{m} '-all-years-.mat']);
        curBowen = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/historical/bowen/regrid/world'], 'bowe', 'yearStart', 1985, 'yearEnd', 2004);
        bowenCmip5(:, :, m, :, :) = curBowen{3};

        %bowenCmip5(bowenCmip5 > 100) = NaN;
        %bowenCmip5(bowenCmip5 < 0) = NaN;

    end

    % loop over regions and extract bowen & tasmax change data
    for i = 1:length(regionNames)

        bowenRegionsCmip5{i} = squeeze(bowenCmip5(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :, :)); 
        tasmaxRegionsCmip5{i} = squeeze(tasmaxCmip5(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :, :)); 
    end
end

% plot ----------------------------------------------------

% loop over all regions for plotting
%for i = 1:length(regionNames)
fprintf('processing correlations...\n');

figure('Color', [1,1,1]);
set(gcf, 'Position', get(0,'Screensize'));

subploti = 1;
for i = [1, 2, 4, 7]
    % mean temperature change across models
    tasmaxNcep = tasmaxRegionsNcep{i};
    bowenNcep = bowenRegionsNcep{i};
    tasmaxEra = tasmaxRegionsEra{i};
    bowenEra = bowenRegionsEra{i};
    tasmaxCmip5 = tasmaxRegionsCmip5{i};
    bowenCmip5 = bowenRegionsCmip5{i};
    
    seasons = [[12 1 2];
               [3 4 5];
               [6 7 8];
               [9 10 11]];
    
    cmip5Corr = zeros(size(tasmaxNcep, 1), size(tasmaxNcep, 2), length(models), size(seasons, 1));
    ncepCorr = zeros(size(tasmaxNcep, 1), size(tasmaxNcep, 2), size(seasons, 1));
    eraCorr = zeros(size(tasmaxNcep, 1), size(tasmaxNcep, 2), size(seasons, 1));
    
    cmip5Corr(cmip5Corr == 0) = NaN;
    ncepCorr(ncepCorr == 0) = NaN;
    eraCorr(eraCorr == 0) = NaN;
    % loop over all gridboxes
    for xlat = 1:size(tasmaxNcep, 1)
        for ylon = 1:size(tasmaxNcep, 2)
            if waterGrid(xlat, ylon)
                ncepCorr(xlat, ylon, 1:4) = NaN;
                continue;
            end
            
            % loop over all seasons
            for season = 1:size(seasons, 1)
                % list of seasonal mean bowen/temp values for each gridbox
                % in region and for each year
                curT = squeeze(nanmean(tasmaxNcep(xlat, ylon, :, seasons(season, :)), 4));
                curB = squeeze(nanmean(bowenNcep(xlat, ylon, :, seasons(season, :)), 4));
                
                nn = find(~isnan(curT) & ~isnan(curB));
                curT = curT(nn);
                curB = curB(nn);
                
                % calculate seasonal corr for each grid cell
                if length(curB) > 10
                    ncepCorr(xlat, ylon, season) = corr(curT, curB);
                end
                
                curT = squeeze(nanmean(tasmaxEra(xlat, ylon, :, seasons(season, :)), 4));
                curB = squeeze(nanmean(bowenEra(xlat, ylon, :, seasons(season, :)), 4));
                
                nn = find(~isnan(curT) & ~isnan(curB));
                curT = curT(nn);
                curB = curB(nn);
                
                % calculate seasonal corr for each grid cell
                if length(curB) > 10
                    eraCorr(xlat, ylon, season) = corr(curT, curB);
                end
                
                % same over all cmip5 models
                for model = 1:length(models)
                    curT = squeeze(nanmean(tasmaxCmip5(xlat, ylon, model, :, seasons(season, :)), 5));
                    curB = squeeze(nanmean(bowenCmip5(xlat, ylon, model, :, seasons(season, :)), 5));
                    cmip5Corr(xlat, ylon, model, season) = corr(curT, curB);
                end
            end
            
        end
    end
    
    h(subploti) = subplot(1,4,subploti);
    hold on;
    axis square;
    grid on;
    box on;
    % plot area average seasonal temp-bowen correlations
    b = boxplot(squeeze(nanmean(nanmean(cmip5Corr, 2), 1)));
    plot(1:4, squeeze(nanmean(nanmean(ncepCorr, 2), 1)), 'ko', 'MarkerSize', 15, 'LineWidth', 2);
    plot(1:4, squeeze(nanmean(nanmean(eraCorr, 2), 1)), 'kx', 'MarkerSize', 15, 'LineWidth', 2);

    set(b,{'LineWidth', 'Color'},{2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2);
    
    set(gca, 'XTick', [1,2,3,4], 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});
    set(gca, 'FontSize', 24);
    if subploti == 1
        ylabel('T_{max} - Bowen Correlation', 'FontSize', 24);
    end
    ylim([-1 1])
    title(regionNames{i});
    xtickangle(45);
    subploti = subploti + 1;
end

spacing = .05;
width = (1-(5*spacing))/4.0;

for i = 1:length(h)
    p(i,:) = get(h(i), 'position');
end

for i = 1:length(h)
    set(h(i), 'position', [(i+.5)*spacing+(i-1)*width p(i,2) width nanmean(p(:,4))]);
end

export_fig(['temp-bowen-corr.eps']);
close all;
    