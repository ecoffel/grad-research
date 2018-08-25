models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

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

prHistBlue = [];
prFutBlue = [];

prcExtHist = [];
prcExtFut = [];
for m = 1:length(models)
    models{m}
    prHist = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/pr/regrid/world'], 'startYear', 1981, 'endYear', 2005);
    curprHistBlue = squeeze(nanmean(nanmean(prHist{3}(latIndsBlue, lonIndsBlue, :, 1:12, :), 2), 1));
    prHistBlue(:,:,m) = reshape(permute(curprHistBlue, [3 2 1]), [size(curprHistBlue, 3)*size(curprHistBlue, 2), size(curprHistBlue, 1)]);
    
    prFut = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/rcp85/pr/regrid/world'], 'startYear', 2075, 'endYear', 2099);
    curprFutBlue = squeeze(nanmean(nanmean(prFut{3}(latIndsBlue, lonIndsBlue, :, 1:12, :), 2), 1));
    prFutBlue(:,:,m) = reshape(permute(curprFutBlue, [3 2 1]), [size(curprFutBlue, 3)*size(curprFutBlue, 2), size(curprFutBlue, 1)]); 
    
    ph = reshape(prHistBlue(:,:,m), [numel(prHistBlue(:,:,m)),1]);
    pf = reshape(prFutBlue(:,:,m), [numel(prFutBlue(:,:,m)),1]);
    
    ph99 = prctile(ph, 99.5);
    pf99 = prctile(pf, 99.5);
    
    prcExtHist(m) = nansum(ph(ph>ph99))/nansum(ph);
    prcExtFut(m) = nansum(pf(pf>pf99))/nansum(pf); 
end