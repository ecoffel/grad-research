function [pts_above] = pointsAbovePercentile(data, data_ref, percentiles)

pts_above = [];
lat = data{1};
lon = data{2};
data = data{3};
data_ref = data_ref{3};

for p=1:length(percentiles)
    
    if length(size(data)) == 3
        perc_data(:,:,p) = prctile(data_ref, percentiles(p), length(size(data_ref)));
        
        % count points above for this percentile
        for d=1:size(data,3)
            if length(pts_above) == 0
                [x_size, y_size, z_size] = size(data);
                pts_above = zeros(x_size, y_size, length(percentiles));
            end
            
            [row, col] = find(data(:,:,d) > perc_data(:,:,p));
            
            for i = 1:length(row)
                pts_above(row(i),col(i),p) = pts_above(row(i),col(i),p)+1;
            end
            
        end
    else
        'error: only handles 3-d data arrays.'
        return
    end
    
end