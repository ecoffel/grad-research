function [yearlyExtremes] = findYearlyExtremes(dailyData, months, isMax)
    
    yearlyExtremes = {};
    
    daily = dailyData{3};
    
%    monthsSize = 1:size(daily, 4);
%    months = intersect(monthsSize, months);
    
    for y = 1:size(daily,3)
        if isMax
            curExt = nanmax(nanmax(daily(:, :, y, months, :), [], 4), [], 5);
        else
            curExt = nanmin(nanmin(daily(:, :, y, months, :), [], 4), [], 5);
        end
        
        yearlyExtremes{y} = {dailyData{1}, dailyData{2}, curExt};
    end
    
end