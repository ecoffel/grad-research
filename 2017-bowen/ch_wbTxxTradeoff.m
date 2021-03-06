models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

load waterGrid.mat;
waterGrid = logical(waterGrid);
      
txxChgOnTxx = [];
wbOnTxx = [];
hussOnTxx = [];
efOnTxx = [];

wbChgOnWb = [];
txxOnWb = [];
hussOnWb = [];
efOnWb = [];

wbChgWarmSeason = [];
txxChgWarmSeason = [];

sEfTxx = [];
pEfTxx = [];
sEfWb = [];
pEfWb = [];

threshChgTw = [];
threshChgTx = [];
threshChgHuss = [];
threshChgTxEf = [];
threshChgTxHuss = [];

for m = 1:length(models)
    
    tind = 1;
    for t = [5:10:95 100]
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-wb-davies-jones-full-' models{m} '-rcp85-2061-2085-each-year.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTw(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-' models{m} '-rcp85-2061-2085-each-year.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTx(:, :, tind, m) = chgData;
        
        if t < 100
            load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-ef-' models{m} '-rcp85-2061-2085-each-year.mat']);
            chgData(waterGrid) = NaN;
            chgData(1:15,:) = NaN;
            chgData(75:90,:) = NaN;
            chgData(chgData > 1 | chgData < 0) = NaN;
            threshChgTxEf(:, :, tind, m) = chgData;
            
            load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-huss-' models{m} '-rcp85-2061-2085-each-year.mat']);
            chgData(waterGrid) = NaN;
            chgData(1:15,:) = NaN;
            chgData(75:90,:) = NaN;
            chgData(chgData > 1 | chgData < 0) = NaN;
            threshChgTxHuss(:, :, tind, m) = chgData;
        end
%         
%         load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-thresh-range-' num2str(t) '-huss-' models{m} '-rcp85-2061-2085-each-year.mat']);
%         chgData(waterGrid) = NaN;
%         chgData(1:15,:) = NaN;
%         chgData(75:90,:) = NaN;
%         threshChgHuss(:, :, tind, m) = chgData;
        
        tind = tind+1;
    end
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txChgWarm-' models{m}]);
    txxChgWarmSeason(:, :, m) = txChgWarm;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txxChg-' models{m}]);
    txxChgOnTxx(:, :, m) = txxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/wbTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    wbOnTxx(:,:,m) = wbTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/hussTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    hussOnTxx(:,:,m) = hussTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/efTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    efOnTxx(:,:,m) = efTxxChg;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\wbChg-' models{m}]);
    wbChgOnWb(:, :, m) = wbChg;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\wbChgWarm-' models{m}]);
    wbChgWarmSeason(:, :, m) = wbChgWarm;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/tasmaxTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    txxOnWb(:,:,m) = tasmaxTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/hussTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    hussOnWb(:,:,m) = hussTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/efTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    efOnWb(:,:,m) = efTxxChg;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txChgWarm-' models{m}]);
    txChgWarmSeason(:, :, m) = txChgWarm;
    
    load(['E:\data\projects\bowen\derived-chg\var-txx-amp\efWarmChg-movingWarm-' models{m}]);
    efChgWarmSeason(:, :, m) = efWarmChg;
    
    load(['E:\data\projects\bowen\derived-chg\var-txx-amp\hussWarmChg-movingWarm-' models{m}]);
    hussChgWarmSeason(:, :, m) = hussWarmChg;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\wbChgWarm-' models{m}]);
    wbChgWarmSeason(:, :, m) = wbChgWarm;
    
    tt = reshape(txxChgOnTxx(:,:,m), [numel(txxChgOnTxx(:,:,m)), 1]);
    wbt = reshape(wbOnTxx(:,:,m), [numel(wbOnTxx(:,:,m)), 1]);
    ht = reshape(hussOnTxx(:,:,m), [numel(hussOnTxx(:,:,m)), 1]);
    et = reshape(efOnTxx(:,:,m), [numel(efOnTxx(:,:,m)), 1]);
    nn = find(isnan(tt) | isnan(wbt) | isnan(ht) | isnan(et) | abs(et) > .4);
    wbt(nn) = [];
    ht(nn) = [];
    et(nn) = [];
    tt(nn) = [];
    
%     wbt = normc(wbt);
%     ht = normc(ht);
%     et = normc(et);
%     tt = normc(tt);
    
    f = fitlm(et, tt, 'poly1');
    sEfTxx(m) = f.Coefficients.Estimate(2);
    pEfTxx(m) = f.Coefficients.pValue(2); 
    
    f = fitlm(et, wbt, 'poly1');
    sEfWb(m) = f.Coefficients.Estimate(2);
    pEfWb(m) = f.Coefficients.pValue(2); 
    
end


tt = reshape(txxChgOnTxx, [numel(txxChgOnTxx), 1]);
wbt = reshape(wbOnTxx, [numel(wbOnTxx), 1]);
ht = reshape(hussOnTxx, [numel(hussOnTxx), 1]);
et = reshape(efOnTxx, [numel(efOnTxx), 1]);
nn = find(isnan(tt) | isnan(wbt) | isnan(ht) | isnan(et) | abs(et) > .4);
wbt(nn) = [];
ht(nn) = [];
et(nn) = [];
tt(nn) = [];

wbwb = reshape(wbChgOnWb, [numel(wbChgOnWb), 1]);
twb = reshape(txxOnWb, [numel(txxOnWb), 1]);
hwb = reshape(hussOnWb, [numel(hussOnWb), 1]);
ewb = reshape(efOnWb, [numel(efOnWb), 1]);
nn = find(isnan(wbwb) | isnan(twb) | isnan(hwb) | isnan(ewb) | abs(ewb) > .4);
twb(nn) = [];
hwb(nn) = [];
ewb(nn) = [];
wbwb(nn) = [];

data = 1000 .* squeeze(nanmean(threshChgTxHuss(:,:,5:10,:),3) - threshChgTxHuss(:,:,5,:));
 plotData = [];
for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        if waterGrid(xlat, ylon)
            plotData(xlat, ylon) = NaN;
            sigChg(xlat, ylon) = 0;
            continue;
        end
        med = nanmedian(data(xlat, ylon, :), 3);
        if ~isnan(med)
            plotData(xlat, ylon) = nanmedian(data(xlat, ylon, :), 3);   
            sigChg(xlat, ylon) = length(find(sign(data(xlat, ylon, :)) == sign(plotData(xlat, ylon)))) < .66*size(data, 3);
        else
            sigChg(xlat, ylon) = 1;
        end
    end
end

sigChg(1:15,:) = 0;
sigChg(75:90,:) = 0;
plotData(1:15,:) = NaN;
plotData(75:90,:) = NaN;

length(find(nanmedian(data,3)>0)) / length(find(~waterGrid & ~isnan(nanmedian(data,3))))*100;
length(find(nanmedian(data,3)<0)) / length(find(~waterGrid & ~isnan(nanmedian(data,3))))*100;

result = {lat, lon, plotData};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-.5 .5], ...
                  'cbXTicks', -.5:.1:.5, ...
                  'plotTitle', [], ...
                  'fileTitle', ['huss-txx-huss-tx50.eps'], ...
                  'plotXUnits', ['Change (g/kg)'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'BrBG'), ...
                  'statData', sigChg);
plotFromDataFile(saveData);