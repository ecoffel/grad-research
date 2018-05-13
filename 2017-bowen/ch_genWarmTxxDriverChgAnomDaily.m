
dataset = 'cmip5';
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};


load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

efChgDailyWarmTxxAnom = [];
finalTxxAmp = [];

for m = 1:length(models)
    load(['E:\data\projects\bowen\derived-chg\var-txx-amp\efTxxAmp-' models{m} '.mat']);
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txxAmp-' models{m} '.mat']);
    
    efTxxAmp(abs(efTxxAmp)>1) = NaN;
    
    efChgDailyWarmTxxAnom(:, :, m) = efTxxAmp;
    finalTxxAmp(:, :, m) = txxAmp;
    
end

txxAmp = finalTxxAmp;
save(['E:\data\projects\bowen\derived-chg\efChgDailyWarmTxxAnom.mat'], 'efChgDailyWarmTxxAnom');
save(['E:\data\projects\bowen\derived-chg\efTxxAmp.mat'], 'txxAmp');



