
models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                      'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3'};

baseDir = 'f:/data/cmip5/output';
                  
timePeriodHistorical = 1985:2005;
timePeriodFuture = 2060:2080;

load lat;
load lon;

% historical and future monthly precip, mm/day
% dims: (x, y, month, year)
prHistorical = [];
prFuture = [];

for model = 1:length(models)
    
    curModel = models{model};
    
    ['loading ' models{model} '...']
    
    % load historical precip
    curMonthlyPrecipHistorical = loadMonthlyData([baseDir '/' models{model} '/r1i1p1/historical/pr/amon/regrid/world'], 'pr', 'yearStart', timePeriodHistorical(1), 'yearEnd', timePeriodHistorical(end));
    
    % and load future precip
    curMonthlyPrecipFuture = loadMonthlyData([baseDir '/' models{model} '/r1i1p1/rcp85/pr/amon/regrid/world'], 'pr', 'yearStart', timePeriodFuture(1), 'yearEnd', timePeriodFuture(end));
  
    for month = 1:12

        % loop over all years of historical data
        for year = 1:length(curMonthlyPrecipHistorical{month})
            % get precip in mm/day for current month, model, and region
            prHistorical(:, :, month) = curMonthlyPrecipHistorical{month}{year}{3} .* 60 .* 60 .* 24;
        end

        % loop over all years of future data
        for year = 1:length(curMonthlyPrecipFuture{month})
            % get precip in mm/day for current month, model, and region
            prFuture(:, :, month) = curMonthlyPrecipFuture{month}{year}{3} .* 60 .* 60 .* 24;
        end
    end

    prChg = prFuture - prHistorical;
    
    save(['2017-concurrent-heat/monthly-pr/monthlyPrChg-cmip5-historical-' curModel '-' num2str(timePeriodFuture(1)) '-' num2str(timePeriodFuture(end)) '.mat'], 'prChg');
    
end






