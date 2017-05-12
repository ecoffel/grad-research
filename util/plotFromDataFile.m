
function [fg, cb] = plotFromDataFile(saveData)

    boxCoordsExists = false;
    if isfield(saveData, 'boxCoords')
        boxCoordsExists = true;
    end
    
    statDataExists = false;
    if isfield(saveData, 'statData')
        statDataExists = true;
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
    
    set(gca, 'Color', 'none');
    set(gca, 'FontSize', 24);
    xlabel(cb, saveData.plotXUnits, 'FontSize', 24);
    set(cb, 'XTick', xticks);
    cbPos = get(cb, 'Position');
    title(saveData.plotTitle, 'FontSize', 30);
    
    set(gcf, 'Position', get(0,'Screensize'));
    ti = get(gca,'TightInset');
    set(gca,'Position', [ti(1) cbPos(2) 1-ti(3)-ti(1) 1-ti(4)-cbPos(2)-cbPos(4)]);
    tightmap;
    
    if statDataExists
        statData = saveData.statData;
        
        for xlat = 1:size(statData, 1)-1
            for ylon = 1:size(statData, 2)-1
                if statData(xlat, ylon)
                    startingLat = saveData.data{1}(xlat, ylon);
                    endingLat = saveData.data{1}(xlat+1, ylon);

                    startingLon = saveData.data{2}(xlat, ylon);
                    endingLon = saveData.data{2}(xlat, ylon+1);
                    
                    for j = linspace(startingLat, endingLat, abs(endingLat-startingLat)/saveData.stippleInterval)
                        for k = linspace(startingLon, endingLon, abs(endingLon-startingLon)/saveData.stippleInterval)
                            plotm(j, k, 'Marker', 'o',...
                                        'MarkerEdgeColor', 'k',...
                                        'MarkerFaceColor', 'k',...
                                        'MarkerSize', 2)
                        end
                    end
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
        geoshow(flipud(lat),flipud(long),'DisplayType','polygon','FaceColor','white','EdgeColor','None');
    end
    
    if blockLand
        geoshow('landareas.shp','DisplayType','polygon','FaceColor','white','EdgeColor','None');
    end
    
    if magnify
        eval(['export_fig ' saveData.fileTitle ' -m' magnify ';']);
    else
        eval(['export_fig ' saveData.fileTitle ';']);
    end
    fileNameParts = strsplit(saveData.fileTitle, '.');
    save([fileNameParts{1} '.mat'], 'saveData');
    close all;
    
end