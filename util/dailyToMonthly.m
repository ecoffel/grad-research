function [monthlyData] = dailyToMonthly(daily)
    
    monthlyData = {daily{1}, daily{2}, squeeze(nanmean(daily{3}, 5))};

end