
baseDir = 'e:/data/cmip5/output';
                  
soilVar = 'mrsos';
soilMonthIndicator = 'lmon';

if strcmp(soilVar, 'mrso')
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
elseif strcmp(soilVar, 'mrsos')
    models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mri-cgcm3', 'noresm1-m'};
elseif strcmp(soilVar, 'snw')
    models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
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
    curMonthlySoilHistorical = loadMonthlyData([baseDir '/' models{model} '/mon/r1i1p1/historical/' soilVar '/regrid/world'], soilVar, 'yearStart', timePeriodHistorical(1), 'yearEnd', timePeriodHistorical(end));
    
    % and load future precip
    curMonthlySoilFuture = loadMonthlyData([baseDir '/' models{model} '/mon/r1i1p1/rcp85/' soilVar '/regrid/world'], soilVar, 'yearStart', timePeriodFuture(1), 'yearEnd', timePeriodFuture(end));
  
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






