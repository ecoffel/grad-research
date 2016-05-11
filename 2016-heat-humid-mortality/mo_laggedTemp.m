
% lags & weights are lists, lag[x] has weight[x] in final sum
function [hi] = mo_laggedTemp(tempSeries, lags, weights)
    
    hi = [];
    for i = max(lags)+1:length(tempSeries)
        val = 0;
        for l = 1:length(lags)
            val = val + tempSeries(i-lags(l))*weights(l);
        end
        hi(end+1) = val;
    end

end