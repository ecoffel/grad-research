
function [fg, cb] = plotFromDataFile(saveData)

    boxCoordsExists = false;
    if isfield(saveData, 'boxCoords')
        boxCoordsExists = true;
    end
    
    statDataExists = false;
    if isfield(saveData, 'statData')
        statDataExists = true;
    end
    
    stippleInterval = 5;
    if isfield(saveData, 'stippleInterval')
        stippleInterval = saveData.stippleInterval;
    end
    
    if isfield(saveData, 'colormap')
        colorMap = saveData.colormap;
    else
        colorMap = [];
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
    
    if isfield(saveData, 'cbXTicks')
        xticks = saveData.cbXTicks;
    else
        xticks = false;
    end
    
    [fg,cb] = plotModelData(saveData.data, saveData.plotRegion, 'caxis', saveData.plotRange, 'colormap', colorMap, 'vectorData', vectorData, 'countries', plotCountries, 'states', plotStates);
    
    %set(gca, 'DrawMode', 'childorder');
    %set(gca, 'SortMethod', 'childorder');
    
    set(gca, 'Color', 'none');
    set(gca, 'FontSize', 50);
    xlabel(cb, saveData.plotXUnits, 'FontSize', 50);
    set(cb, 'XTick', xticks);
    cbPos = get(cb, 'Position');
    title(saveData.plotTitle, 'FontSize', 30);
    
    set(gcf, 'Position', get(0,'Screensize'));
    ti = get(gca,'TightInset');
    set(gca,'Position', [ti(1) cbPos(2) 1-ti(3)-ti(1) 1-ti(4)-cbPos(2)-cbPos(4)]);
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
        xCoords = circshift(xCoords,-15,2);
        yCoords = circshift(yCoords,-15,2);
        statData = circshift(statData,-15,2);
        
        xCoords(end+1, :) = xCoords(1, :);
        xCoords(:, end+1) = xCoords(:, 1);
        yCoords(:, end+1) = yCoords(:, 1);
        yCoords(end+1, :) = yCoords(1, :);
        
        for xlat = 1:size(statData, 1)
            for ylon = 1:size(statData, 2)
                if statData(xlat, ylon)
                    
                    tulX = xCoords(xlat, ylon);
                    tulY = yCoords(xlat, ylon);
                    
                    turX = xCoords(xlat+1, ylon);
                    turY = yCoords(xlat+1, ylon);
                    
                    tblX = xCoords(xlat, ylon+1);
                    tblY = yCoords(xlat, ylon+1);
                    
                    tbrX = xCoords(xlat+1, ylon+1);
                    tbrY = yCoords(xlat+1, ylon+1);
                    
                    p = patch([tulX turX tbrX tblX], [tulY turY tbrY tblY], 'w');
                    set(p, 'FaceColor', 'none', 'EdgeColor', 'none');
                    h = hatchfill2(p, 'single', 'HatchAngle', 45, 'HatchColor', 'w', 'HatchSpacing', stippleInterval);
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
            end
        end
    end
    
    if boxCoordsExists
        boxCoords = saveData.boxCoords;
        
        lat1 = boxCoords(1,1);
        lat2 = boxCoords(1,2);
        lon1 = boxCoords(2,1);
        lon2 = boxCoords(2,2);
        
        plotm([lat1; lat2], [lon1; lon1], 'LineWidth', 2, 'Color', 'r');
        plotm([lat2; lat2], [lon1; lon2], 'LineWidth', 2, 'Color', 'r');
        plotm([lat2; lat1], [lon2; lon2], 'LineWidth', 2, 'Color', 'r');
        plotm([lat1; lat1], [lon2; lon1], 'LineWidth', 2, 'Color', 'r');
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
        
    if magnify
        eval(['export_fig ' saveData.fileTitle ' -painters -m' magnify ';']);
    else
        eval(['export_fig ' saveData.fileTitle ' -painters;']);
    end
    fileNameParts = strsplit(saveData.fileTitle, '.');
    save([fileNameParts{1} '.mat'], 'saveData');
    close all;
    
end