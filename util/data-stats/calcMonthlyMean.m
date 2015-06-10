function [monthlyMeans] = calcMonthlyMean(monthlyData)

monthlyAgg = [];

for m=1:length(monthlyData)
    for y=1:length(monthlyData{m})
        monthlyAgg(:,:,m,y) = monthlyData{m}{y}{3};
    end
end

monthlyMeans = {};
for m=1:size(monthlyData,2)
    monthlyMeans{m} = {monthlyData{m}{1}{1}, monthlyData{m}{1}{2}, squeeze(nanmean(monthlyAgg(:,:,m,:),4))}; 
end

end