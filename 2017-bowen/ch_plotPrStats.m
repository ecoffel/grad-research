
baseDir = 'e:/data';
var = 'ef';                  

metric = 'Std';

% models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%               'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
plotMap = true;

timePeriodHistorical = 1981:2005;
timePeriodFuture = 2061:2085;

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
load('2017-bowen/hottest-season-txx-rel-cmip5-all-txx.mat');
load('2017-bowen/txx-months-historical-cmip5-1981-2005.mat');
txxMonthsHist = txxMonths;
load('2017-bowen/txx-months-future-cmip5-2061-2085.mat');
txxMonthsFut = txxMonths;

region = 1;

curLat = regionLatLonInd{region}{1};
curLon = regionLatLonInd{region}{2};


for model = 1:length(models)
    
    if exist(['e:/data/projects/bowen/derived-chg/var-stats/' var metric '-absolute-' models{model} '.mat'])
        continue;
    end
    
    % historical and future monthly precip, mm/day
    % dims: (x, y, model)
    regionalMetricHistorical = zeros(length(curLat), length(curLon), 12);
    regionalMetricHistorical(regionalMetricHistorical == 0) = NaN;
    regionalMetricHistoricalTxx = zeros(length(curLat), length(curLon));
    regionalMetricHistoricalTxx(regionalMetricHistoricalTxx == 0) = NaN;

    regionalMetricFuture = zeros(length(curLat), length(curLon), 12);
    regionalMetricFuture(regionalMetricFuture == 0) = NaN;
    regionalMetricFutureTxx = zeros(length(curLat), length(curLon));
    regionalMetricFutureTxx(regionalMetricFutureTxx == 0) = NaN;

    
    fprintf('loading %s historical...\n', models{model});
    try
        driver = loadDailyData([baseDir '/cmip5/output/' models{model} '/r1i1p1/historical/' var '/regrid/world'], 'startYear', 1981, 'endYear', 2005);
    catch 
        continue;
    end
    if strcmp(metric, 'DryDays')
        driverMetric = findDryDays(driver{3});
    elseif strcmp(metric, 'Std')
        driverMetric = squeeze(nanstd(driver{3}(:, :, :, 1:12, :), [], 5));
    elseif strcmp(metric, 'ConsecDryDays')
        driverMetric = findConsecDryDays(driver{3});
    end

%     metricRegrid = [];
%     for year = 1:size(prMetric, 3)
%         for month = 1:12
%             ddr = regridGriddata({driver{1},driver{2},prMetric(:,:,year,month)},{lat,lon,[]},false);
%             metricRegrid(:,:,year,month) = ddr{3};
%         end
%     end
    
    for xlat = 1:size(driverMetric,1)
        for ylon = 1:size(driverMetric,2)
            for year = 1:size(driverMetric, 3)
                if ~isnan(txxMonthsHist(xlat, ylon, model, year))
                    regionalMetricHistoricalTxx(xlat, ylon) = driverMetric(xlat, ylon, year, txxMonthsHist(xlat, ylon, model, year));
                end
            end
        end
    end

    regionalMetricHistorical(:,:,:) = squeeze(nanmean(driverMetric, 3));
    clear driver driverMetric;

    fprintf('loading %s future...\n', models{model});
    driver = loadDailyData([baseDir '/cmip5/output/' models{model} '/r1i1p1/rcp85/' var '/regrid/world'], 'startYear', 2061, 'endYear', 2085);
    if strcmp(metric, 'DryDays')
        driverMetric = findDryDays(driver{3});
    elseif strcmp(metric, 'Std')
        driverMetric = squeeze(nanstd(driver{3}(:, :, :, 1:12, :), [], 5));
    elseif strcmp(metric, 'ConsecDryDays')
        driverMetric = findConsecDryDays(driver{3});
    end

%     metricRegrid = [];
%     for year = 1:size(driverMetric, 3)
%         for month = 1:12
%             ddr = regridGriddata({driver{1},driver{2},driverMetric(:,:,year,month)},{lat,lon,[]},false);
%             metricRegrid(:,:,year,month) = ddr{3};
%         end
%     end
    
    for xlat = 1:size(driverMetric,1)
        for ylon = 1:size(driverMetric,2)
            for year = 1:size(driverMetric, 3)
                if ~isnan(txxMonthsFut(xlat, ylon, model, year))
                    regionalMetricFutureTxx(xlat, ylon) = driverMetric(xlat, ylon, year, txxMonthsFut(xlat, ylon, model, year));
                end
            end
        end
    end

    regionalMetricFuture(:,:,:) = squeeze(nanmean(driverMetric,3));
    clear driver driverMetric;
    
    % calculate soil change for each model
    chgAbs = [];
    chgPer = [];

    chgAbsTxx = [];
    chgPerTxx = [];
    
    tmpHistorical = regionalMetricHistorical;
    tmpFuture = regionalMetricFuture;
    
    tmpHistoricalTxx = regionalMetricHistoricalTxx;
    tmpFutureTxx = regionalMetricFutureTxx;

    % change in all seasons
    chgPer(:, :, :) = squeeze((tmpFuture(:,:,:)-tmpHistorical(:,:,:)) ./ tmpHistorical(:,:,:));
    % in w/m2
    chgAbs(:, :, :) = squeeze(tmpFuture(:,:,:)-tmpHistorical(:,:,:));

        % change in all seasons
    chgPerTxx(:, :, :) = squeeze((tmpFutureTxx(:,:,:)-tmpHistoricalTxx(:,:,:)) ./ tmpHistoricalTxx(:,:,:));
    % in w/m2
    chgAbsTxx(:, :, :) = squeeze(tmpFutureTxx(:,:,:)-tmpHistoricalTxx(:,:,:));

    % median over models
    chgPer = chgPer .* 100;
    chgPerTxx = chgPerTxx .* 100;

    eval([var metric 'Chg = chgPer;']);
    save(['e:/data/projects/bowen/derived-chg/var-stats/' var metric '-percent-' models{model} '.mat'], [var metric 'Chg']);
    eval([var metric 'Chg = chgAbs;']);
    save(['e:/data/projects/bowen/derived-chg/var-stats/' var metric '-absolute-' models{model} '.mat'], [var metric 'Chg']);

    eval([var metric 'ChgTxxMonths = chgPerTxx;']);
    save(['e:/data/projects/bowen/derived-chg/var-stats/' var metric 'ChgTxxMonths-percent-' models{model} '.mat'], [var metric  'ChgTxxMonths']);
    eval([var metric 'ChgTxxMonths = chgAbsTxx;']);
    save(['e:/data/projects/bowen/derived-chg/var-stats/' var metric 'ChgTxxMonths-absolute-' models{model} '.mat'], [var metric 'ChgTxxMonths']);
   
end


