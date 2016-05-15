
% lags & weights are lists, lag[x] has weight[x] in final sum
function [hi] = mo_laggedTemp(tempSeries, lag)
    
    lags = 0:lag;
    weights = ones(length(lags)) ./ length(lags);

    hi = [];
    for i = max(lags)+1:length(tempSeries)
        val = 0;
        for l = 1:length(lags)
            newVal = tempSeries(i-lags(l));
            if ~isnan(newVal)
                val = val + tempSeries(i-lags(l))*weights(l);
            end
        end
        hi(end+1,1) = val;
    end

end