city = 'ny';

eval(['load ' city 'MortData.mat;']);       % loads into mortData
eval(['load ' city 'Wx.mat;']);             % loads into wxTable

% add wb headers to the mortData headers list
wbMinInd = length(mortData{1}) + 1;
wbMaxInd = length(mortData{1}) + 2;
wbMeanInd = length(mortData{1}) + 3;

mortData{1}{wbMinInd} = 'wbmin';
mortData{1}{wbMaxInd} = 'wbmax';
mortData{1}{wbMeanInd} = 'wbmean';

tempMinInd = length(mortData{1}) + 1;
tempMaxInd = length(mortData{1}) + 2;
tempMeanInd = length(mortData{1}) + 3;

mortData{1}{tempMinInd} = 'ishTempMin';
mortData{1}{tempMaxInd} = 'ishTempMax';
mortData{1}{tempMeanInd} = 'ishTempMean';

% lines in mort data file
for i = 1:size(mortData{2}, 1)
    curWxInd = 1;
    
    % current day in mort
    mortYear = mortData{2}(i, 1);
    mortMonth = mortData{2}(i, 2);
    mortDay = mortData{2}(i, 3);
    
    % find matching day's hourly data in wxTable
    wxYears = wxTable.year;
    wxMonths = wxTable.month;
    wxDays = wxTable.day;
    wxHours = wxTable.hour;
    
    % search for correct year
    while wxYears(curWxInd) < mortYear
        curWxInd = curWxInd + 1;
    end
    
    % now month
    while wxMonths(curWxInd) < mortMonth
        curWxInd = curWxInd + 1;
    end
    
    % and day...
    while wxDays(curWxInd) < mortDay
        curWxInd = curWxInd + 1;
    end
    
    wbMin = wxTable.wb(curWxInd);
    wbMax = wxTable.wb(curWxInd);
    wbMean = wxTable.wb(curWxInd);
    
    tempMin = wxTable.temp(curWxInd);
    tempMax = wxTable.temp(curWxInd);
    tempMean = wxTable.temp(curWxInd);
    
    startingWbInd = curWxInd;
    curWxInd = curWxInd + 1;
    
    % now loop over the day and find the min, mean, and max wb temperature
    while curWxInd <= length(wxHours) && wxHours(curWxInd) > 0 && wxHours(curWxInd) <= 23
        if wxTable.wb(curWxInd) < wbMin
            wbMin = wxTable.wb(curWxInd);
        end
        
        if wxTable.wb(curWxInd) > wbMax
            wbMax = wxTable.wb(curWxInd);
        end
        
        wbMean = wbMean + wxTable.wb(curWxInd);
        
        if wxTable.temp(curWxInd) < tempMin
            tempMin = wxTable.temp(curWxInd);
        end
        
        if wxTable.temp(curWxInd) > tempMax
            tempMax = wxTable.temp(curWxInd);
        end
        
        tempMean = tempMean + wxTable.temp(curWxInd);
        
        curWxInd = curWxInd + 1;
    end
    
    % so this generates a lot of NaNs, presumably because there are NaNs in
    % the hourly data which get carried through in the sum - maybe check
    % out whether using nanmean on the range would be better, or if this
    % would generate unreliable means of a small number of non-nan readings
    % for a day
    wbMean = wbMean / (curWxInd-startingWbInd);
    tempMean = tempMean / (curWxInd-startingWbInd);
    
    % add wb stats to the mortData matrix
    mortData{2}(i, wbMinInd) = wbMin;
    mortData{2}(i, wbMaxInd) = wbMax;
    mortData{2}(i, wbMeanInd) = wbMean;
    
    mortData{2}(i, tempMinInd) = tempMin;
    mortData{2}(i, tempMaxInd) = tempMax;
    mortData{2}(i, tempMeanInd) = tempMean;
    
end

save([city 'MergedMortData.mat'], 'mortData');