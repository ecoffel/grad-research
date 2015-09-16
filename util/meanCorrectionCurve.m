% Calculates the correction value between model and obs data for eachw
% percentile bucket. modelData and obsData must be the same length.

function [percentileCorrections, percentileBuckets, modelPercentileTemps, obsPercentileTemps] = meanCorrectionCurve(modelData, obsData, percentileBucketSize)

% size of each percentile bucket for a correction calculation
percentileCorrections = [];
percentileBuckets = 0:percentileBucketSize:100;
percentileTemps = [];

for p = 1:length(percentileBuckets)-1
    p1 = percentileBuckets(p);
    p2 = percentileBuckets(p+1);
    
    p1TempModel = prctile(modelData, p1);
    p2TempModel = prctile(modelData, p2);
    
    p1TempObs = prctile(obsData, p1);
    p2TempObs = prctile(obsData, p2);
    
    modelTemps = find(modelData >= p1TempModel & modelData <= p2TempModel);
    obsTemps = find(obsData >= p1TempObs & obsData <= p2TempObs);
    
    modelPercentileTemps(p) = p2TempModel;
    obsPercentileTemps(p) = p2TempObs;
    
    percentileCorrections(p) = nanmean(modelData(modelTemps)) - nanmean(obsData(obsTemps));
end
