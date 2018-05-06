
baseDir = 'e:/data';
var = 'pr';                  

metric = 'ConsecDryDays';

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

% historical and future monthly precip, mm/day
% dims: (x, y, model)
regionalDryHistorical = zeros(length(curLat), length(curLon), length(models), 12);
regionalDryHistorical(regionalDryHistorical == 0) = NaN;
regionalDryHistoricalTxx = zeros(length(curLat), length(curLon), length(models));
regionalDryHistoricalTxx(regionalDryHistoricalTxx == 0) = NaN;

regionalDryFuture = zeros(length(curLat), length(curLon), length(models), 12);
regionalDryFuture(regionalDryFuture == 0) = NaN;
regionalDryFutureTxx = zeros(length(curLat), length(curLon), length(models));
regionalDryFutureTxx(regionalDryFutureTxx == 0) = NaN;

for model = 1:length(models)
    fprintf('loading %s historical...\n', models{model});
    pr = loadDailyData([baseDir '/cmip5/output/' models{model} '/r1i1p1/historical/' var], 'startYear', 1981, 'endYear', 2005);
    if strcmp(metric, 'DryDays')
        prMetric = findDryDays(pr{3});
    elseif strcmp(metric, 'Std')
        prMetric = squeeze(nanmean(nanstd(pr{3}, [], 5),3));
    elseif strcmp(metric, 'ConsecDryDays')
        prMetric = findConsecDryDays(pr{3});
    end

    metricRegrid = [];
    for year = 1:size(prMetric, 3)
        for month = 1:12
            ddr = regridGriddata({pr{1},pr{2},prMetric(:,:,year,month)},{lat,lon,[]},false);
            metricRegrid(:,:,year,month) = ddr{3};
        end
    end
    
    for xlat = 1:size(metricRegrid,1)
        for ylon = 1:size(metricRegrid,2)
            for year = 1:size(metricRegrid, 3)
                if ~isnan(txxMonthsHist(xlat, ylon, model, year))
                    regionalDryHistoricalTxx(xlat, ylon, model) = metricRegrid(xlat, ylon, year, txxMonthsHist(xlat, ylon, model, year));
                end
            end
        end
    end

    regionalDryHistorical(:,:,model,:) = nanmean(metricRegrid,3);
    clear pr prMetric;

    fprintf('loading %s future...\n', models{model});
    pr = loadDailyData([baseDir '/cmip5/output/' models{model} '/r1i1p1/rcp85/' var ], 'startYear', 2060, 'endYear', 2079);
    if strcmp(metric, 'DryDays')
        prMetric = findDryDays(pr{3});
    elseif strcmp(metric, 'Std')
        prMetric = squeeze(nanmean(nanstd(pr{3}, [], 5),3));
    elseif strcmp(metric, 'ConsecDryDays')
        prMetric = findConsecDryDays(pr{3});
    end

    metricRegrid = [];
    for year = 1:size(prMetric, 3)
        for month = 1:12
            ddr = regridGriddata({pr{1},pr{2},prMetric(:,:,year,month)},{lat,lon,[]},false);
            metricRegrid(:,:,year,month) = ddr{3};
        end
    end
    
    for xlat = 1:size(metricRegrid,1)
        for ylon = 1:size(metricRegrid,2)
            for year = 1:size(metricRegrid, 3)
                if ~isnan(txxMonthsFut(xlat, ylon, model, year))
                    regionalDryFutureTxx(xlat, ylon, model) = metricRegrid(xlat, ylon, year, txxMonthsFut(xlat, ylon, model, year));
                end
            end
        end
    end

    regionalDryFuture(:,:,model,:) = nanmean(metricRegrid,3);
    clear pr prMetric;
end


% calculate soil change for each model
chgAbs = [];
chgPer = [];

chgAbsTxx = [];
chgPerTxx = [];

for model = 1:size(regionalDryHistorical, 3)
    tmpHistorical = regionalDryHistorical;
    tmpFuture = regionalDryFuture;
    
    tmpHistoricalTxx = regionalDryHistoricalTxx;
    tmpFutureTxx = regionalDryFutureTxx;

    % change in all seasons
    chgPer(:, :, model, :) = squeeze((tmpFuture(:,:,model,:)-tmpHistorical(:,:,model,:)) ./ tmpHistorical(:,:,model,:));
    % in w/m2
    chgAbs(:, :, model, :) = squeeze(tmpFuture(:,:,model,:)-tmpHistorical(:,:,model,:));

        % change in all seasons
    chgPerTxx(:, :, model, :) = squeeze((tmpFutureTxx(:,:,model,:)-tmpHistoricalTxx(:,:,model,:)) ./ tmpHistoricalTxx(:,:,model,:));
    % in w/m2
    chgAbsTxx(:, :, model, :) = squeeze(tmpFutureTxx(:,:,model,:)-tmpHistoricalTxx(:,:,model,:));

end

% median over models
chgPer = chgPer .* 100;
chgAbs = chgAbs .* 100;
chgPerTxx = chgPerTxx .* 100;
chgAbsTxx = chgAbsTxx .* 100;

eval([var metric 'Chg = chgPer;']);
save(['e:/data/projects/bowen/derived-chg/' var metric '-all-txx.mat'], [var metric 'Chg']);
eval([var metric 'Chg = chgAbs;']);
save(['e:/data/projects/bowen/derived-chg/' var metric '-absolute-all-txx.mat'], [var metric 'Chg']);

eval([var metric 'ChgTxxMonths = chgPerTxx;']);
save(['e:/data/projects/bowen/derived-chg/' var metric 'ChgTxxMonths-percent.mat'], [var metric  'ChgTxxMonths']);
eval([var metric 'ChgTxxMonths = chgAbsTxx;']);
save(['e:/data/projects/bowen/derived-chg/' var metric 'ChgTxxMonths-absolute.mat'], [var metric 'ChgTxxMonths']);
