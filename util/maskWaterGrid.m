function [maskedData] = maskWaterGrid(data)
    
    [data, waterMask] = createWaterMask(data, []);
    
    dataLat = data{1};
    dataLon = data{2};
    dataData = data{3};
    
    maskLat = waterMask{1};
    maskLon = waterMask{2};
    maskData = waterMask{3};
    
    for lat = 1:size(dataData, 1)
        for lon = 1:size(dataData, 2)
            
            % find closest gridbox in the mask
            [~,I] = min(abs(maskLat(:,1)-dataLat(lat,1)));
            latIndex = I;

            %lon
            [~,I] = min(abs(maskLon(1,:)-dataLon(1,lon)));
            lonIndex = I;
            
            if isnan(maskData(latIndex, lonIndex))
                dataData(latIndex, lonIndex) = NaN;
            end
            
        end
    end
    
    maskedData = {dataLat, dataLon, dataData};

end