models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
timePeriod = 1981:2005;

load E:\data\projects\bowen\derived-chg\txChgWarm.mat
load('2017-bowen/hottest-season-txx-rel-cmip5-all-txx.mat');

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

% look for days above 95th percentile
thresh = 99;

recurHist = zeros(size(lat,1), size(lat,2), length(timePeriod), length(models));
recurHist(recurHist == 0) = NaN;
recurTxShift = zeros(size(lat,1), size(lat,2), length(timePeriod), length(models));
recurTxShift(recurTxShift == 0) = NaN;
recurAmp = zeros(size(lat,1), size(lat,2), length(timePeriod), length(models));
recurAmp(recurAmp == 0) = NaN;

for m = 1:length(models)
    fprintf('loading %s historical...\n', models{m});
    t = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    fprintf('loading %s future...\n', models{m});
    tFut = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/rcp85/tasmax/regrid/world'], 'startYear', 2061, 'endYear', 2085);
    t = t{3};
    tFut = tFut{3};
    if nanmean(nanmean(nanmean(nanmean(nanmean(t)))))>100
        t = t-273.15;
    end
    if nanmean(nanmean(nanmean(nanmean(nanmean(tFut)))))>100
        tFut = tFut-273.15;
    end
    
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            
            if waterGrid(xlat, ylon) || isnan(txChgWarm(xlat, ylon, m))
                continue;
            end
            
            months = [squeeze(hottestSeason(xlat, ylon, m)-1) squeeze(hottestSeason(xlat, ylon, m)) squeeze(hottestSeason(xlat, ylon, m)+1)];
            months(months == 0) = 12;
            months(months == 13) = 1;

            curt = squeeze(t(xlat, ylon, :, months, :));
            curt = reshape(permute(curt, [3 2 1]), [numel(curt),1]);
            curThresh = prctile(curt, thresh);
            
            for year = 1:size(t, 3)
                curt = squeeze(t(xlat, ylon, year, months, :));
                curt = reshape(permute(curt, [2 1]), [numel(curt), 1]);
                recurHist(xlat, ylon, year, m) = length(find(curt>curThresh));
                recurTxShift(xlat, ylon, year, m) = length(find((curt+txChgWarm(xlat, ylon, m))>curThresh));
                
                curtfut = squeeze(tFut(xlat, ylon, year, months, :));
                curtfut = reshape(permute(curtfut, [2 1]), [numel(curtfut), 1]);
                recurAmp(xlat, ylon, year, m) = length(find(curtfut>curThresh));
            end
            
        end
    end
    
    clear t tFut;
    
end

data = {recurHist, recurTxShift, recurAmp};
save('recurChg-99', 'data');

result = {lat,lon,nanmedian(squeeze(nanmean(data{3},3))-squeeze(nanmean(data{2},3)),3)};
    
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-5 5], ...
                  'cbXTicks', -5:1:5, ...
                  'plotTitle', [''], ...
                  'fileTitle', ['recur-amp-txshift-99.eps'], ...
                  'plotXUnits', ['Days per warm season'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*RdBu'));

plotFromDataFile(saveData);



result = {lat,lon,nanmedian(squeeze(nanmean(data{3},3))-squeeze(nanmean(data{1},3)),3)};
    
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [0 60], ...
                  'cbXTicks', 0:10:60, ...
                  'plotTitle', [''], ...
                  'fileTitle', ['recur-amp-hist-99.eps'], ...
                  'plotXUnits', ['Days per warm season'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], 'Reds'));

plotFromDataFile(saveData);
