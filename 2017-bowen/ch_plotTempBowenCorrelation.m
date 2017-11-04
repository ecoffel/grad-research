% plot monthly max temperature change alongside mean monthly bowen ratio changes

dataset = 'reanalysis';

tasmaxMetric = 'monthly-mean-max';
tasminMetric = 'monthly-mean-min';

models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                      'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3'};

% show the percentage change in bowen ratio or the absolute change
showPercentChange = true;

showLegend = false;

% show correlation between Tx and Bowen
showCorr = true;

load waterGrid;
load lat;
load lon;
waterGrid = logical(waterGrid);

bowenBaseDir = 'e:\data\projects\bowen\bowen-chg-data\';
tempBaseDir = 'e:\data\projects\bowen\temp-chg-data\';

% all available models for both bowen and tasmax
availModels = {};

% dimensions: x, y, month, model
bowenCmip5 = [];
tasmaxCmip5 = [];

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
fprintf('loading reanalysis data...\n');
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

% load ncep/era data if needed and conver to monthly mean
if ~exist('tasmaxNcep', 'var')
    tasmaxNcep = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'yearStart', 1985, 'yearEnd', 2005);
    tasmaxNcep{3} = tasmaxNcep{3} - 273.15;
    tasmaxNcep = dailyToMonthly(tasmaxNcep);
    
    bowenNcep = loadDailyData('e:/data/ncep-reanalysis/output/bowen/regrid/world', 'yearStart', 1985, 'yearEnd', 2005);
    bowenNcep{3}(bowenNcep{3} > 50) = NaN;
    bowenNcep{3}(bowenNcep{3} < 0) = NaN;
    bowenNcep = dailyToMonthly(bowenNcep);
    
    for year = 1:size(tasmaxNcep{3}, 3)
        for month = 1:size(tasmaxNcep{3}, 4)
            curGrid = tasmaxNcep{3}(:, :, year, month);
            curGrid(waterGrid) = NaN;
            tasmaxNcep{3}(:, :, year, month) = curGrid;
            
            curGrid = bowenNcep{3}(:, :, year, month);
            curGrid(waterGrid) = NaN;
            bowenNcep{3}(:, :, year, month) = curGrid;
        end
    end
    
    % select data and average over years
    tasmaxNcep = tasmaxNcep{3};
    bowenNcep = bowenNcep{3};
    
    %eraTmax = dailyToMonthly(loadDailyData('e:/data/era-interim/output/mx2t/world/regrid', 'yearStart', 1985, 'yearEnd', 2005));
    %eraBowen = dailyToMonthly(loadDailyData('e:/data/era-interim/output/bowen/world/regrid', 'yearStart', 1985, 'yearEnd', 2005));
end


% load cmip5 historical data
fprintf('loading cmip5 data...\n');
for m = 1:length(models)
   
    load([tempBaseDir 'monthly-mean-tasmax-cmip5-historical-' models{m} '.mat']);
    tasmaxCmip5(:, :, m, :) = monthlyMeans;
    
    load([bowenBaseDir 'monthly-mean-historical-' models{m} '.mat']);
    bowenCmip5(:, :, m, :) = monthlyMeans;
   
end
    
% average bowen (absolute) and temperature change over each region
bowenRegionsNcep = {};
tasmaxRegionsNcep = {};

bowenRegionsCmip5 = {};
tasmaxRegionsCmip5 = {};


% loop over regions and extract bowen & tasmax change data
for i = 1:length(regionNames)
    
    % calculate spatial mean historical bowen
    bowenRegionsNcep{i} = squeeze(bowenNcep(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :)); 
    tasmaxRegionsNcep{i} = squeeze(tasmaxNcep(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :)); 
    
    bowenRegionsCmip5{i} = squeeze(bowenCmip5(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :)); 
    tasmaxRegionsCmip5{i} = squeeze(tasmaxCmip5(regionLatLonInd{i}{1}, regionLatLonInd{i}{2}, :, :)); 
end

% plot ----------------------------------------------------

% loop over all regions for plotting
%for i = 1:length(regionNames)
figure('Color', [1,1,1]);
f = 1;
for i = [1, 2, 4, 7]
    subplot(2,2,f);
    hold on;
    axis square;
    grid on;
    box on;
    f = f+1;
    
    % mean temperature change across models
    tasmaxNcep = tasmaxRegionsNcep{i};
    bowenNcep = bowenRegionsNcep{i};
    tasmaxCmip5 = tasmaxRegionsCmip5{i};
    bowenCmip5 = bowenRegionsCmip5{i};
    
    seasons = [[12 1 2];
               [3 4 5];
               [6 7 8];
               [9 10 11]];
    
    cmip5Corr = [];
    ncepCorr = [];
    % loop over all gridboxes
    for xlat = 1:size(tasmaxNcep, 1)
        for ylon = 1:size(tasmaxNcep, 2)
            if waterGrid(xlat, ylon)
                ncepCorr(xlat, ylon, 1:4) = NaN;
                continue;
            end
            
            % loop over all seasons
            for season = 1:size(seasons, 2)
                % list of seasonal mean bowen/temp values for each gridbox
                % in region and for each year
                curT = squeeze(nanmean(tasmaxNcep(xlat, ylon, :, seasons(season, :)), 4));
                curB = squeeze(nanmean(bowenNcep(xlat, ylon, :, seasons(season, :)), 4));
                
                % calculate seasonal corr for each grid cell
                ncepCorr(xlat, ylon, season) = corr(curT, curB);
                
                % same over all cmip5 models
                for model = 1:length(models)
                    curT = squeeze(nanmean(tasmaxCmip5(xlat, ylon, model, :, seasons(season, :)), 5));
                    curB = squeeze(nanmean(bowenCmip5(xlat, ylon, model, :, seasons(season, :)), 5));
                    cmip5Corr(xlat, ylon, model, season) = corr(curT, curB);
                end
            end
            
        end
    end
    
    % plot area average seasonal temp-bowen correlations
    plot(1:4, squeeze(nanmean(nanmean(ncepCorr, 2), 1)), 'ko', 'MarkerSize', 15, 'LineWidth', 2);
    boxplot(cmip5Cor);
    set(gca, 'XTick', [1,2,3,4], 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});
    ylabel('T_{max} - Bowen Correlation');
    ylim([-1 1])
    title(regionNames{i});
    set(gca, 'FontSize', 24);
end
    