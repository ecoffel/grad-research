


baseDir = 'e:/data/cmip5/output';
                  
soilVar = 'snw';
soilMonthIndicator = 'limon';

if strcmp(soilVar, 'mrso')
models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                      'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3'};
elseif strcmp(soilVar, 'mrsos')
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                      'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                      'mri-cgcm3'};
elseif strcmp(soilVar, 'snw')
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                      'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3'};
end
    

timePeriodHistorical = 1985:2005;
timePeriodFuture = 2060:2080;

load lat;
load lon;

% historical and future monthly precip, mm/day
% dims: (x, y, month, year)
soilHistorical = [];
soilFuture = [];

for model = 1:length(models)
    
    curModel = models{model};
    
    ['loading ' models{model} '...']
    
    % load historical precip
    curMonthlySoilHistorical = loadMonthlyData([baseDir '/' models{model} '/r1i1p1/historical/' soilVar '/' soilMonthIndicator '/regrid/world'], soilVar, 'yearStart', timePeriodHistorical(1), 'yearEnd', timePeriodHistorical(end));
    
    % and load future precip
    curMonthlySoilFuture = loadMonthlyData([baseDir '/' models{model} '/r1i1p1/rcp85/' soilVar '/' soilMonthIndicator '/regrid/world'], soilVar, 'yearStart', timePeriodFuture(1), 'yearEnd', timePeriodFuture(end));
  
    for month = 1:12

        % loop over all years of historical data
        for year = 1:length(curMonthlySoilHistorical{month})
            % get precip in mm/day for current month, model, and region
            soilHistorical(:, :, month) = curMonthlySoilHistorical{month}{year}{3} .* 60 .* 60 .* 24;
        end

        % loop over all years of future data
        for year = 1:length(curMonthlySoilFuture{month})
            % get precip in mm/day for current month, model, and region
            soilFuture(:, :, month) = curMonthlySoilFuture{month}{year}{3} .* 60 .* 60 .* 24;
        end
    end

    soilChg = soilFuture - soilHistorical;
    
    save(['2017-concurrent-heat/monthly-soil/monthlySoilChg-cmip5-historical-' soilVar '-' curModel '-' num2str(timePeriodHistorical(1)) '-' num2str(timePeriodHistorical(end)) '.mat'], 'soilHistorical');
    save(['2017-concurrent-heat/monthly-soil/monthlySoilChg-cmip5-future-' soilVar '-' curModel '-' num2str(timePeriodFuture(1)) '-' num2str(timePeriodFuture(end)) '.mat'], 'soilFuture');
    
end






