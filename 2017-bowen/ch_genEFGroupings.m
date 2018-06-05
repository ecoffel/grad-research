
dataset = 'cmip5';
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
               'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
models = {'gfdl-cm3'};
var = 'ef';          

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

load('2017-bowen/hottest-season-txx-rel-cmip5-all-txx.mat');

for m = 1:length(models)
    efGroup = zeros(size(lat,1),size(lat,2));
    
    if exist(['e:/data/projects/bowen/derived-chg/var-stats/efGroup-' models{m} '.mat'])
        %continue;
    end
    
    load(['2017-bowen/txx-timing/txx-months-' models{m} '-historical-cmip5-1981-2005.mat']);
    txxMonthsHist = txxMonths;

    fprintf('loading %s...\n', models{m});
    efHist = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/' var '/regrid/world'], 'startYear', 1981, 'endYear', 2005);
    efHist = efHist{3};
    efHist(efHist > 1 | efHist < 0) = NaN;
    
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon)
                continue;
            end
            
            curTxxMonthsHist = unique(squeeze(txxMonthsHist(xlat, ylon, :)));
            
            baseEf = squeeze(nanmean(nanmean(nanmean(efHist(xlat, ylon, :, curTxxMonthsHist, :), 5), 4), 3));
            
            if isnan(baseEf)
                efGroup(xlat, ylon) = NaN;
            else
                if baseEf < .1
                    efGroup(xlat, ylon) = 1;
                elseif baseEf < .33
                    efGroup(xlat, ylon) = 2;
                elseif baseEf < .75
                    efGroup(xlat, ylon) = 3;
                elseif baseEf >= .75
                    efGroup(xlat, ylon) = 4;
                end
            end
        end
    end
    
    clear efHist;
    save(['e:/data/projects/bowen/derived-chg/var-stats/efGroup-' models{m} '.mat'], ['efGroup']);
end

