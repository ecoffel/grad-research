models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

datadir = 'E:\data\projects\bowen\'

load waterGrid.mat;
waterGrid = logical(waterGrid);

plotDistChg = false;
      
twChgPred = [];
twChgFull = [];
twChg = [];
hussChgDueToT = [];
hussChg = [];


for m = 1:length(models)
    
    tind = 1;
    for t = 5:10:95
        load([datadir 'temp-chg-data\chgData-cmip5-thresh-range-' num2str(t) '-tasmax-' models{m} '-rcp85-2061-2085-all-txx.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTx(:, :, tind, m) = chgData;
        
        load([datadir 'temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-huss-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgHuss(:, :, tind, m) = chgData;
        
        load([datadir 'temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        twChg(:, :, tind, m) = chgData;
        
        tind = tind+1;
    end
        
    load([datadir 'temp-chg-data\chgData-huss-med-temp-pred-' models{m} '-rcp85-2061-2085']);
    chgData = hchgDueToMedT;
    chgData(waterGrid) = NaN;
    chgData(1:15,:) = NaN;
    chgData(75:90,:) = NaN;
    hussChgDueToT(:, :, m) = chgData;

    load([datadir 'temp-chg-data\chgData-tw-temp-dist-pred-huss-' models{m} '-rcp85-2061-2085.mat']);
    chgData = twchgMedT_predHuss;
    chgData(waterGrid) = NaN;
    chgData(1:15,:) = NaN;
    chgData(75:90,:) = NaN;
    twChgPred(:, :, :, m) = chgData;

    load([datadir 'temp-chg-data\chgData-tw-temp-dist-full-huss-' models{m} '-rcp85-2061-2085.mat']);
    chgData = twchgMedT_fullHuss;
    chgData(waterGrid) = NaN;
    chgData(1:15,:) = NaN;
    chgData(75:90,:) = NaN;
    twChgFull(:, :, :, m) = chgData;

    load([datadir 'huss-chg-data\chgData-cmip5-warm-season-tx-huss-' models{m} '-rcp85-2061-2085']);
    chgData(waterGrid) = NaN;
    chgData(1:15,:) = NaN;
    chgData(75:90,:) = NaN;
    hussChg(:, :, m) = chgData;

end


txFullChg = squeeze(nanmean(threshChgTx, 3));
txTxNoAmpChg = threshChgTx;
for t = 6:10
    txTxNoAmpChg(:,:,t,:) = txTxNoAmpChg(:,:,5,:);
end

hussFullChg = squeeze(nanmean(threshChgHuss, 3));
hussTxNoAmpChg = threshChgHuss;
for t = 6:10
    hussTxNoAmpChg(:,:,t,:) = hussTxNoAmpChg(:,:,5,:);
end

twFullChg = squeeze(nanmean(twChg, 3));
twNoTxAmpChg = twChg;
for t = 6:10
    twNoTxAmpChg(:,:,t,:) = twNoTxAmpChg(:,:,5,:);
end

%data = (hussFullChg - squeeze(nanmean(hussTxNoAmpChg, 3))) .* 1000;
%data = (twFullChg - squeeze(nanmean(twNoTxAmpChg, 3)));
data = squeeze(nanmean(twFullChg(:,:,5:10,:),3) - twFullChg(:,:,5,:));
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

result = {lat, lon, plotData};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-.5 .5], ...
                  'cbXTicks', -.5:.1:.5, ...
                  'plotTitle', [], ...
                  'fileTitle', ['tx-chg-due-to-tamp-new.eps'], ...
                  'plotXUnits', ['Change (' char(176) 'C)'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'*RdBu'), ...
                  'colorbarArrow', 'both', ...
                  'statData', sigChg);
plotFromDataFile(saveData);



