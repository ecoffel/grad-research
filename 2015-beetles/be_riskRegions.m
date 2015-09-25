pinubank = shaperead('2015-beetles/data/pinubank/pinubank.shp', 'UseGeoCoords', true);
pinuresi = shaperead('2015-beetles/data/pinuresi/pinuresi.shp', 'UseGeoCoords', true);
pinurigi = shaperead('2015-beetles/data/pinurigi/pinurigi.shp', 'UseGeoCoords', true);

states = shaperead('usastatelo', 'UseGeoCoords', true, 'Selector', ...
             {@(name) ~any(strcmp(name,{'Alaska','Hawaii'})), 'Name'});
         
         
fg = figure;
hold on;
set(fg, 'Color', [1,1,1]);
axis off;
axesm('mercator','MapLatLimit',[35 50],'MapLonLimit',[-100 -60]);
framem off; gridm off; mlabel off; plabel off;

a = geoshow(pinubank, 'DisplayType', 'polygon', 'FaceColor', 'b');
b = geoshow(pinuresi, 'DisplayType', 'polygon', 'FaceColor', 'g');
c = geoshow(pinurigi, 'DisplayType', 'polygon', 'FaceColor', 'r');
geoshow(states, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none', 'LineWidth', 2);

title('Forest Types', 'FontSize', 24);
set(gcf, 'Position', get(0,'Screensize'));
l = legend([a b c], 'Jack Pine', 'Red Pine', 'Pitch Pine');
set(l, 'FontSize', 24, 'Location', 'south');

tightfig;
export_fig spb-risk-regions.pdf