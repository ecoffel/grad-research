load asos-in;

tempPrc = 99.9;
precipPrc = 99.9;

pcnt = 0;
tcnt = 0;

for s = 1:length(asosData)
    temp = asosData{1}{end-2};
    precip = asosData{1}{end};
    
    years = asosData{1}{4};
    months = asosData{1}{5};
    
    growingSeasonInd = find(months>= 4 & months <= 9);
    
    temp = temp(growingSeasonInd);
    precip = precip(growingSeasonInd);
    
    tempThresh = prctile(temp, tempPrc);
    precipThresh = prctile(precip, tempPrc);
    
    tempGroup = [];
    precipGroup = [];
    
    lastYear = years(1);
    lastYearStartInd = 1;
    lastYearEndInd = 1;
    for y = 1:length(years)
        if years(y) ~= lastYear && y <= length(temp) && y <= length(precip)
            lastYear = years(y);
            lastYearEndInd = y;
            
            tempYear = temp(lastYearStartInd:lastYearEndInd);
            precipYear = precip(lastYearStartInd:lastYearEndInd);
            
            if length(find(tempYear > tempThresh)) > 0
                tempGroup(end+1) = years(y);
            elseif length(find(precipYear > precipThresh)) > 0
                precipGroup(end+1) = years(y);
            end
            lastYearStartInd = y;
        end
    end
    
    tcnt = tcnt + length(tempGroup);
    pcnt = pcnt + length(precipGroup);
    
    
end