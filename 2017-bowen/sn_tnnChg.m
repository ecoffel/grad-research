models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

load waterGrid.mat;
waterGrid = logical(waterGrid);
      
for m = 1:length(models)

    
    load(['E:\data\projects\snow\chgData-cmip5-ann-min-tasmin-' models{m} '-rcp85-2061-2085']);
    tnnChg(:, :, m) = chgData;
    
    load(['E:\data\projects\snow\chgData-cmip5-cold-season-tn-tasmin-' models{m} '-rcp85-2061-2085']);
    tnColdSeason(:, :, m) = chgData;
    
    
end


data = (tnnChg-tnColdSeason);
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

result = {lat, lon, plotData};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-5 5], ...
                  'cbXTicks', -5:1:5, ...
                  'plotTitle', [], ...
                  'fileTitle', ['tnn-warm-season.eps'], ...
                  'plotXUnits', ['Change (' char(176) 'C)'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'*RdBu'), ...
                  'statData', sigChg);
plotFromDataFile(saveData);