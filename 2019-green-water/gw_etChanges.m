load('2019-green-water/gldasData-regrid.mat');
load('2019-green-water/gwfpData-regrid.mat');



diff = nanmean(nanmean(gldasData(:, :, end-10:end, [6, 7, 8]), 4), 3) - ...
       nanmean(nanmean(gldasData(:, :, 1:10, [6, 7, 8]), 4), 3);

   
   
   
plotModelData({lat, lon, nanmean(gwfpData(:, :, [6, 7, 8]), 3) ./ nanmean(nanmean(gldasData(:, :, 1995-1981+1:2004-1981+1, [6, 7, 8]), 4), 3)}, 'world', 'caxis', [0 1])   
plotModelData({lat, lon, }, 'world', 'caxis', [0 50])   
plotModelData({lat, lon, diff}, 'world', 'caxis', [-15 15])