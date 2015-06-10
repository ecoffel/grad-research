function [biasCorrected] = biasCorrect(obsData, modelData, modelDataToCorrect, timeScale, varargin)

anom = {};
biasCorrected = {};

if mod(length(varargin), 2) ~= 0
    ['error: must take an even number of arguments']
    return;
end

for i=1:2:length(varargin)
    switch varargin{i}
        case 'anom'
            anom = varargin{i+1};
    end
end

if length(anom) == 0
    anom = calcMonthlyAnomaly(obsData, modelData);
end

if strcmp(timeScale, 'monthly')
    for m = 1:length(anom)
        biasCorrected{m} = {modelDataToCorrect{m}{1}, modelDataToCorrect{m}{2}, modelDataToCorrect{m}{3}-anom{m}{3}};
    end
elseif strcmp(timeScale, 'daily')
    data = modelDataToCorrect{3};
    
    newData = ones(size(data));
    for m=1:size(data,4)
        for y=1:size(data,3)
            for d=1:size(data,5)
                newData(:,:,y,m,d) = data(:,:,y,m,d)-anom{m}{3};
            end
        end
    end
    biasCorrected = {modelDataToCorrect{1}, modelDataToCorrect{2}, newData};
end

end