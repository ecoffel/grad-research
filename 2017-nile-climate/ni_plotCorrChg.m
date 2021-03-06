[regionInds, regions, regionNames] = ni_getRegions();
curInds = regionInds('nile');
latInds = curInds{1};
lonInds = curInds{2};

load lat;
load lon;

seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};

for s = 1:4
    
    load(['temp-pr-corr-cmip5-' seasonNames{s}]);
    corrHist = saveData.data{3};
    load(['temp-pr-corr-cmip5-rcp85-' seasonNames{s}]);
    corrFut = saveData.data{3};
    
    result = {lat(latInds,lonInds), lon(latInds,lonInds), corrFut-corrHist}; 

    saveData = struct('data', {result}, ...
                      'plotRegion', 'nile', ...
                      'plotRange', [-.5 .5], ...
                      'cbXTicks', -.5:.25:.5, ...
                      'plotTitle', [''], ...
                      'fileTitle', ['temp-pr-corr-cmip5-chg-' seasonNames{s} '.eps'], ...
                      'plotXUnits', ['Correlation change'], ...
                      'blockWater', true, ...
                      'colormap', brewermap([], 'RdBu'), ...
                      'plotCountries', true, ...
                      'boxCoords', {[[13 32], [29, 34];
                                     [2 13], [25 42]]});
    plotFromDataFile(saveData);
end