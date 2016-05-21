% load boston data
if ~exist('data', 'var')
    data = bi_readRadiosonde('2016-birds/radiosonde/78016.dat');
end

targetLevels = [100000 85000 70000];
tempData = [];

for i = 1:size(data, 1)
    entry = data(i, :);
    
    % indices in pressure array closest to target levels
    pressureInd = [];
    
    for t = 1:length(targetLevels)
        tmp = abs(entry.data.pressure - targetLevels(t));
        [idx idx] = min(tmp);
        pressureInd(t) = idx;
    end
    
    for t = 1:length(pressureInd)
        tempData(i, t) = entry.data.temp(pressureInd(t)) / 10.0;
    end
    
    if mod(i, 1000) == 0
        ['processed ' num2str(i) ' lines...']
    end
    
end

tempMeans = nanmean(tempData, 1);

