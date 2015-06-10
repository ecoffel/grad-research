% Calculates the correction value between model and obs data for each
% percentile bucket. modelData and obsData must be the same length.

function [modelDataCor, meanCor, varCor, rangeCor] = meanVarBiasCorrect(modelData, obsData, dataToCorrect)

% calculate mean correction
modelMean = nanmean(modelData);
obsMean = nanmean(obsData);
meanCor = modelMean - obsMean;

% subtract mean
modelData = modelData - modelMean;
obsData = obsData - obsMean;

% calculate model range correction
rangeCor = (max(obsData) - min(obsData)) / (max(modelData)-min(modelData));
varCor = nanvar(obsData) / nanvar(modelData);

curModelMean = nanmean(dataToCorrect);
modelDataCor = (dataToCorrect - curModelMean) .* rangeCor;
modelDataCor = (modelDataCor + curModelMean - meanCor) ./ varCor;

end