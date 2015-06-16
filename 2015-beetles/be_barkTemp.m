function barkTemp(dataDir, isRegridded)

K = [.221 .175 .156 .141 .077];
timeStep = 1;

maxTempVar = 'tasmax';
minTempVar = 'tasmin';

regridStr = '';
if isRegridded
    regridStr = 'regrid/';
end

maxTempDirNames = dir([dataDir '/' maxTempVar '/' regridStr]);
maxTempDirIndices = [maxTempDirNames(:).isdir];
maxTempDirNames = {maxTempDirNames(maxTempDirIndices).name}';

minTempDirNames = dir([dataDir '/' minTempVar '/' regridStr]);
minTempDirIndices = [minTempDirNames(:).isdir];
minTempDirNames = {minTempDirNames(minTempDirIndices).name}';

if length(maxTempDirNames) == 0
    maxTempDirNames{1} = '';
end

if length(minTempDirNames) == 0
    minTempDirNames{1} = '';
end

yearIndex = 1;
monthIndex = 1;

maxTempMatFileNames = {};
maxTempMatDirNames = {};
minTempMatFileNames = {};
minTempMatDirNames = {};

for d = 1:length(maxTempDirNames)
    if strcmp(maxTempDirNames{d}, '.') | strcmp(maxTempDirNames{d}, '..')
        continue;
    end
    
    maxTempCurDir = [dataDir '/' maxTempVar '/' regridStr maxTempDirNames{d}];
    
    if ~isdir(maxTempCurDir)
        continue;
    end
    
    curTempMatFileNames = dir([maxTempCurDir '/*.mat']);
    maxTempMatFileNames = {maxTempMatFileNames{:} curTempMatFileNames.name};
    
    for i = 1:length({curTempMatFileNames.name})
        maxTempMatDirNames = {maxTempMatDirNames{:} maxTempCurDir};
    end
end

for d = 1:length(minTempDirNames)
    if strcmp(minTempDirNames{d}, '.') | strcmp(minTempDirNames{d}, '..')
        continue;
    end
    
    minTempCurDir = [dataDir  '/' minTempVar '/' regridStr minTempDirNames{d}];
    
    if ~isdir(minTempCurDir)
        continue;
    end
    
    curMinTempMatFileNames = dir([minTempCurDir, '/*.mat']);
    minTempMatFileNames = {minTempMatFileNames{:} curMinTempMatFileNames.name};
    
    for i = 1:length({curMinTempMatFileNames.name})
        minTempMatDirNames = {minTempMatDirNames{:} minTempCurDir};
    end
end


if length(maxTempMatFileNames) == 0 | length(minTempMatFileNames) == 0
    return;
end

monthIndex = 1;

% find index of matching first file name
maxTempStartInd = 1;
minTempStartInd = 1;
maxTempEndInd = length(maxTempMatFileNames);
minTempEndInd = length(minTempMatFileNames);

maxStartYear = -1;
maxStartMonth = -1;

minEndYear = -1;
minEndMonth = -1;

% find common start date
maxTempMatFileName = maxTempMatFileNames{1};
maxTempMatFileNameParts = strsplit(maxTempMatFileName, '.');
maxTempMatFileNameNoExt = maxTempMatFileNameParts{1};

minTempMatFileName = minTempMatFileNames{1};
minTempMatFileNameParts = strsplit(minTempMatFileName, '.');
minTempMatFileNameNoExt = minTempMatFileNameParts{1};


maxTempFileSubParts = strsplit(maxTempMatFileNameParts{1}, '_');
minTempFileSubParts = strsplit(minTempMatFileNameParts{1}, '_');

maxTempStartYear = str2num(maxTempFileSubParts{2});
minTempStartYear = str2num(minTempFileSubParts{2});

maxTempStartMonth = str2num(maxTempFileSubParts{3});
minTempStartMonth = str2num(minTempFileSubParts{3});

maxStartYear = maxTempStartYear;
maxStartMonth = maxTempStartMonth;

while maxTempStartYear < maxStartYear | maxTempStartMonth < maxStartMonth
    maxTempStartInd = maxTempStartInd+1;

    maxTempMatFileName = maxTempMatFileNames{maxTempStartInd};
    maxTempMatFileNameParts = strsplit(maxTempMatFileName, '.');
    maxTempMatFileNameNoExt = maxTempMatFileNameParts{1};
    maxTempFileSubParts = strsplit(maxTempMatFileNameParts{1}, '_');

    maxTempStartYear = str2num(maxTempFileSubParts{2});
    maxTempStartMonth = str2num(maxTempFileSubParts{3});
end

while minTempStartYear < maxStartYear | minTempStartMonth < maxStartMonth
    minTempStartInd = minTempStartInd+1;

    minTempMatFileName = minTempMatFileNames{minTempStartInd};
    minTempMatFileNameParts = strsplit(minTempMatFileName, '.');
    minTempMatFileNameNoExt = minTempMatFileNameParts{1};
    minTempFileSubParts = strsplit(minTempMatFileNameParts{1}, '_');

    minTempStartYear = str2num(minTempFileSubParts{2});
    minTempStartMonth = str2num(minTempFileSubParts{3});
end

% find common end date
maxTempMatFileName = maxTempMatFileNames{end};
maxTempMatFileNameParts = strsplit(maxTempMatFileName, '.');
maxTempMatFileNameNoExt = maxTempMatFileNameParts{1};

minTempMatFileName = minTempMatFileNames{end};
minTempMatFileNameParts = strsplit(minTempMatFileName, '.');
minTempMatFileNameNoExt = minTempMatFileNameParts{1};

maxTempFileSubParts = strsplit(maxTempMatFileNameParts{1}, '_');
minTempFileSubParts = strsplit(minTempMatFileNameParts{1}, '_');

maxTempEndYear = str2num(maxTempFileSubParts{2});
minTempEndYear = str2num(minTempFileSubParts{2});

maxTempEndMonth = str2num(maxTempFileSubParts{3});
minTempEndMonth = str2num(minTempFileSubParts{3});

minEndYear = min(maxTempEndYear, minTempEndYear);
minEndMonth = min(maxTempEndMonth, minTempEndMonth);

while maxTempEndYear > minEndYear | maxTempEndMonth > minEndMonth
    maxTempEndInd = maxTempEndInd-1;

    maxTempMatFileName = maxTempMatFileNames{maxTempEndInd};
    maxTempMatFileNameParts = strsplit(maxTempMatFileName, '.');
    maxTempMatFileNameNoExt = maxTempMatFileNameParts{1};
    maxTempFileSubParts = strsplit(maxTempMatFileNameParts{1}, '_');

    maxTempEndYear = str2num(maxTempFileSubParts{2});
    maxTempEndMonth = str2num(maxTempFileSubParts{3});
end

while minTempEndYear > minEndYear | minTempEndMonth > minEndMonth
    minTempEndInd = minTempEndInd-1;

    minTempMatFileName = minTempMatFileNames{minTempEndInd};
    minTempMatFileNameParts = strsplit(minTempMatFileName, '.');
    minTempMatFileNameNoExt = minTempMatFileNameParts{1};
    minTempFileSubParts = strsplit(minTempMatFileNameParts{1}, '_');

    minTempEndYear = str2num(minTempFileSubParts{2});
    minTempEndMonth = str2num(minTempFileSubParts{3});
end

folDataTarget = [dataDir, '/bt/', regridStr, num2str(maxStartYear) num2str(maxStartMonth) '01-' num2str(minEndYear) num2str(minEndMonth) '31'];
if ~isdir(folDataTarget)
    mkdir(folDataTarget);
else
    %continue;
end

% start with tasmax
maxOrMin = true;

btCurDir = folDataTarget;

while maxTempStartInd <= maxTempEndInd & minTempStartInd <= minTempEndInd
    maxTempMatFileName = maxTempMatFileNames{maxTempStartInd};
    maxTempMatFileNameParts = strsplit(maxTempMatFileName, '.');
    maxTempMatFileNameNoExt = maxTempMatFileNameParts{1};

    minTempMatFileName = minTempMatFileNames{minTempStartInd};
    minTempMatFileNameParts = strsplit(minTempMatFileName, '.');
    minTempMatFileNameNoExt = minTempMatFileNameParts{1};
    
    maxTempFileSubParts = strsplit(maxTempMatFileNameParts{1}, '_');
    minTempFileSubParts = strsplit(minTempMatFileNameParts{1}, '_');
    
    maxTempStartYear = str2num(maxTempFileSubParts{2});
    minTempStartYear = str2num(minTempFileSubParts{2});
    
    maxTempStartMonth = str2num(maxTempFileSubParts{3});
    minTempStartMonth = str2num(minTempFileSubParts{3});

    if maxTempStartYear ~= minTempStartYear
        ['years do not match']
        return;
    else
        curYear = maxTempStartYear;
    end

    if maxTempStartMonth ~= minTempStartMonth
        ['months do not match']
        return;
    else
        curMonth = maxTempStartMonth;
    end
    
    maxTempCurFileName = [maxTempMatDirNames{maxTempStartInd}, '/', maxTempMatFileName];
    minTempCurFileName = [minTempMatDirNames{minTempStartInd}, '/', minTempMatFileName];

    load(maxTempCurFileName);
    load(minTempCurFileName);

    eval(['maxTempLat = ' maxTempMatFileNameNoExt '{1};']);
    eval(['maxTempLon = ' maxTempMatFileNameNoExt '{2};']);
    eval(['maxTempData = ' maxTempMatFileNameNoExt '{3};']);
    eval(['clear ' maxTempMatFileNameNoExt ';']);
    
    eval(['minTempLat = ' minTempMatFileNameNoExt '{1};']);
    eval(['minTempLon = ' minTempMatFileNameNoExt '{2};']);
    eval(['minTempData = ' minTempMatFileNameNoExt '{3};']);
    eval(['clear ' minTempMatFileNameNoExt ';']);

    if size(maxTempData,1) ~= size(minTempData,1)
        ['lat dimensions do not match, skipping ' maxTempCurFileName]
        maxTempStartInd = maxTempStartInd + 1;
        minTempStartInd = minTempStartInd + 1;
        continue;
    end

    if size(maxTempData,2) ~= size(minTempData,2)
        ['lon dimensions do not match, skipping ' maxTempCurFileName]
        maxTempStartInd = maxTempStartInd + 1;
        minTempStartInd = minTempStartInd + 1;
        continue;
    end
    
    if size(maxTempData, 3) ~= size(minTempData, 3)
        ['time dimensions do not match, skipping' maxTempCurFileName]
        maxTempStartInd = maxTempStartInd + 1;
        minTempStartInd = minTempStartInd + 1;
        continue;
    end
    
    monthlyBarkT = [];
    monthlyBarkT(:,:,1) = (maxTempData(:,:,1)+minTempData(:,:,1)) ./ 2;

    maxDayInc = 1;
    minDayInc = 1;
    
    for d = 1:(size(maxTempData, 3)+size(minTempData, 3))-2
        if maxOrMin
            monthlyBarkT(:,:,d+1) = monthlyBarkT(:,:,d) + mean(K)*(maxTempData(:,:,maxDayInc+1) - monthlyBarkT(:,:,d))*timeStep;
            maxDayInc = maxDayInc+1;
        else
            monthlyBarkT(:,:,d+1) = monthlyBarkT(:,:,d) + mean(K)*(minTempData(:,:,minDayInc+1) - monthlyBarkT(:,:,d))*timeStep;
            minDayInc = minDayInc+1;
        end
        maxOrMin = ~maxOrMin;
    end

    [latIndexRange, lonIndexRange] = latLonIndexRange({maxTempLat, maxTempLon, monthlyBarkT}, [37 46], [-80 -60]);
    maxTempLat = maxTempLat(latIndexRange, lonIndexRange);
    maxTempLon = maxTempLon(latIndexRange, lonIndexRange);
    maxTempData = maxTempData(latIndexRange, lonIndexRange, :);
    minTempData = minTempData(latIndexRange, lonIndexRange, :);
    monthlyBarkT = monthlyBarkT(latIndexRange, lonIndexRange, :);
    
    monthStr = '';
    if curMonth < 10
        monthStr = ['0', num2str(curMonth)];
    else
        monthStr = num2str(curMonth);
    end

    fileName = ['bt_', num2str(curYear), '_' monthStr, '_01'];
    
    if exist([btCurDir '/' fileName '.mat'], 'file')
        %continue;
    end
    
    ['processing ' btCurDir '/' fileName]
    eval([fileName ' = {maxTempLat, maxTempLon, monthlyBarkT};']);
    save([btCurDir, '/', fileName, '.mat'], fileName, '-v7.3');

    eval(['clear ', fileName], ';');
    clear maxTempLat maxTempLon maxTempData monthlyBarkT;
    clear minTempLat minTempLon minTempData;

    maxTempStartInd = maxTempStartInd + 1;
    minTempStartInd = minTempStartInd + 1;
end

