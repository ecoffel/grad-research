targetYear = 2050;
fourColor = false;
earthSA = 510.1e6;      % km^2


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
    
    contours = {};
    cnt = 1;
    while cnt < size(C, 2)
        key = C(1, cnt);
        num = C(2, cnt);
        contours{end+1} = {key, C(:, cnt+1 : cnt + num)};
        cnt = cnt + num + 1;
    end
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

poly2040Lon = contours{end}{2}(1, :);
poly2040Lon = [poly2040Lon(1) poly2040Lon poly2040Lon(end) poly2040Lon(1)];
poly2040Lat = contours{end}{2}(2, :);
poly2040Lat = [30 poly2040Lat 30 30];

% area calculation
pitchArea = 0;
redArea = 0;
jackArea = 0;
for i = 1:length(pinurigi)
    curLat = pinurigi(i).Lat;
    curLon = pinurigi(i).Lon;
    
    [poly2040Lon, poly2040Lat] = poly2cw(poly2040Lon, poly2040Lat);
    [intx, inty] = polybool('intersection', curLon, curLat, poly2040Lon, poly2040Lat);
    
    if length(intx) > 0
        curArea = areaint(intx, inty);
        for k = 1:length(curArea)
            pitchArea = pitchArea + curArea(k);
        end
    end
end
for i = 1:length(pinubank)
    curLat = pinubank(i).Lat;
    curLon = pinubank(i).Lon;
    
    [poly2040Lon, poly2040Lat] = poly2cw(poly2040Lon, poly2040Lat);
    [intx, inty] = polybool('intersection', curLon, curLat, poly2040Lon, poly2040Lat);
    
    if length(intx) > 0
        curArea = areaint(intx, inty);
        for k = 1:length(curArea)
            jackArea = jackArea + curArea(k);
        end
    end
end
for i = 1:length(pinuresi)
    curLat = pinuresi(i).Lat;
    curLon = pinuresi(i).Lon;
    
    [poly2040Lon, poly2040Lat] = poly2cw(poly2040Lon, poly2040Lat);
    [intx, inty] = polybool('intersection', curLon, curLat, poly2040Lon, poly2040Lat);
    
    if length(intx) > 0
        curArea = areaint(intx, inty);
        for k = 1:length(curArea)
            redArea = redArea + curArea(k);
        end
    end
end

pitchArea = pitchArea * earthSA;
jackArea = jackArea * earthSA;
redArea = redArea * earthSA;
['destroyed jack pine: ' num2str(jackArea) ' km^2']
['destroyed red pine: ' num2str(redArea) ' km^2']
['destroyed pitch pine: ' num2str(pitchArea) ' km^2']

title('Forest Types', 'FontSize', 24);
%set(gcf, 'Position', get(0,'Screensize'));
l = legend([a b c], 'Jack Pine', 'Red Pine', 'Pitch Pine');
set(l, 'FontSize', 24, 'Location', 'south');

%tightfig;
%export_fig spb-risk-regions.pdf