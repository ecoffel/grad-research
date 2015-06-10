function [data] = selectDataYear(monthlyData, yearIndex)

data = {};

for m=1:size(monthlyData,1)
    i = 1;
    for y=1:length(yearIndex)
        data{i}{m} = monthlyData{m}{yearIndex(y)};
        i = i+1;
    end
end

end