function [isWater] = isWaterTile(lat, lon, landmass)
    if length(landmass) == 0
        landmass = shaperead('landareas.shp', 'UseGeoCoords', true);
    end
    
    latBounds = [landmass.Lat];
    lonBounds = [landmass.Lon];
    
    if lon > 180
        lon = lon-360;
    end
    
    isWater = ~inpolygon(lat, lon, latBounds, lonBounds);
end

