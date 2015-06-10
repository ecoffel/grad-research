function [percentiles_out] = findPercentileWinds(dataDir, varName, percentiles, varargin)

matFileNames = dir([dataDir, '/*.mat']);
matFileNames = {matFileNames.name};

dailyData = [];
dayIndex = 1;
lat = [];
lon = [];

plev = -1;
if length(varargin) == 1
    plev = varargin{1};
end

for k = 1:length(matFileNames)
    matFileName = matFileNames{k};
    
    % check if this file contains the target variable
    matFileNameParts = strsplit(matFileName, '_');
    if length(strfind(matFileNameParts{1}, varName)) == 0
        continue
    end
    
    matFileNameParts = strsplit(matFileName, '.');
    matFileNameNoExt = matFileNameParts{1};
    
    curFileName = [dataDir, '/', matFileName];
    load(curFileName);
    
    curMonthlyData = eval([matFileNameNoExt, '{3}']);
    
    for d = 1:size(curMonthlyData,length(size(curMonthlyData)))
        curDay = [];
        if plev ~= -1
            curDay = double(squeeze(curMonthlyData(:,:,plev,d)));
        else
            curDay = double(squeeze(curMonthlyData(:,:,d)));
        end
        dailyData(:,:,dayIndex) = curDay;
        dayIndex = dayIndex + 1;
    end
    
    if length(lat) == 0
        lat = eval([matFileNameNoExt, '{1}']);
        lon = eval([matFileNameNoExt, '{2}']);
    end
    
    clear curMonthlyData;
    clear(matFileNameNoExt);
end

percentiles_out = {};
for p=1:length(percentiles)
    percentiles_out{p} = {lat, lon, permute(prctile(permute(dailyData, [3 1 2]), [percentiles(p)]), [2 3 1])};
end