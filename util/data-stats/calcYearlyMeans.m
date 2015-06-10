function [yearlyMeans] = calcYearlyMeans(baseDir, varName, varargin)

yearlyMeans = [];

if length(varargin) > 1
    'Error: cannot take more than 3 arguments'
    return
end

dirNames = dir(baseDir);
dirNames = {dirNames.name};

index = 1;
for k = 1:length(dirNames)
    dirName = dirNames{k};
    if length(dirName) < 3 | ~isdir([baseDir, '/', dirName])
        continue;
    end
    
    dirName
    if length(varargin) == 1
        plev = varargin{1};
        yearlyMeans{index} = {dirName, calcYearlyMean([baseDir '/' dirName], varName, plev)};
        index = index + 1;
    elseif length(varargin) == 0
        yearlyMeans{index} = {dirName, calcYearlyMean([baseDir '/' dirName], varName)};
        index = index + 1;
    end
end