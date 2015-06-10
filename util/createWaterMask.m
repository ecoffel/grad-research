function [data, mask] = createWaterMask(data, maskData)

    gridSpacing = 0.5;

    latGrid = meshgrid(linspace(-90, 90, 180/gridSpacing), linspace(0, 360, 360/gridSpacing))';
    lonGrid = meshgrid(linspace(0, 360, 360/gridSpacing), linspace(-90, 90, 180/gridSpacing));
    baseGrid = {latGrid, lonGrid, []};

    data = regridGriddata(data, baseGrid);
    
    if length(maskData) == 0
        maskData = loadDailyData('e:/data/ncep-reanalysis/output/soilw', 'yearStart', 1981, 'yearEnd', 1981);
        maskData = regridGriddata({maskData{1}, maskData{2}, maskData{3}(:,:,1,1,1)}, baseGrid);
        lat = maskData{1};
        lon = maskData{2};
    else
        maskData = regridGriddata(maskData, baseGrid);
        lat = maskData{1};
        lon = maskData{2};
        maskData = maskData{3};
    end
    
    maskVal = 6.5;

    lat = maskData{1};
    lon = maskData{2};
    maskData = maskData{3};

    maskData(maskData >= maskVal) = NaN;

    mask = {lat, lon, maskData};
end