function [sa] = ch_gridcellSA(x, y)
% gridcellSA Find surface area on earth of a particular grid cell
%   x: latitude index (relative to 2x2 regridding)
%   y: longitude index (relative to 2x2 regridding)

    load lat;
    load lon;
    
    y2 = y + 1;
    if y2 > size(lat, 2)
        y2 = y;
    end
    
    x2 = x + 1;
    if x2 > size(lat, 1)
        x2 = x;
    end
    
    
    
    lat1 = lat(x, y);
    lat2 = lat(x2, y2);
    lon1 = lon(x, y);
    lon2 = lon(x2, y2);

    sa = areaquad(lat1, lon1, lat2, lon2) * 4 * pi * 6371^2;

end