figure('Color',[1,1,1]);

set(gcf,'renderer','opengl');

hold on;
axis off;
box off;

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];


regions = [[[2 13 13 2], [25 25 42 42]]; ...
           [[13 32 32 13], [29 29 34 34]]];

worldmap('africa');
landmass = shaperead('landareas.shp', 'UseGeoCoords', true);
countries = shaperead('countries', 'UseGeoCoords', true);
geoshow(landmass, 'FaceColor', 'w', 'EdgeColor', 'k');

geoshow(countries, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none');
tightmap;

load coast;
geoshow(flipud(lat),flipud(long), 'DisplayType', 'polygon', 'FaceColor', [166/255.0, 205/255.0, 227/255.0]);

for r = 1:size(regions,1)
    geoshow(regions(r, 1:4), regions(r, 5:8), 'DisplayType', 'polygon', 'FaceColor', [0.7, 0.7, 0.7], 'FaceAlpha', 0.2, 'EdgeColor', 'k', 'LineWidth', 1);
end


set(gcf, 'Position', get(0,'Screensize'));