baseDataset = 'ncep-reanalysis';
baseDir = '2017-nile-climate/output';

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

switch (baseDataset)
    case 'era-interim'
        fprintf('loading ERA...\n');
        models = {''};
        prBase = loadDailyData(['E:\data\era-interim\output\tp\regrid\world'], 'startYear', 1980, 'endYear', 2016);
        prBase = dailyToMonthly(prBase);
        prBase = prBase{3}(latInds, lonInds, :, :, :) .* 1000;
    case 'ncep-reanalysis'
        fprintf('loading NCEP...\n');
        models = {''};
        prBase = loadDailyData(['E:\data\ncep-reanalysis\output\prate\regrid\world'], 'startYear', 1980, 'endYear', 2016);
        prBase = dailyToMonthly(prBase);
        prBase = prBase{3}(latInds, lonInds, :, :, :) .* 3600 .* 24;
        
end

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
rcp = 'rcp85';
timePeriod = [2021 2050];

for m = 1:length(models)
    fprintf('processing %s...\n', models{m});
    load([baseDir '/pr-monthly-chg-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-' models{m} '.mat']);

    prFuture = prBase;
    
    % apply changes to each month of base data...
    for year = 1:size(prBase, 3)
        for month = 1:12
            prFuture(:, :, year, month) = prFuture(:, :, year, month) + monthlyChg(:, :, month);
        end
    end
    
    save([baseDir '/projections/pr-monthly-future-' baseDataset '-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-' models{m} '.mat'], 'prFuture');
end