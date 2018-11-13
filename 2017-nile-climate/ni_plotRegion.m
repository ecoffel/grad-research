figure('Color',[1,1,1]);

set(gcf,'renderer','opengl');

hold on;
axis off;
box on;

[regionInds, regions, regionNames] = ni_getRegions();
regionBounds = regions('nile');
regionBoundsBlue = regions('nile-blue');
regionBoundsWhite = regions('nile-white');
regionBoundsNorth = regions('nile-north');


regions = [[[regionBoundsBlue(1,1) regionBoundsBlue(1,2) regionBoundsBlue(1,2) regionBoundsBlue(1,1)], [regionBoundsBlue(2,1) regionBoundsBlue(2,1) regionBoundsBlue(2,2) regionBoundsBlue(2,2)]]; ...
           [[regionBoundsWhite(1,1) regionBoundsWhite(1,2) regionBoundsWhite(1,2) regionBoundsWhite(1,1)], [regionBoundsWhite(2,1) regionBoundsWhite(2,1) regionBoundsWhite(2,2) regionBoundsWhite(2,2)]]];
           %[[regionBoundsNorth(1,1) regionBoundsNorth(1,2) regionBoundsNorth(1,2) regionBoundsNorth(1,1)], [regionBoundsNorth(2,1) regionBoundsNorth(2,1) regionBoundsNorth(2,2) regionBoundsNorth(2,2)]]];

worldmap('africa');
landmass = shaperead('landareas.shp', 'UseGeoCoords', true);
countries = shaperead('2017-nile-climate/data/shape/countries/ne_50m_admin_0_countries.shp', 'UseGeoCoords', true);
geoshow(landmass, 'FaceColor', 'w', 'EdgeColor', 'k');
rivers = shaperead('2017-nile-climate/data/shape/rivers/world_rivers_dSe.shp', 'UseGeoCoords', true);
geoshow(rivers, 'Color', 'blue')

geoshow(countries, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none');
tightmap;

load coast;
geoshow(flipud(lat),flipud(long), 'DisplayType', 'polygon', 'FaceColor', [166/255.0, 205/255.0, 227/255.0]);

for r = 1:size(regions,1)
    geoshow(regions(r, 1:4), regions(r, 5:8), 'DisplayType', 'polygon', 'FaceColor', [0.7, 0.7, 0.7], 'FaceAlpha', 0.2, 'EdgeColor', 'k', 'LineWidth', 1);
end


set(gcf, 'Position', get(0,'Screensize'));