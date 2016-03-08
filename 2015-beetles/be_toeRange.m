load('toe-ci-5p-ensemble');
ensemble5 = saveData;

load('toe-ci-95p-ensemble');
ensemble95 = saveData;

load('toe-ci-lower-model-range');
lowerRange = saveData;

load('toe-ci-upper-model-range');
upperRange = saveData;

ensembleRangeResults = ensemble95.data{3} - ensemble5.data{3};
mmRangeResults = upperRange.data{3} - lowerRange.data{3};

ensembleRangeResults = ensembleRangeResults(2:end-4,8:end-1);
mmRangeResults = mmRangeResults(2:end-4, 8:end-1);

ratio = {ensemble5.data{1}(2:end-4,8:end-1), ensemble5.data{2}(2:end-4,8:end-1), ensembleRangeResults ./ mmRangeResults};
infind = find(isinf(ratio{3}));
nanind = find(isnan(ratio{3}));
ratio{3}(isinf(ratio{3})) = NaN;
ensembleRangeResults(infind) = NaN;
ensembleRangeResults(nanind) = NaN;
mmRangeResults(infind) = NaN;
mmRangeResults(nanind) = NaN;

plotTitle = ['Ensemble range vs model range ratio'];

saveData = struct('data', {ratio}, ...
                  'plotRegion', 'usne', ...
                  'plotRange', [0 1], ...
                  'plotTitle', plotTitle, ...
                  'fileTitle', 'ens-vs-model-range.pdf', ...
                  'plotXUnits', 'Ratio', ...
                  'blockWater', true, ...
                  'colormap', 'summer');

plotFromDataFile(saveData);

