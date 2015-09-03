landmass = shaperead('landareas.shp', 'UseGeoCoords', true);
load('E:\data\cmip5\output\gfdl-cm3\r1i1p1\historical\tasmax\regrid\19800101-19841231\tasmax_1980_01_01');

lat = tasmax_1980_01_01{1};
lon = tasmax_1980_01_01{2};

gridsize = 2.0;

waterGrid = [];

for xlat = 1:size(lat, 1)
    ['xlat = ' num2str(xlat)]
    for ylon = 1:size(lat, 2)
        waterGrid(xlat, ylon) = isWaterTile(lat(xlat, ylon)+gridsize/2, lon(xlat, ylon)+gridsize/2, landmass);
    end
end

save('waterGrid2.mat', 'waterGrid');