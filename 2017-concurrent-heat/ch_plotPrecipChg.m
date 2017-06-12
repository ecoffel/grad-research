
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

% historical and future monthly precip, mm/day
% dims: (x, y, month, year)
prHistorical = {};
prFuture = {};

for model = 1:length(models)
    
    ['loading ' models{model} '...']
    
    % load historical precip
    curMonthlyPrecipHistorical = loadMonthlyData([baseDir '/' models{model} '/r1i1p1/historical/pr/amon/regrid/world'], 'pr', 'yearStart', timePeriodHistorical(1), 'yearEnd', timePeriodHistorical(end));
    
    % and load future precip
    curMonthlyPrecipFuture = loadMonthlyData([baseDir '/' models{model} '/r1i1p1/rcp85/pr/amon/regrid/world'], 'pr', 'yearStart', timePeriodFuture(1), 'yearEnd', timePeriodFuture(end));
        
    % loop over all regions
    for region = 1:length(regionLatLonInd)
    
        % lat/lon index range for current region
        curLat = regionLatLonInd{region}{1};
        curLon = regionLatLonInd{region}{2};
        
        % add cell for region if not there already
        if length(prHistorical) < region
            prHistorical{region} = [];
            prFuture{region} = [];
        end
        
        for month = 1:12
        
            % loop over all years of historical data
            for year = 1:length(curMonthlyPrecipHistorical{month})
                % get precip in mm/day for current month, model, and region
                prHistorical{region}(:, :, month, model) = nanmean(curMonthlyPrecipHistorical{month}{year}{3}(curLat, curLon)) * 60 * 60 * 24;
            end
            
            % loop over all years of future data
            for year = 1:length(curMonthlyPrecipFuture{month})
                % get precip in mm/day for current month, model, and region
                prFuture{region}(:, :, month, model) = nanmean(curMonthlyPrecipFuture{month}{year}{3}(curLat, curLon)) * 60 * 60 * 24;
            end
        end
        
    end
end






