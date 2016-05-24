% read station list
f = fopen('2016-birds/radiosonde/stations.txt');
stationCodes = [];
stationNames = {};
line = fgets(f);
while line ~= -1
    parts = strsplit(line, ',');
    stationCodes(end+1) = str2num(parts{1});
    stationNames{end+1} = parts{2};
    
    line = fgets(f);
end

rawData = {};
tempData = {};
pressureData = {};
realLevels = {};

for c = 1:length(stationCodes)
    % load data for current city
    data = bi_readRadiosonde(['2016-birds/radiosonde/' num2str(stationCodes(c)) '.dat']);
    
    % look for 1000, 850, 700 mb
    targetLevels = [100000 85000 70000];
    
    first = data(1,:);
    realLevels{c} = [];
    curTempMonthlyCnt = [];
    tempData{c} = {};
    curTempData = {};
    
    % create a list for each month
    for i = 1:12
        curTempData{i} = [];
        curTempMonthlyCnt(i) = 1;
    end
    
    for i = 1:size(data, 1)
        entry = data(i, :);

        curMonth = entry.month;
        
        % indices in pressure array closest to target levels
        pressureInd = [];
        
        if length(entry.data.pressure) == 0
            continue;
        end
        
        for t = 1:length(targetLevels)
            tmp = abs(entry.data.pressure - targetLevels(t));
            [idx idx] = min(tmp);
            pressureInd(t) = idx;
        end
        
        % stations with no surface pressure
        if ismember(stationCodes(c), [32540, 72469])
            pressureInd(1) = -1;
        end
        
        % temp data units deg C * 10
        for t = 1:length(pressureInd)
            
            % something wrong with this pressure leve, set NaN
            if pressureInd(t) == -1
                realLevels{c}(t) = NaN;
                curTempData{curMonth}(curTempMonthlyCnt(curMonth), t) = NaN;
            else
                if length(realLevels{c}) < length(pressureInd)
                    realLevels{c}(t) = entry.data.pressure(pressureInd(t));
                end

                if entry.data.temp(pressureInd(t)) / 10.0 > - 100
                    curTempData{curMonth}(curTempMonthlyCnt(curMonth), t) = entry.data.temp(pressureInd(t)) / 10.0;
                end
            end
        end
        
        curTempMonthlyCnt(curMonth) = curTempMonthlyCnt(curMonth) + 1;
        
        if mod(i, 1000) == 0
            ['processed ' num2str(i) ' lines...']
        end

    end

    tempMeans = {};
    for m = 1:length(curTempData)
        tempMeans{m} = nanmean(curTempData{m}, 1);
        if length(tempMeans{m}) ~= 3
            tempMeans{m} = [NaN NaN NaN];
        end
        tempData{c}{m} = {strtrim(stationNames{c}), tempMeans{m}};
    end
    
	
end

fout = fopen('tempData.txt','w');
for i = 1:size(tempData, 2)
    for m = 1:length(tempData{i})
        while length(realLevels{i}) < 3
            realLevels{i}(end+1) = -1;
        end

        fprintf(fout, '%s,%d,%d,%d,%d,%f,%f,%f\r\n', strtrim(tempData{i}{m}{1}), m, ...
                                                     round(realLevels{i}(1)), round(realLevels{i}(2)), round(realLevels{i}(3)), ...
                                                     tempData{i}{m}{2}(1), tempData{i}{m}{2}(2), tempData{i}{m}{2}(3));
    end
end
fclose(fout);
