data = saveData{1};
plotRegion = saveData{2};
plotRange = saveData{3};
plotTitle = saveData{4};
fileTitle = saveData{5};
plotXUnits = saveData{6};
boxCoords = saveData{7};
colorMap = saveData{8};
blockWater = saveData{9};
if length(saveData) > 9
    statData = saveData{10};
else
    statData = [];
end

saveData = struct();
saveData.data = data;
saveData.plotRegion = plotRegion;
saveData.plotRange = plotRange;
saveData.plotTitle = plotTitle;
saveData.plotXUnits = plotXUnits;
saveData.fileTitle = fileTitle;

if length(boxCoords) > 0
    saveData.boxCoords = boxCoords;
end

if length(colorMap) > 0
    saveData.colorMap = colorMap;
end

saveData.blockWater = blockWater;

if length(statData) > 0
    saveData.statData = statData;
end

fileNameParts = strsplit(fileTitle, '.');
save([fileNameParts{1} '.mat'], 'saveData');