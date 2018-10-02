
function [fg, cb] = plotFromDataFile(saveData)

    boxCoordsExists = false;
    if isfield(saveData, 'boxCoords')
        boxCoordsExists = true;
    end
    
    statDataExists = false;
    if isfield(saveData, 'statData')
        statDataExists = true;
    end
    
    stippleInterval = 10;
    if isfield(saveData, 'stippleInterval')
        stippleInterval = saveData.stippleInterval;
    end
    
    if isfield(saveData, 'colormap')
        colorMap = saveData.colormap;
    else
        colorMap = [];
    end
    
    if isfield(saveData, 'showColorbar')
        showColorbar = saveData.showColorbar;
    else
        showColorbar = true;
    end
    
    if isfield(saveData, 'vectorData')
        vectorData = saveData.vectorData;
    else
        vectorData = [];
    end
    
    if isfield(saveData, 'plotCountries')
        plotCountries = saveData.plotCountries;
    else
        plotCountries = false;
    end
    
    if isfield(saveData, 'plotStates')
        plotStates = saveData.plotStates;
    else
        plotStates = false;
    end
    
    if isfield(saveData, 'blockLand')
        blockLand = saveData.blockLand;
    else
        blockLand = false;
    end
    
    if isfield(saveData, 'blockWater')
        blockWater = saveData.blockWater;
    else
        blockWater = false;
    end
    
    if isfield(saveData, 'magnify')
        magnify = saveData.magnify;
    else
        magnify = false;
    end
    
    if isfield(saveData, 'vector')
        vector = true;
    else
        vector = false;
    end
    
    if isfield(saveData, 'cbXTicks')
        xticks = saveData.cbXTicks;
    else
        xticks = false;
    end
    
    if isfield(saveData, 'skipStatSignTransition')
        skipStatSignTransition = true;
    else
        skipStatSignTransition = false;
    end
    
    % add an extra col on to draw the last tile
    saveData.data{2}(:,end+1)=saveData.data{2}(:,end)+(saveData.data{2}(:,end)-saveData.data{2}(:,end-1));
    saveData.data{1}(:,end+1)=saveData.data{1}(:,end)+(saveData.data{1}(:,end)-saveData.data{1}(:,end-1));
    saveData.data{3}(:,end+1)=saveData.data{3}(:,end);
    
    [fg,cb] = plotModelData(saveData.data, saveData.plotRegion, 'caxis', saveData.plotRange, 'colormap', colorMap, 'vectorData', vectorData, 'countries', plotCountries, 'states', plotStates, 'showColorbar', showColorbar);
    
    %set(gca, 'DrawMode', 'childorder');
    %set(gca, 'SortMethod', 'childorder');
    
    set(gca, 'Color', 'none');
    set(gca, 'FontSize', 36);
    if showColorbar
        xlabel(cb, saveData.plotXUnits, 'FontSize', 36);
        set(cb, 'XTick', xticks);
        cbPos = get(cb, 'Position');
    end
    if length(saveData.plotTitle) > 0
        title(saveData.plotTitle, 'FontSize', 36);
    end
    
    set(gcf, 'Position', get(0,'Screensize'));
    ti = get(gca,'TightInset');
    if showColorbar
        set(gca,'Position', [ti(1) cbPos(2) 1-ti(3)-ti(1) 1-ti(4)-cbPos(2)-cbPos(4)]);
    end
	tightmap;
    
    if statDataExists
        statData = saveData.statData;
        
        lat=saveData.data{1};
        lon=saveData.data{2};
        
        % expand to include the 360/0 lon line
        %statData(:, end+1) = statData(:, 1);
        %statData(:, 1) = 0;
        %lat(:, end+1) = lat(:, 1);
        %lon(:, end+1) = lon(:, 1);
        
        [xCoords, yCoords] = mfwdtran(lat,lon);
       
        % neet to rotate these so the crossover from x > 0 to x < 0 occurs
        % at the first/last elements
%         crossInd = find(diff(sign(xCoords(1,:))))+1;
%         xCoords = circshift(xCoords,-(crossInd-1),2);
%         yCoords = circshift(yCoords,-(crossInd-1),2);
%         statData = circshift(statData,-(crossInd-1),2);

            % ORIGINAL - not sure where the 15 came from
        %xCoords = circshift(xCoords,-15,2);
        %yCoords = circshift(yCoords,-15,2);
        %statData = circshift(statData,-15,2);
%         xCoords(end+1, :) = xCoords(1, :);
%         xCoords(:, end+1) = xCoords(:, 1);
%         yCoords(:, end+1) = yCoords(:, 1);
%         yCoords(end+1, :) = yCoords(1, :);

        % new, adding new col onto data and lat/lon
        %xCoords(end+1, :) = xCoords(end, :);
        xCoords(:, end+1) = xCoords(:, end) + (xCoords(:, end)-xCoords(:, end-1));
        xCoords(end+1, :) = xCoords(end, :);
        yCoords(end+1, :) = yCoords(end, :);
        yCoords(:, end+1) = yCoords(:, end) - (yCoords(:, end) - yCoords(:, end-1));
        
        % keep track of coords on map as well as in smaller statdata
        mapx = 1;
        for statx = 1:size(statData, 1)
            mapy = 1;
            for staty = 1:size(statData, 2)
                
                if statData(statx, staty)
                    
                    if skipStatSignTransition
                        % at the transition from pos to deg there is a repeated
                        % column. skip it to prevent hatches crossing the whole
                        % screen
                        if xCoords(mapx, mapy) ~= 0 && (sign(xCoords(mapx, mapy)) ~= sign(xCoords(mapx, mapy+1)))
                            mapy = mapy+1;
                        end
                    end
                    
                    tulX = xCoords(mapx, mapy);
                    tulY = yCoords(mapx, mapy);
                    
                    turX = xCoords(mapx+1, mapy);
                    turY = yCoords(mapx+1, mapy);
                    
                    tblX = xCoords(mapx, mapy+1);
                    tblY = yCoords(mapx, mapy+1);
                    
                    tbrX = xCoords(mapx+1, mapy+1);
                    tbrY = yCoords(mapx+1, mapy+1);
                    
                    p = patch([tulX turX tbrX tblX], [tulY turY tbrY tblY], 'k');
                    set(p, 'FaceColor', 'none', 'EdgeColor', 'none');
                    h = hatchfill2(p, 'single', 'HatchAngle', 45, 'HatchColor', 'k', 'HatchSpacing', stippleInterval, 'HatchLineWidth', 1.5);
                    
                    
                    
                    %h = hatchfill(p, 'single', 45, stippleInterval);
                    %uistack(h, 'bottom');
                    
%                     for j = linspace(startingLat, endingLat, abs(endingLat-startingLat)/saveData.stippleInterval)
%                         for k = linspace(startingLon, endingLon, abs(endingLon-startingLon)/saveData.stippleInterval)
%                             p1 = plotm(j, k, 'Marker', 'o',...
%                                         'MarkerEdgeColor', 'k',...
%                                         'MarkerFaceColor', 'k',...
%                                         'MarkerSize', 2);
%                             uistack(p1, 'down');
%                         end
%                     end
                end
                mapy = mapy+1;
            end
            mapx = mapx+1;
        end
    end
    
    if saveData.blockWater
        load coast;
        geoshow(flipud(lat),flipud(long),'DisplayType','Polygon','FaceColor','white','EdgeColor','none');
        geoshow(flipud(lat),flipud(long),'DisplayType','Line','Color','black','LineWidth',2);
        %uistack(g, 'top');
    end
    
    if blockLand
        geoshow('landareas.shp','DisplayType','polygon','FaceColor','white','EdgeColor','None');
    end
       
    if boxCoordsExists
        boxCoords = saveData.boxCoords;
        
        for c = 1:size(boxCoords,1)
            lat1 = boxCoords(c,1);
            lat2 = boxCoords(c,2);
            lon1 = boxCoords(c,3);
            lon2 = boxCoords(c,4);

            plotm([lat1; lat2], [lon1; lon1], 'LineWidth', 2, 'Color', 'k');
            plotm([lat2; lat2], [lon1; lon2], 'LineWidth', 2, 'Color', 'k');
            plotm([lat2; lat1], [lon2; lon2], 'LineWidth', 2, 'Color', 'k');
            plotm([lat1; lat1], [lon2; lon1], 'LineWidth', 2, 'Color', 'k');
        end
    end
    
    if magnify
        eval(['export_fig ' saveData.fileTitle ' -painters -m' magnify ';']);
    else
        eval(['export_fig ' saveData.fileTitle ' -painters;']);
    end
    
    if vector
        p = strsplit(saveData.fileTitle, '.');
        p = p{1};
        eval(['export_fig ' p '.pdf;']);
    end
    
    fileNameParts = strsplit(saveData.fileTitle, '.');
    save([fileNameParts{1} '.mat'], 'saveData');
    close all;
    
end