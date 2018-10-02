models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

load waterGrid.mat;
waterGrid = logical(waterGrid);

plotDistChg = false;
      
threshChgTw = [];
threshChgTwNoTxAmp = [];

for m = 1:length(models)
    tind = 1;
    for t = 5:10:95
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-tw-count-chg-no-tx-amp-pred-huss-' num2str(t) '-27-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTwNoTxAmp(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-tw-count-chg-' num2str(t) '-27-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTw(:, :, tind, m) = chgData;
        
        
        tind = tind+1;
    end
end

data = squeeze(sum(threshChgTw,3))-squeeze(sum(threshChgTwNoTxAmp,3));

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

length(find(nanmedian(data,3)>0)) / length(find(~waterGrid & ~isnan(nanmedian(data,3))))*100
length(find(nanmedian(data,3)<0)) / length(find(~waterGrid & ~isnan(nanmedian(data,3))))*100

result = {lat, lon, plotData};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-10 10], ...
                  'cbXTicks', -10:2:10, ...
                  'plotTitle', [], ...
                  'fileTitle', ['tw-cnt-27-tx-amp.eps'], ...
                  'plotXUnits', ['# days per warm season'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'*RdBu'), ...
                  'statData', sigChg);
plotFromDataFile(saveData);
