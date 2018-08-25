models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mri-cgcm3', 'noresm1-m'};
          
load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];

regionBoundsNorth = [[15 32]; [29, 34]];
regionBoundsBlue = [[8 14]; [34, 40]];
regionBoundsWhite = [[3 14]; [27, 33.5]];

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsBlue, lonIndsBlue] = latLonIndexRange({lat,lon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhite, lonIndsWhite] = latLonIndexRange({lat,lon,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));


latIndsNorth = latIndsNorth - latInds(1) + 1;
lonIndsNorth = lonIndsNorth - lonInds(1) + 1;
latIndsBlue = latIndsBlue - latInds(1) + 1;
lonIndsBlue = lonIndsBlue - lonInds(1) + 1;
latIndsWhite = latIndsWhite - latInds(1) + 1;
lonIndsWhite = lonIndsWhite - lonInds(1) + 1;


mind = 1;
mrsosChg = [];

for m = mind:length(models)
    models{m}
    mrsos = loadMonthlyData(['e:/data/cmip5/output/' models{m} '/mon/r1i1p1/rcp85/mrsos/regrid/world'], 'mrsos', 'startYear', 2006, 'endYear', 2099);
    mrsosChg(:,:,:,:,mind) = mrsos{3}(latInds,lonInds,1:90,:);
    mind = mind + 1;
end