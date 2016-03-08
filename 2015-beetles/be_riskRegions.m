targetYear = 2080;
fourColor = false;
earthSA = 510.1e6;      % km^2

computeAreas = true;

pinubank = shaperead('2015-beetles/data/pinubank/pinubank.shp', 'UseGeoCoords', true);
pinuresi = shaperead('2015-beetles/data/pinuresi/pinuresi.shp', 'UseGeoCoords', true);
pinurigi = shaperead('2015-beetles/data/pinurigi/pinurigi.shp', 'UseGeoCoords', true);

states = shaperead('usastatelo', 'UseGeoCoords', true, 'Selector', ...
             {@(name) ~any(strcmp(name,{'Alaska','Hawaii'})), 'Name'});
         
canadaShp = shaperead('2015-beetles/data/canada/Canada.shp', 'UseGeoCoords', true);
f = fieldnames(canadaShp);
v = struct2cell(canadaShp);
f{strmatch('NAME',f,'exact')} = 'Name';
canadaShp = cell2struct(v,f);
clear f v;

statesAndCanada = {canadaShp, states};
         
fg = figure;
hold on;
set(fg, 'Color', [1,1,1]);
axis off;
axesm('mercator','MapLatLimit',[36 50],'MapLonLimit',[-90 -60]);
framem off; gridm off; mlabel off; plabel off;

a = geoshow(pinubank, 'DisplayType', 'polygon', 'FaceColor', [179/255.0, 205/255.0, 227/255.0]);
b = geoshow(pinuresi, 'DisplayType', 'polygon', 'FaceColor', [204/255.0, 235/255.0, 197/255.0]);
c = geoshow(pinurigi, 'DisplayType', 'polygon', 'FaceColor', [251/255.0, 180/255.0, 174/255.0]);
geoshow(states, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none', 'LineWidth', 1);

load('bt-output\bt-toe-bc-mean-r1i1p1-mm-bt-100-perc--10-cmip5-all-ext-2006-2090-cmip5-1985-2004');
X=saveData.data{1};
Y=saveData.data{2};
Z=saveData.data{3};

set(gcf, 'Position', get(0,'Screensize'));

if ~fourColor    
    [C, h] = contourm(X, Y, Z, [2020 2050 2080], 'LineWidth', 2, 'LineColor', 'black');
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

poly2040Lon = contours{2}{2}(1, :);
poly2040Lon = [-50 poly2040Lon -100 -50];
poly2040Lat = contours{2}{2}(2, :);
poly2040Lat = [39 poly2040Lat 39 39];

if computeAreas
    % area calculation
    pitchArea = 0;
    redArea = 0;
    jackArea = 0;

    pitchStateArea = {};
    redStateArea = {};
    jackStateArea = {};

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

            for d = 1:length(statesAndCanada)
                for s = 1:length(statesAndCanada{d})
                    state = statesAndCanada{d}(s);
                    [stateintx, stateinty] = polybool('intersection', intx, inty, state.Lon, state.Lat);
                    if length(stateintx) > 0
                        stateArea = areaint(stateintx, stateinty);
                        curStateArea = 0;
                        for k = 1:length(stateArea)
                            curStateArea = curStateArea + stateArea(k);
                        end

                        stateInd = find(cellfun(@(S) strcmp(state.Name, S{1}), pitchStateArea));

                        if length(stateInd) == 0
                            pitchStateArea{end+1} = {state.Name, curStateArea*earthSA};
                        else
                            pitchStateArea{stateInd}{2} = pitchStateArea{stateInd}{2} + curStateArea*earthSA;
                        end
                    end
                end
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

            for d = 1:length(statesAndCanada)
                for s = 1:length(statesAndCanada{d})
                    state = statesAndCanada{d}(s);
                    [stateintx, stateinty] = polybool('intersection', intx, inty, state.Lon, state.Lat);
                    if length(stateintx) > 0
                        stateArea = areaint(stateintx, stateinty);
                        curStateArea = 0;
                        for k = 1:length(stateArea)
                            curStateArea = curStateArea + stateArea(k);
                        end

                        stateInd = find(cellfun(@(S) strcmp(state.Name, S{1}), jackStateArea));

                        if length(stateInd) == 0
                            jackStateArea{end+1} = {state.Name, curStateArea*earthSA};
                        else
                            jackStateArea{stateInd}{2} = jackStateArea{stateInd}{2} + curStateArea*earthSA;
                        end
                    end
                end
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

            for d = 1:length(statesAndCanada)
                for s = 1:length(statesAndCanada{d})
                    state = statesAndCanada{d}(s);
                    [stateintx, stateinty] = polybool('intersection', intx, inty, state.Lon, state.Lat);
                    if length(stateintx) > 0
                        stateArea = areaint(stateintx, stateinty);
                        curStateArea = 0;
                        for k = 1:length(stateArea)
                            curStateArea = curStateArea + stateArea(k);
                        end

                        stateInd = find(cellfun(@(S) strcmp(state.Name, S{1}), redStateArea));

                        if length(stateInd) == 0
                            redStateArea{end+1} = {state.Name, curStateArea*earthSA};
                        else
                            redStateArea{stateInd}{2} = redStateArea{stateInd}{2} + curStateArea*earthSA;
                        end
                    end
                end
            end
        end
    end

    pitchArea = pitchArea * earthSA;
    jackArea = jackArea * earthSA;
    redArea = redArea * earthSA;
    ['destroyed jack pine: ' num2str(jackArea) ' km^2']
    ['destroyed red pine: ' num2str(redArea) ' km^2']
    ['destroyed pitch pine: ' num2str(pitchArea) ' km^2']
end

title('Forest Types', 'FontSize', 24);
l = legend([a b c], 'Jack Pine', 'Red Pine', 'Pitch Pine');
set(l, 'FontSize', 24, 'Location', 'south');

%tightfig;
%export_fig spb-risk-regions.pdf