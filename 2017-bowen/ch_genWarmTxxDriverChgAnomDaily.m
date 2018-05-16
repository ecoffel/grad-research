
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

dailyAnom = [];
finalTxxAmp = [];

warmSeason = false;

load('2017-bowen/hottest-season-txx-rel-cmip5-all-txx.mat');

for m = 1:length(models)
    load(['E:\data\projects\bowen\derived-chg\var-txx-amp\efTxxAmp-movingWarm-' models{m} '.mat']);
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txxAmp-' models{m} '.mat']);
    
    efTxxAmp(abs(efTxxAmp)>1) = NaN;
    
    %efStdChg(abs(efStdChg)>1) = NaN;
    
    if warmSeason
        for xlat = 1:size(lat, 1)
            for ylon = 1:size(lat, 2)
                if isnan(hottestSeason(xlat, ylon, m))
                    dailyAnom(xlat, ylon) = NaN;
                    continue;
                end
                
                months = [squeeze(hottestSeason(xlat, ylon, m)-1) squeeze(hottestSeason(xlat, ylon, m)) squeeze(hottestSeason(xlat, ylon, m)+1)];
                months(months == 0) = 12;
                months(months == 13) = 1;
                
                dailyAnom(xlat, ylon, m) = nanmean(efStdChg(xlat, ylon, months), 3);
            end
        end
    else
        dailyAnom(:, :, m) = efTxxAmp;
    end
    finalTxxAmp(:, :, m) = txxAmp;
    
end

txxAmp = finalTxxAmp;
efChgDailyWarmTxxAnom = dailyAnom;
save(['E:\data\projects\bowen\derived-chg\efChgDailyWarmTxxAnom.mat'], 'efChgDailyWarmTxxAnom');
save(['E:\data\projects\bowen\derived-chg\efTxxAmp.mat'], 'txxAmp');



