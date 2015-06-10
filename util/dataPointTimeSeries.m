function [data_ret, lat_index, lon_index] = dataPointTimeSeries(dailyData, pt_target)

lat = dailyData{1};
lon = dailyData{2};
data = dailyData{3};

[~,I] = min(abs(lat(:,1)-pt_target(1)));
lat_index = I;

%lon
[~,I] = min(abs(lon(1,:)-pt_target(2)));
lon_index = I;

data_ret = squeeze(data(lat_index, lon_index, :));
    
end