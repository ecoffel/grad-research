targetYear = 2050;
fourColor = false;

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

a = geoshow(pinubank, 'DisplayType', 'polygon', 'FaceColor', [179/255.0, 205/255.0, 227/255.0]);
b = geoshow(pinuresi, 'DisplayType', 'polygon', 'FaceColor', [204/255.0, 235/255.0, 197/255.0]);
c = geoshow(pinurigi, 'DisplayType', 'polygon', 'FaceColor', [251/255.0, 180/255.0, 174/255.0]);
geoshow(states, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none', 'LineWidth', 1);

load('bt-toe-bt-90-perc--11-cmip5-all-ext-2021-2050-cmip5-1985-2004.mat');
X=saveData.data{1};
Y=saveData.data{2};
Z=saveData.data{3};

if ~fourColor    
    [C, h] = contourm(X, Y, Z, 2020:5:2050, 'LineWidth', 2, 'LineColor', 'black');
    labels = clabelm(C, h);
    set(labels, 'FontSize', 22);
else
    selGrid = zeros(size(Z));
    for xlat = 1:size(Z, 1)
        for ylon = 1:size(Z, 2)
            if Z(xlat, ylon) < targetYear
                selGrid(xlat, ylon) = 1;
            end
        end
    end
    
    
end

title('Forest Types', 'FontSize', 24);
%set(gcf, 'Position', get(0,'Screensize'));
l = legend([a b c], 'Jack Pine', 'Red Pine', 'Pitch Pine');
set(l, 'FontSize', 24, 'Location', 'south');

%tightfig;
%export_fig spb-risk-regions.pdf