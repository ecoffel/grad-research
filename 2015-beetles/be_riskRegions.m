targetYear = 2080;
earthSA = 510.1e6;      % km^2

computeAreas = true;
computeStateAreas = false;
plotMap = false;

pinubank = shaperead('2015-beetles/data/pinubank/pinubank.shp', 'UseGeoCoords', true);
pinuresi = shaperead('2015-beetles/data/pinuresi/pinuresi.shp', 'UseGeoCoords', true);
pinurigi = shaperead('2015-beetles/data/pinurigi/pinurigi.shp', 'UseGeoCoords', true);

if computeAreas
    totalPitchArea = 0;
    totalJackArea = 0;
    totalRedArea = 0;

    for i = 1:length(pinurigi)
        [polyLon, polyLat] = poly2cw(pinurigi(i).Lon, pinurigi(i).Lat);
        areas = areaint(polyLon, polyLat);
        for a = 1:length(areas)
            totalPitchArea = totalPitchArea + areas(a) * earthSA;
        end
    end

    for i = 1:length(pinubank)
        [polyLon, polyLat] = poly2cw(pinubank(i).Lon, pinubank(i).Lat);
        areas = areaint(polyLon, polyLat);
        for a = 1:length(areas)
            totalJackArea = totalJackArea + areas(a)*earthSA;
        end
    end

    for i = 1:length(pinuresi)
        [polyLon, polyLat] = poly2cw(pinuresi(i).Lon, pinuresi(i).Lat);
        areas = areaint(polyLon, polyLat);
        for a = 1:length(areas)
            totalRedArea = totalRedArea + areas(a) * earthSA;
        end
    end
end

states = shaperead('usastatelo', 'UseGeoCoords', true, 'Selector', ...
             {@(name) ~any(strcmp(name,{'Alaska','Hawaii'})), 'Name'});
         
canadaShp = shaperead('2015-beetles/data/canada/Canada.shp', 'UseGeoCoords', true);
f = fieldnames(canadaShp);
v = struct2cell(canadaShp);
f{strmatch('NAME',f,'exact')} = 'Name';
canadaShp = cell2struct(v,f);
clear f v;

statesAndCanada = {canadaShp, states};
         
if plotMap
    fg = figure;
    hold on;
    set(fg, 'Color', [1,1,1]);
    axis off;
    axesm('mercator','MapLatLimit',[36 50],'MapLonLimit',[-90 -60]);
    framem off; gridm off; mlabel off; plabel off;

    g1 = geoshow(pinubank, 'DisplayType', 'polygon', 'FaceColor', [179/255.0, 205/255.0, 227/255.0]);
    g2 = geoshow(pinuresi, 'DisplayType', 'polygon', 'FaceColor', [204/255.0, 235/255.0, 197/255.0]);
    g3 = geoshow(pinurigi, 'DisplayType', 'polygon', 'FaceColor', [251/255.0, 180/255.0, 174/255.0]);
    geoshow(states, 'DisplayType', 'polygon', 'DefaultFaceColor', 'none', 'LineWidth', 1);
end

load('bt-output/bt-toe-bc-mean-r1i1p1-mm-rcp85-bt-100-perc--10-cmip5-all-ext-2006-2090-cmip5-1985-2004');
X=saveData.data{1};
Y=saveData.data{2};
Z=saveData.data{3};

[C, h] = contourm(X, Y, Z, [2020 2050 2080], 'LineWidth', 2, 'LineColor', 'black');

if plotMap
    set(gcf, 'Position', get(0,'Screensize'));
    labels = clabelm(C, h);
    set(labels, 'FontSize', 22);
end

contours = {};
cnt = 1;
while cnt < size(C, 2)
    key = C(1, cnt);
    num = C(2, cnt);
    contours{end+1} = {key, C(:, cnt+1 : cnt + num)};
    cnt = cnt + num + 1;
end

polyLon = {};
polyLat = {};

for c = 1:length(contours)
    if contours{c}{1} == targetYear
%         polyLon{end+1} = [-50 contours{c}{2}(1, :) -100 -50];
%         polyLat{end+1} = [39 contours{c}{2}(2, :) 39 39];
        %polyLon{end+1} = [contours{c}{2}(1, 1), contours{c}{2}(1, :), contours{c}{2}(1, end), contours{c}{2}(1, 1)];
        %polyLat{end+1} = [30,                   contours{c}{2}(2, :), 30,                     30];
        
        % if we have a closed contour, then just include it directly
        if contours{c}{2}(1,1) == contours{c}{2}(1,end) %&& ...
           %contours{c}{2}(2,1) == contours{c}{2}(2,end)
            polyLon{end+1} = contours{c}{2}(1, :);
            polyLat{end+1} = contours{c}{2}(2, :);
        % if the contour is not closed and it is long enough, close it by
        % specifying lat/lon points well outside the shapefile region
        else
            if length(contours{c}{2}(1, :)) > 20
                polyLon{end+1} = [-120, contours{c}{2}(1, :), -50, -50, -120];
                polyLat{end+1} = [20,   contours{c}{2}(2, :),  60,  20,  20];
            end
        end
    end
end

if computeAreas
    % area calculation
    pitchArea = 0;
    redArea = 0;
    jackArea = 0;

    pitchStateArea = {};
    redStateArea = {};
    jackStateArea = {};

    for i = 1:length(pinurigi)
        curShapeLat = pinurigi(i).Lat;
        curShapeLon = pinurigi(i).Lon;
        
        for c = 1:length(polyLon)
            curConLat = polyLat{c};
            curConLon = polyLon{c};
            
            [curConLon, curConLat] = poly2cw(curConLon, curConLat);
            [intx, inty] = polybool('intersection', curShapeLon, curShapeLat, curConLon, curConLat);

            if length(intx) > 0
                curArea = areaint(intx, inty);
                for k = 1:length(curArea)
                    pitchArea = pitchArea + curArea(k);
                end

                if computeStateAreas
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
        end
    end

    for i = 1:length(pinubank)
        curShapeLat = pinubank(i).Lat;
        curShapeLon = pinubank(i).Lon;
        
        for c = 1:length(polyLon)
            curConLat = polyLat{c};
            curConLon = polyLon{c};
            
            [curConLon, curConLat] = poly2cw(curConLon, curConLat);
            
            [intx, inty] = polybool('intersection', curShapeLon, curShapeLat, curConLon, curConLat);

            if length(intx) > 0
                curArea = areaint(intx, inty);
                for k = 1:length(curArea)
                    jackArea = jackArea + curArea(k);
                end

                if computeStateAreas
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
        end
    end

    for i = 1:length(pinuresi)
        curShapeLat = pinuresi(i).Lat;
        curShapeLon = pinuresi(i).Lon;

        for c = 1:length(polyLon)
            curConLat = polyLat{c};
            curConLon = polyLon{c};
            
            [curConLon, curConLat] = poly2cw(curConLon, curConLat);
            [intx, inty] = polybool('intersection', curShapeLon, curShapeLat, curConLon, curConLat);
            
            if length(intx) > 0
                curArea = areaint(intx, inty);
                for k = 1:length(curArea)
                    redArea = redArea + curArea(k);
                end

                if computeStateAreas
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
        end
    end

    % in 2080 we have 2 large closed contours, so the destroyed area is
    % just the total area minus the intersection area
    if targetYear == 2080
        pitchArea = totalPitchArea - pitchArea * earthSA;
        redArea = totalRedArea - redArea * earthSA;
        jackArea = totalJackArea - jackArea * earthSA;
    else
        pitchArea = pitchArea * earthSA;
        jackArea = jackArea * earthSA;
        redArea = redArea * earthSA;
    end
    
    ['destroyed jack pine by ' num2str(targetYear) ': ' num2str(jackArea) ' km^2']
    ['destroyed red pine by ' num2str(targetYear) ': ' num2str(redArea) ' km^2']
    ['destroyed pitch pine by ' num2str(targetYear) ': ' num2str(pitchArea) ' km^2']
end

if plotMap
    title('Forest Types', 'FontSize', 24);
    l = legend([g1 g2 g3], 'Jack Pine', 'Red Pine', 'Pitch Pine');
    set(l, 'FontSize', 24, 'Location', 'south');
end

%tightfig;
%export_fig spb-risk-regions.pdf