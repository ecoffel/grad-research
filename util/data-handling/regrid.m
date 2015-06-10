% Don't forget...
% The lat/lon grids need to be the same format - usually 0-90 lat, 0-360
% lon

% regridds data1 to be along data2's grid
function [data1_regridded, F] = regrid(dataOldGrid, dataNewGrid)
    
    data1_lat = dataOldGrid{1};
    data1_lon = dataOldGrid{2};
    data1_data = dataOldGrid{3};
    
    data2_lat = dataNewGrid{1};
    data2_lon = dataNewGrid{2};
    data2_x_size = size(dataNewGrid{3},1);
    data2_y_size = size(dataNewGrid{3},2);
    
    data1_lat_1d = [];
    data1_lon_1d = [];
    data1_data_1d = [];
    
    index = 1;
    for row=1:size(data1_lat,1)
        for col = 1:size(data1_lat,2)
            data1_lat_1d(index) = data1_lat(row,col);
            data1_lon_1d(index) = data1_lon(row,col);
            data1_data_1d(index) = data1_data(row,col);
            index = index+1;
        end
    end
    
    data1_lat_1d = data1_lat_1d';
    data1_lon_1d = data1_lon_1d';
    data1_data_1d = data1_data_1d';
    
    F = scatteredInterpolant(data1_lat_1d, data1_lon_1d, data1_data_1d);
    data1_regridded = [];
    
    for x=1:data2_x_size
        for y=1:data2_y_size
            data1_regridded(x,y) = F(data2_lat(x,y), data2_lon(x,y));
        end
    end
    
    data1_regridded = {data2_lat, data2_lon, data1_regridded};
    
end