models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

          
timePeriod = 1981:2005;

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

% look for days above 95th percentile
thresh = 95;

var = 'tasmax';

recurHist = zeros(size(lat,1), size(lat,2), length(timePeriod), length(models));
recurHist(recurHist == 0) = NaN;
recurTxShift = zeros(size(lat,1), size(lat,2), length(timePeriod), length(models));
recurTxShift(recurTxShift == 0) = NaN;
recurAmp = zeros(size(lat,1), size(lat,2), length(timePeriod), length(models));
recurAmp(recurAmp == 0) = NaN;

for m = 1:length(models)
    
    load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-thresh-range-50-' var '-' models{m} '-rcp85-2061-2085-all-txx.mat']);
    chgData(waterGrid) = NaN;
    chgData(1:15,:) = NaN;
    chgData(75:90,:) = NaN;
    warmChg = chgData;
    
    fprintf('loading %s historical...\n', models{m});
    t = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/' var '/regrid/world'], 'startYear', timePeriod(1), 'endYear', timePeriod(end));
    fprintf('loading %s future...\n', models{m});
    tFut = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/rcp85/' var '/regrid/world'], 'startYear', 2061, 'endYear', 2085);
    t = t{3};
    tFut = tFut{3};
    if nanmean(nanmean(nanmean(nanmean(nanmean(t)))))>100
        t = t-273.15;
    end
    if nanmean(nanmean(nanmean(nanmean(nanmean(tFut)))))>100
        tFut = tFut-273.15;
    end
    
    load(['2017-bowen/txx-timing/txx-months-' models{m} '-historical-cmip5-1981-2005.mat']);
    txxMonthsHist = txxMonths;
    load(['2017-bowen/txx-timing/txx-months-' models{m} '-future-cmip5-2061-2085.mat']);
    txxMonthsFut = txxMonths;
    
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lat, 2)
            
            if waterGrid(xlat, ylon) || isnan(warmChg(xlat, ylon))
                continue;
            end
            
%             months = [squeeze(hottestSeason(xlat, ylon, m)-1) squeeze(hottestSeason(xlat, ylon, m)) squeeze(hottestSeason(xlat, ylon, m)+1)];
%             months(months == 0) = 12;
%             months(months == 13) = 1;

            curTxxMonthsHist = unique(squeeze(txxMonthsHist(xlat, ylon, :)));
            curTxxMonthsFut = unique(squeeze(txxMonthsFut(xlat, ylon, :)));
            
            if length(find(isnan(curTxxMonthsHist))) == 0
            
                curt = squeeze(t(xlat, ylon, :, curTxxMonthsHist, :));
                curt = reshape(permute(curt, [3 2 1]), [numel(curt),1]);
                curThresh = prctile(curt, thresh);

                for year = 1:size(t, 3)
                    curt = squeeze(t(xlat, ylon, year, curTxxMonthsHist, :));
                    curt = reshape(permute(curt, [2 1]), [numel(curt), 1]);
                    recurHist(xlat, ylon, year, m) = length(find(curt>curThresh));
                    recurTxShift(xlat, ylon, year, m) = length(find((curt+warmChg(xlat, ylon))>curThresh));

                    curtfut = squeeze(tFut(xlat, ylon, year, curTxxMonthsFut, :));
                    curtfut = reshape(permute(curtfut, [2 1]), [numel(curtfut), 1]);
                    recurAmp(xlat, ylon, year, m) = length(find(curtfut>curThresh));
                end
            else
                for year = 1:size(t, 3)
                    recurHist(xlat, ylon, year, m) = NaN;
                    recurTxShift(xlat, ylon, year, m) = NaN;
                    recurAmp(xlat, ylon, year, m) = NaN;
                end
            end
            
        end
    end
    
    clear t tFut;
    
end

data = {recurHist, recurTxShift, recurAmp};
save('recurChg-95-tx', 'data');

result = {lat,lon,nanmedian(squeeze(nanmean(data{3}-data{2},3)),3)};
    
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-20 20], ...
                  'cbXTicks', -20:5:20, ...
                  'plotTitle', [''], ...
                  'fileTitle', ['recur-amp-tx-95.eps'], ...
                  'plotXUnits', ['Days per warm season'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], '*RdBu'));

plotFromDataFile(saveData);



result = {lat,lon,nanmedian(squeeze(nanmean(data{2},3))-squeeze(nanmean(data{1},3)),3)};
    
saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [0 100], ...
                  'cbXTicks', 0:20:100, ...
                  'plotTitle', [''], ...
                  'fileTitle', ['recur-amp-warm-99.eps'], ...
                  'plotXUnits', ['Days per warm season'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([], 'Reds'));

plotFromDataFile(saveData);
