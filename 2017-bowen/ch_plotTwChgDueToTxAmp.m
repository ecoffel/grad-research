models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

load waterGrid.mat;
waterGrid = logical(waterGrid);

plotDistChg = false;
      
twChgPred = [];
twChgFull = [];
twChg = [];
hussChgDueToT = [];
hussChg = [];

for m = 1:length(models)
    
    load(['E:\data\projects\bowen\huss-chg-data\chgData-cmip5-warm-season-tx-huss-' models{m} '-rcp85-2061-2085']);
    chgData(waterGrid) = NaN;
    chgData(1:15,:) = NaN;
    chgData(75:90,:) = NaN;
    hussChg(:, :, m) = chgData;
    
    load(['E:\data\projects\bowen\temp-chg-data\chgData-huss-med-temp-pred-' models{m} '-rcp85-2061-2085']);
    chgData = hchgDueToMedT;
    chgData(waterGrid) = NaN;
    chgData(1:15,:) = NaN;
    chgData(75:90,:) = NaN;
    hussChgDueToT(:, :, m) = chgData;
    
        load(['E:\data\projects\bowen\temp-chg-data\chgData-tw-med-temp-pred-huss-' models{m} '-rcp85-2061-2085.mat']);
        chgData = twchgMedT_predHuss;
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        twChgPred(:, :, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-tw-med-temp-full-huss-' models{m} '-rcp85-2061-2085.mat']);
        chgData = twchgMedT_fullHuss;
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        twChgFull(:, :, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-warm-season-tx-wb-davies-jones-full-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        twChg(:, :, m) = chgData;
end

data = (hussChg-hussChgDueToT) .* 1000;
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
                  'plotRange', [-1 1], ...
                  'cbXTicks', -1:.25:1, ...
                  'plotTitle', [], ...
                  'fileTitle', ['huss-chg-due-to-tamp.eps'], ...
                  'plotXUnits', ['Change (g/kg)'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'BrBG'), ...
                  'statData', sigChg);
plotFromDataFile(saveData);



