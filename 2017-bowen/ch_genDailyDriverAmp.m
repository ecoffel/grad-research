
dataset = 'cmip5';
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
               'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5'};%, 'csiro-mk3-6-0', ...
%               'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
var = 'zg';          

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

load('2017-bowen/hottest-season-txx-rel-cmip5-all-txx.mat');

for m = 1:length(models)
    if exist(['e:/data/projects/bowen/derived-chg/var-txx-amp/' var 'TxxAmp-' models{m} '.mat'])
        continue;
    end
    
    fprintf('loading %s...\n', models{m});
    driverHist = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/' var '/regrid/world'], 'startYear', 1981, 'endYear', 2005);
    driverFut = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/rcp85/' var '/regrid/world'], 'startYear', 2061, 'endYear', 2085);

    load(['2017-bowen/txx-timing/txx-days-' models{m} '-historical-' dataset '-1981-2005.mat']);
    txxDaysHist = txxDays;
    load(['2017-bowen/txx-timing/txx-days-' models{m} '-future-' dataset '-2061-2085.mat']);
    txxDaysFut = txxDays;
    
    driverHist = driverHist{3};
    driverFut = driverFut{3};
    
    driverTxxHist = zeros(size(lat, 1), size(lat, 2), 25);
    driverTxxHist(driverTxxHist == 0) = NaN;
    driverTxxFut = zeros(size(lat, 1), size(lat, 2), 25);
    driverTxxFut(driverTxxFut == 0) = NaN;

    driverWarmChg = zeros(size(lat, 1), size(lat, 2));
    driverWarmChg(driverWarmChg == 0) = NaN;
    
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            if waterGrid(xlat, ylon)
                continue;
            end
            
            months = [squeeze(hottestSeason(xlat, ylon, m)-1) squeeze(hottestSeason(xlat, ylon, m)) squeeze(hottestSeason(xlat, ylon, m)+1)];
            months(months == 0) = 12;
            months(months == 13) = 1;
            
            driverWarmChg(xlat, ylon) = squeeze(nanmean(nanmean(nanmean(driverFut(xlat, ylon,:,months,:), 5), 4), 3)) - squeeze(nanmean(nanmean(nanmean(driverHist(xlat, ylon,:,months,:), 5), 4), 3));
            
            for year = 1:size(driverHist, 3)
                curDriverHist = squeeze(reshape(permute(squeeze(driverHist(xlat, ylon, year, :, :)), [2 1]), [numel(driverHist(xlat, ylon, year, :, :)), 1]));
                driverTxxHist(xlat, ylon, year) = curDriverHist(txxDaysHist(xlat, ylon, year));
                
                curDriverFut = squeeze(reshape(permute(squeeze(driverFut(xlat, ylon, year, :, :)), [2 1]), [numel(driverFut(xlat, ylon, year, :, :)), 1]));
                driverTxxFut(xlat, ylon, year) = curDriverFut(txxDaysFut(xlat, ylon, year));
            end
        end
    end
    
    clear driverHist driverFut;
    
    driverTxxChg = nanmean(driverTxxFut, 3) - nanmean(driverTxxHist, 3);
    driverTxxAmp = driverTxxChg - driverWarmChg;
    
    eval([var 'TxxChg = driverTxxChg;']);
    eval([var 'TxxAmp = driverTxxAmp;']);
    eval([var 'WarmChg = driverWarmChg;']);
    
    save(['e:/data/projects/bowen/derived-chg/var-txx-amp/' var 'TxxAmp-' models{m} '.mat'], [var 'TxxAmp']);
    save(['e:/data/projects/bowen/derived-chg/var-txx-amp/' var 'TxxChg-' models{m} '.mat'], [var 'TxxChg']);
    save(['e:/data/projects/bowen/derived-chg/var-txx-amp/' var 'WarmChg-' models{m} '.mat'], [var 'WarmChg']);
end

