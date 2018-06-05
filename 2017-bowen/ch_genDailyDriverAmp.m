
dataset = 'cmip5';
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
               'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};
models = {'access1-0'};
var = 'huss';          

useTxxDays = true;

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

load('2017-bowen/hottest-season-txx-rel-cmip5-all-txx.mat');

for m = 1:length(models)
    if exist(['e:/data/projects/bowen/derived-chg/var-txx-amp/' var 'TxxAmp-movingWarm-' models{m} '.mat'])
        %continue;
    end
    
    load(['2017-bowen/txx-timing/wb-davies-jones-full-months-' models{m} '-historical-cmip5-1981-2005.mat']);
    txxMonthsHist = txxMonths;

    load(['2017-bowen/txx-timing/wb-davies-jones-full-months-' models{m} '-future-cmip5-2061-2085.mat']);
    txxMonthsFut = txxMonths;
    
    fprintf('loading %s...\n', models{m});
    driverHist = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/' var '/regrid/world'], 'startYear', 1981, 'endYear', 2005);
    driverFut = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/rcp85/' var '/regrid/world'], 'startYear', 2061, 'endYear', 2085);

    if strcmp(var, 'wb-davies-jones-full') || strcmp(var, 'tasmax')
        if nanmean(nanmean(nanmean(nanmean(nanmean(driverHist{3}))))) > 100
            driverHist{3} = driverHist{3} - 273.15;
        end
        if nanmean(nanmean(nanmean(nanmean(nanmean(driverFut{3}))))) > 100
            driverFut{3} = driverFut{3} - 273.15;
        end
    end
    
    if ~useTxxDays
        load(['2017-bowen/txx-timing/wb-davies-jones-full-days-' models{m} '-historical-' dataset '-1981-2005.mat']);
        txxDaysHist = txxDays;
        load(['2017-bowen/txx-timing/wb-davies-jones-full-days-' models{m} '-future-' dataset '-2061-2085.mat']);
        txxDaysFut = txxDays;
    else
        load(['2017-bowen/txx-timing/txx-days-' models{m} '-historical-' dataset '-1981-2005.mat']);
        txxDaysHist = txxDays;
        load(['2017-bowen/txx-timing/txx-days-' models{m} '-future-' dataset '-2061-2085.mat']);
        txxDaysFut = txxDays;
    end
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
            
            curTxxMonthsHist = unique(squeeze(txxMonthsHist(xlat, ylon, :)));
            curTxxMonthsFut = unique(squeeze(txxMonthsFut(xlat, ylon, :)));
            
            if length(find(~isnan(curTxxMonthsHist))) == 0 || length(find(~isnan(curTxxMonthsFut))) == 0
                continue;
            end
            
%             months = [squeeze(hottestSeason(xlat, ylon, m)-1) squeeze(hottestSeason(xlat, ylon, m)) squeeze(hottestSeason(xlat, ylon, m)+1)];
%             months(months == 0) = 12;
%             months(months == 13) = 1;
            
            driverWarmChg(xlat, ylon) = squeeze(nanmean(nanmean(nanmean(driverFut(xlat, ylon,:,curTxxMonthsFut,:), 5), 4), 3)) - squeeze(nanmean(nanmean(nanmean(driverHist(xlat, ylon,:,curTxxMonthsHist,:), 5), 4), 3));
            
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
    
    if strcmp(var, 'wb-davies-jones-full')
        varName = 'wb';
    else
        varName = var;
    end
    
    eval([varName 'TxxChg = driverTxxChg;']);
    eval([varName 'TxxAmp = driverTxxAmp;']);
    eval([varName 'WarmChg = driverWarmChg;']);
    eval([varName 'TxxHist = driverTxxHist;']);
    eval([varName 'TxxFut = driverTxxFut;']);
    
    if useTxxDays
        save(['e:/data/projects/bowen/derived-chg/var-txx-amp/' varName 'TxxAmp-movingWarm-txxDays-' models{m} '.mat'], [varName 'TxxAmp']);
        save(['e:/data/projects/bowen/derived-chg/var-txx-amp/' varName 'TxxChg-movingWarm-txxDays-' models{m} '.mat'], [varName 'TxxChg']);
        save(['e:/data/projects/bowen/derived-chg/var-txx-amp/' varName 'WarmChg-movingWarm-txxDays-' models{m} '.mat'], [varName 'WarmChg']);
        
        save(['e:/data/projects/bowen/' var '-chg-data/' var '-txx-historical-1981-2005-' models{m} '-txxDays.mat'], [varName 'TxxHist']);    
        save(['e:/data/projects/bowen/' var '-chg-data/' var '-txx-future-2061-2085-' models{m} '-txxDays.mat'], [varName 'TxxFut']);

    else
        save(['e:/data/projects/bowen/derived-chg/var-txx-amp/' varName 'TxxAmp-movingWarm-wbDays-' models{m} '.mat'], [varName 'TxxAmp']);
        save(['e:/data/projects/bowen/derived-chg/var-txx-amp/' varName 'TxxChg-movingWarm-wbDays-' models{m} '.mat'], [varName 'TxxChg']);
        save(['e:/data/projects/bowen/derived-chg/var-txx-amp/' varName 'WarmChg-movingWarm-wbDays-' models{m} '.mat'], [varName 'WarmChg']);
        
        save(['e:/data/projects/bowen/' var '-chg-data/' var '-wb-historical-1981-2005-' models{model} '-wbDays.mat'], [varName 'TxxHist']);    
        save(['e:/data/projects/bowen/' var '-chg-data/' var '-wb-future-2061-2085-' models{model} '-wbDays.mat'], [varName 'TxxFut']);
    end
end

