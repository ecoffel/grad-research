
dataset = 'cmip5';
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

v1 = [];
v2 = [];

for m = 1:length(models)
    load(['E:\data\projects\bowen\derived-chg\var-txx-amp\efTxxAmp-movingWarm-' models{m} '.mat']);
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txxAmp-' models{m} '.mat']);
    
%     load(['e:/data/projects/bowen/derived-chg/var-txx-amp/wbTxxChg-movingWarm-txxDays-' models{m} '.mat']);
%     load(['e:/data/projects/bowen/derived-chg/var-txx-amp/tasmaxTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    
    %efTxxAmp(abs(efTxxAmp)>1) = NaN;
    %efStdChg(abs(efStdChg)>1) = NaN;
    
    v1(:, :, m) = wbTxxChg;
    v2(:, :, m) = tasmaxTxxChg;
    
end


wbTxxChg = v1;
tasmaxWbChg = v2;
save(['E:\data\projects\bowen\derived-chg\wbTxxChg.mat'], 'wbTxxChg');
save(['E:\data\projects\bowen\derived-chg\tasmaxWbChg.mat'], 'tasmaxWbChg');



