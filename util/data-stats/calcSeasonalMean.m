function [seasonalMean] = calcSeasonalMean(monthlyData, season)

months = [];

switch season
    case 'djf'
        months = [12 1 2];
    case 'mam'
        months = [3 4 5];
    case 'jja'
        months = [6 7 8];
    case 'son'
        months = [9 10 11];
end

data = [];
seasonalMean = {};

for y=1:length(monthlyData{1})
    for m = 1:length(months)
        data(:,:,m) = monthlyData{months(m)}{y}{3};
    end
    seasonalMean{y} = {monthlyData{1}{1}{1}, monthlyData{1}{1}{2}, nanmean(data,3)};
end

end