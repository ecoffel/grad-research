models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
rcp = 'rcp85';
timePeriod = [2051 2080];

load(['2017-nile-climate/output/historical-temp-percentiles-era-interim.mat']);
load(['2017-nile-climate/output/historical-pr-percentiles-era-interim.mat']);

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndsNorth = latIndsNorth - latInds(1) + 1;
lonIndsNorth = lonIndsNorth - lonInds(1) + 1;
latIndsSouth = latIndsSouth - latInds(1) + 1;
lonIndsSouth = lonIndsSouth - lonInds(1) + 1;

seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};
seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

tempFutureCmip5 = [];
prFutureCmip5 = [];
for m = 1:length(models)
    load(['2017-nile-climate/output/tasmax-monthly-chg-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-' models{m} '.mat']);
    tempFutureCmip5(:, :, :, m) = monthlyChg;
    
    load(['2017-nile-climate/output/pr-monthly-chg-cmip5-' rcp '-' num2str(timePeriod(1)) '-' num2str(timePeriod(end)) '-' models{m} '.mat']);
    prFutureCmip5(:, :, :, m) = monthlyChg;
end

plotModelData({lat(latInds,lonInds),lon(latInds,lonInds),squeeze(nanmedian(nanmean(prFutureCmip5(:,:,[12 1 2],:), 3),4))},'nile','caxis',[-.5 .5])
plotModelData({lat(latInds,lonInds),lon(latInds,lonInds),squeeze(nanmedian(nanmean(prFutureCmip5(:,:,[3 4 5],:), 3),4))},'nile','caxis',[-.5 .5])
plotModelData({lat(latInds,lonInds),lon(latInds,lonInds),squeeze(nanmedian(nanmean(prFutureCmip5(:,:,[6 7 8],:), 3),4))},'nile','caxis',[-.5 .5])
plotModelData({lat(latInds,lonInds),lon(latInds,lonInds),squeeze(nanmedian(nanmean(prFutureCmip5(:,:,[9 10 11],:), 3),4))},'nile','caxis',[-.5 .5])
    