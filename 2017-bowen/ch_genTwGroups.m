
dataset = 'cmip5';
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};
          
var = 'wb-davies-jones-full';          

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

for m = 1:length(models)
    efGroup = zeros(size(lat,1),size(lat,2));
    
    if exist(['e:/data/projects/bowen/derived-chg/var-stats/twGroup-' models{m} '.mat'])
        %continue;
    end
    
    load(['2017-bowen/txx-timing/wb-davies-jones-full-months-' models{m} '-historical-cmip5-1981-2005.mat']);
    txxMonthsHist = txxMonths;

    fprintf('loading %s...\n', models{m});
    twHist = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/' var '/regrid/world'], 'startYear', 1981, 'endYear', 2005);
    twHist = twHist{3};
    
    warmSeasonMean = [];
    
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)            
            curTxxMonthsHist = unique(squeeze(txxMonthsHist(xlat, ylon, :)));
            if length(find(isnan(curTxxMonthsHist))) > 0
                warmSeasonMean(xlat, ylon) = NaN;
                continue;
            end
            warmSeasonMean(xlat, ylon) = squeeze(nanmean(nanmean(nanmean(twHist(xlat, ylon, :, curTxxMonthsHist, :), 5), 4), 3));            
        end
    end
    
    warmSeasonMean(1:15,:) = NaN;
    warmSeasonMean(75:90,:) = NaN;
    warmSeasonMean(waterGrid) = NaN;
    
    warmSeasonMeanLin = reshape(warmSeasonMean, [numel(warmSeasonMean),1]);
    warmSeasonMeanP = [];
    percRange = 0:20:100;
    for p = 1:length(percRange)
        warmSeasonMeanP(p) = prctile(warmSeasonMeanLin, percRange(p));
    end
    
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)            
            if isnan(warmSeasonMean(xlat, ylon))
                twGroup(xlat, ylon) = NaN;
            else
                twGroup(xlat, ylon) = find(abs(warmSeasonMean(xlat, ylon) - warmSeasonMeanP) == min(abs(warmSeasonMean(xlat, ylon) - warmSeasonMeanP)));
            end
        end
    end
    
    clear twHist;
    save(['e:/data/projects/bowen/derived-chg/var-stats/twGroup-' models{m} '.mat'], ['twGroup']);
end

