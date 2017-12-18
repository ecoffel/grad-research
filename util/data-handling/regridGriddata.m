% Don't forget...
% The lat/lon grids need to be the same format - usually 0-90 lat, 0-360
% lon

% regridds data1 to be along data2's grid
function [data1_regridded] = regridGriddata(dataOldGrid, dataNewGrid, gridCor, zeroCentered)
    
    data1_lat = dataOldGrid{1};
    data1_lon = dataOldGrid{2};
    data1_data = dataOldGrid{3};
    
    % add in zero column 
    if data1_lon(1,1) == 360
        data1_lon = [data1_lon(:,1) zeros(size(data1_lon,1),1), data1_lon(:,2:end)];
        data1_lat = [data1_lat(:,1) data1_lat(:,1) data1_lat(:,2:end)];
        data1_data = [data1_data(:,1) data1_data(:,1) data1_data(:,2:end)];
    elseif data1_lon(1,1) == 0
        data1_lon = [data1_lon ones(size(data1_lon,1),1) .* 360];
        data1_lat = [data1_lat data1_lat(:,1)];
        data1_data = [data1_data data1_data(:,1)];
    
    % col lon 1 and end are centered around 0 but don't include it... add
    % both a 0 and a 360 col and interpolate the data in between
    elseif zeroCentered
        data1_lon = [data1_lon(:,1) zeros(size(data1_lon,1),1), data1_lon(:,2:end)];
        data1_lat = [data1_lat(:,1) data1_lat(:,1) data1_lat(:,2:end)];
        data1_data = [(data1_data(:,1)+data1_data(:,1))./2 data1_data];
        
        data1_lon = [data1_lon ones(size(data1_lon,1),1) .* 360];
        data1_lat = [data1_lat data1_lat(:,1)];
        data1_data = [data1_data (data1_data(:,1)+data1_data(:,1))./2];
    end
    
    data2_lat = dataNewGrid{1};
    data2_lon = dataNewGrid{2}; 
    
    % extend the original grid so that its lat/lon points always cover the
    % new grid
    
    % lon extension - leftward
    if gridCor
        while data1_lon(1,1) > data2_lon(1,1)
            data1_lon = [data1_lon(:,end)-360, data1_lon(:,:)];
            data1_lat = [data1_lat(:,end), data1_lat(:,:)];
            data1_data = [data1_data(:,end), data1_data(:,:)];
        end

        % lon extension - rightward
        while data1_lon(1,end)+1 < data2_lon(1,end)
            data1_lon(:,end+1) = 360 - data1_lon(:,1);
            data1_lat(:,end+1) = data1_lat(:,end);
            data1_data(:,end+1) = data1_data(:,1);
        end

        % lat extension - downward
        while data1_lat(end,1)+1 < data2_lat(end,1)
            data1_lon(end+1,:) = data1_lon(end,:);
            data1_lat(end+1,:) = 180 + data1_lat(1,:);
            data1_data(end+1,:) = data1_data(1,:);
        end

        % lat extension - upward
        cnt = 1;
        while data1_lat(1,1) > data2_lat(1,1)
            data1_lat = [data1_lat(end-cnt,:)-180; data1_lat(:,:)];
            data1_lon = [data1_lon(end,:); data1_lon(:,:)];
            data1_data = [data1_data(end,:); data1_data(:,:)];
            cnt = cnt+1;
        end
    end
    
    data1_lat_1d = reshape(data1_lat, [1, size(data1_lat,1)*size(data1_lat,2)])';
    data1_lon_1d = reshape(data1_lon, [1, size(data1_lon,1)*size(data1_lon,2)])';
    data1_data_1d = reshape(data1_data, [1, size(data1_lat,1)*size(data1_lat,2)])';
    
    data2_lat_1d = reshape(data2_lat, [1, size(data2_lat,1)*size(data2_lat,2)])';
    data2_lon_1d = reshape(data2_lon, [1, size(data2_lat,1)*size(data2_lat,2)])';

    data1_regridded = griddata(data1_lat_1d, data1_lon_1d, data1_data_1d, data2_lat_1d, data2_lon_1d);
    data1_regridded = reshape(data1_regridded, [size(data2_lat, 1), size(data2_lat, 2)]);
    data1_regridded = {data2_lat, data2_lon, data1_regridded};
end