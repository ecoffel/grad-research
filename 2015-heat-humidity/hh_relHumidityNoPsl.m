function relHumidity(dataDir, isRegridded, region, biasCorrect)

tempVar = 'air';
hussVar = 'shum';
pslVar = 'pres';

x4 = false;
skipExisting = false;

x4Str = '';
if x4
    x4Str = 'x4/';
end

regridStr = ['/' region];
if isRegridded
    regridStr = ['regrid/' region];
end

bcStr = '';
if biasCorrect
    bcStr = '-bc';
end

tempDirNames = dir([dataDir '/' tempVar '/' x4Str regridStr bcStr]);
tempDirIndices = [tempDirNames(:).isdir];
tempDirNames = {tempDirNames(tempDirIndices).name}';

hussDirNames = dir([dataDir '/' hussVar '/' x4Str regridStr]);
hussDirIndices = [hussDirNames(:).isdir];
hussDirNames = {hussDirNames(hussDirIndices).name}';

pslDirNames = dir([dataDir '/' pslVar '/' x4Str regridStr]);
pslDirIndices = [pslDirNames(:).isdir];
pslDirNames = {pslDirNames(pslDirIndices).name}';

if length(tempDirNames) == 0
    tempDirNames{1} = '';
end

if length(hussDirNames) == 0
    hussDirNames{1} = '';
end

if length(pslDirNames) == 0
    pslDirNames{1} = '';
end

yearIndex = 1;
monthIndex = 1;

tempMatFileNames = {};
tempMatDirNames = {};
hussMatFileNames = {};
hussMatDirNames = {};
pslMatFileNames = {};
pslMatDirNames = {};

for d = 1:length(tempDirNames)
    if strcmp(tempDirNames{d}, '.') | strcmp(tempDirNames{d}, '..')
        continue;
    end
    
    tempCurDir = [dataDir '/' tempVar '/' x4Str regridStr bcStr '/' tempDirNames{d}];
    
    if ~isdir(tempCurDir)
        continue;
    end
    
    curTempMatFileNames = dir([tempCurDir '/*.mat']);
    tempMatFileNames = {tempMatFileNames{:} curTempMatFileNames.name};
    
    for i = 1:length({curTempMatFileNames.name})
        tempMatDirNames = {tempMatDirNames{:} tempCurDir};
    end

end

for d = 1:length(hussDirNames)
    if strcmp(hussDirNames{d}, '.') | strcmp(hussDirNames{d}, '..')
        continue;
    end
    
    hussCurDir = [dataDir  '/' hussVar '/' x4Str regridStr '/' hussDirNames{d}];
    
    if ~isdir(hussCurDir)
        continue;
    end
    
    curHussMatFileNames = dir([hussCurDir, '/*.mat']);
    hussMatFileNames = {hussMatFileNames{:} curHussMatFileNames.name};
    
    for i = 1:length({curHussMatFileNames.name})
        hussMatDirNames = {hussMatDirNames{:} hussCurDir};
    end
end

for d = 1:length(pslDirNames)
    if strcmp(pslDirNames{d}, '.') | strcmp(pslDirNames{d}, '..')
        continue;
    end
    
    pslCurDir = [dataDir  '/' pslVar '/' x4Str regridStr '/' pslDirNames{d}];
    
    if ~isdir(pslCurDir)
        continue;
    end
    
    curPslMatFileNames = dir([pslCurDir, '/*.mat']);
    pslMatFileNames = {pslMatFileNames{:} curPslMatFileNames.name};
    
    for i = 1:length({curPslMatFileNames.name})
        pslMatDirNames = {pslMatDirNames{:} pslCurDir};
    end
end

if length(tempMatFileNames) == 0 | length(hussMatFileNames) == 0 | length(pslMatFileNames) == 0
    return;
end

monthIndex = 1;

% find index of matching first file name
tempStartInd = 1;
hussStartInd = 1;
pslStartInd = 1;

tempEndInd = length(tempMatFileNames);
hussEndInd = length(hussMatFileNames);
pslEndInd = length(pslMatFileNames);

maxStartYear = -1;
maxStartMonth = -1;

minEndYear = -1;
minEndMonth = -1;

% find common start date
tempMatFileName = tempMatFileNames{1};
tempMatFileNameParts = strsplit(tempMatFileName, '.');
tempMatFileNameNoExt = tempMatFileNameParts{1};

hussMatFileName = hussMatFileNames{1};
hussMatFileNameParts = strsplit(hussMatFileName, '.');
hussMatFileNameNoExt = hussMatFileNameParts{1};

pslMatFileName = pslMatFileNames{1};
pslMatFileNameParts = strsplit(pslMatFileName, '.');
pslMatFileNameNoExt = pslMatFileNameParts{1};

tempFileSubParts = strsplit(tempMatFileNameParts{1}, '_');
hussFileSubParts = strsplit(hussMatFileNameParts{1}, '_');
pslFileSubParts = strsplit(pslMatFileNameParts{1}, '_');

tempStartYear = str2num(tempFileSubParts{2});
hussStartYear = str2num(hussFileSubParts{2});
pslStartYear = str2num(pslFileSubParts{2});

tempStartMonth = str2num(tempFileSubParts{3});
hussStartMonth = str2num(hussFileSubParts{3});
pslStartMonth = str2num(pslFileSubParts{3});

maxStartYear = max(tempStartYear, max(hussStartYear, pslStartYear));
maxStartMonth = max(tempStartMonth, max(hussStartMonth, pslStartMonth));

while tempStartYear < maxStartYear | tempStartMonth < maxStartMonth
    tempStartInd = tempStartInd+1;

    tempMatFileName = tempMatFileNames{tempStartInd};
    tempMatFileNameParts = strsplit(tempMatFileName, '.');
    tempMatFileNameNoExt = tempMatFileNameParts{1};
    tempFileSubParts = strsplit(tempMatFileNameParts{1}, '_');

    tempStartYear = str2num(tempFileSubParts{2});
    tempStartMonth = str2num(tempFileSubParts{3});
end

while hussStartYear < maxStartYear | hussStartMonth < maxStartMonth
    hussStartInd = hussStartInd+1;

    hussMatFileName = hussMatFileNames{hussStartInd};
    hussMatFileNameParts = strsplit(hussMatFileName, '.');
    hussMatFileNameNoExt = hussMatFileNameParts{1};
    hussFileSubParts = strsplit(hussMatFileNameParts{1}, '_');

    hussStartYear = str2num(hussFileSubParts{2});
    hussStartMonth = str2num(hussFileSubParts{3});
end

while pslStartYear < maxStartYear | pslStartMonth < maxStartMonth
    pslStartInd = pslStartInd+1;

    pslMatFileName = pslMatFileNames{pslStartInd};
    pslMatFileNameParts = strsplit(pslMatFileName, '.');
    pslMatFileNameNoExt = pslMatFileNameParts{1};
    pslFileSubParts = strsplit(pslMatFileNameParts{1}, '_');

    pslStartYear = str2num(pslFileSubParts{2});
    pslStartMonth = str2num(pslFileSubParts{3});
end

% find common end date
tempMatFileName = tempMatFileNames{end};
tempMatFileNameParts = strsplit(tempMatFileName, '.');
tempMatFileNameNoExt = tempMatFileNameParts{1};

hussMatFileName = hussMatFileNames{end};
hussMatFileNameParts = strsplit(hussMatFileName, '.');
hussMatFileNameNoExt = hussMatFileNameParts{1};

pslMatFileName = pslMatFileNames{end};
pslMatFileNameParts = strsplit(pslMatFileName, '.');
pslMatFileNameNoExt = pslMatFileNameParts{1};

tempFileSubParts = strsplit(tempMatFileNameParts{1}, '_');
hussFileSubParts = strsplit(hussMatFileNameParts{1}, '_');
pslFileSubParts = strsplit(pslMatFileNameParts{1}, '_');

tempEndYear = str2num(tempFileSubParts{2});
hussEndYear = str2num(hussFileSubParts{2});
pslEndYear = str2num(pslFileSubParts{2});

tempEndMonth = str2num(tempFileSubParts{3});
hussEndMonth = str2num(hussFileSubParts{3});
pslEndMonth = str2num(pslFileSubParts{3});

minEndYear = min(tempEndYear, min(hussEndYear, pslEndYear));
minEndMonth = min(tempEndMonth, min(hussEndMonth, pslEndMonth));

while tempEndYear > minEndYear | tempEndMonth > minEndMonth
    tempEndInd = tempEndInd-1;

    tempMatFileName = tempMatFileNames{tempEndInd};
    tempMatFileNameParts = strsplit(tempMatFileName, '.');
    tempMatFileNameNoExt = tempMatFileNameParts{1};
    tempFileSubParts = strsplit(tempMatFileNameParts{1}, '_');

    tempEndYear = str2num(tempFileSubParts{2});
    tempEndMonth = str2num(tempFileSubParts{3});
end

while hussEndYear > minEndYear | hussEndMonth > minEndMonth
    hussEndInd = hussEndInd-1;

    hussMatFileName = hussMatFileNames{hussEndInd};
    hussMatFileNameParts = strsplit(hussMatFileName, '.');
    hussMatFileNameNoExt = hussMatFileNameParts{1};
    hussFileSubParts = strsplit(hussMatFileNameParts{1}, '_');

    hussEndYear = str2num(hussFileSubParts{2});
    hussEndMonth = str2num(hussFileSubParts{3});
end

while pslEndYear > minEndYear | pslEndMonth > minEndMonth
    pslEndInd = pslEndInd-1;

    pslMatFileName = pslMatFileNames{pslEndInd};
    pslMatFileNameParts = strsplit(pslMatFileName, '.');
    pslMatFileNameNoExt = pslMatFileNameParts{1};
    pslFileSubParts = strsplit(pslMatFileNameParts{1}, '_');

    pslEndYear = str2num(pslFileSubParts{2});
    pslEndMonth = str2num(pslFileSubParts{3});
end

folDataTarget = [dataDir, '/rh/', regridStr, x4Str, num2str(maxStartYear) num2str(maxStartMonth) '01-' num2str(minEndYear) num2str(minEndMonth) '31'];
if ~isdir(folDataTarget)
    mkdir(folDataTarget);
else
    %continue;
end

rhCurDir = folDataTarget;

while tempStartInd <= tempEndInd & hussStartInd <= hussEndInd & pslStartInd <= pslEndInd
    tempMatFileName = tempMatFileNames{tempStartInd};
    tempMatFileNameParts = strsplit(tempMatFileName, '.');
    tempMatFileNameNoExt = tempMatFileNameParts{1};

    hussMatFileName = hussMatFileNames{hussStartInd};
    hussMatFileNameParts = strsplit(hussMatFileName, '.');
    hussMatFileNameNoExt = hussMatFileNameParts{1};

    pslMatFileName = pslMatFileNames{pslStartInd};
    pslMatFileNameParts = strsplit(pslMatFileName, '.');
    pslMatFileNameNoExt = pslMatFileNameParts{1};

    tempFileSubParts = strsplit(tempMatFileNameParts{1}, '_');
    hussFileSubParts = strsplit(hussMatFileNameParts{1}, '_');
    pslFileSubParts = strsplit(pslMatFileNameParts{1}, '_');

    tempStartYear = str2num(tempFileSubParts{2});
    hussStartYear = str2num(hussFileSubParts{2});
    pslStartYear = str2num(pslFileSubParts{2});

    tempStartMonth = str2num(tempFileSubParts{3});
    hussStartMonth = str2num(hussFileSubParts{3});
    pslStartMonth = str2num(pslFileSubParts{3});

    if tempStartYear ~= hussStartYear || tempStartYear ~= pslStartYear || pslStartYear ~= hussStartYear
        ['years do not match']
        tempStartInd = tempStartInd + 1;
        hussStartInd = hussStartInd + 1;
        pslStartInd = pslStartInd + 1;
        continue;
    else
        curYear = tempStartYear;
    end

    if tempStartMonth ~= hussStartMonth || tempStartMonth ~= pslStartMonth || pslStartMonth ~= hussStartMonth
        ['months do not match']
        tempStartInd = tempStartInd + 1;
        hussStartInd = hussStartInd + 1;
        pslStartInd = pslStartInd + 1;
        continue;
    else
        curMonth = tempStartMonth;
    end

    monthStr = '';
    if curMonth < 10
        monthStr = ['0', num2str(curMonth)];
    else
        monthStr = num2str(curMonth);
    end

    fileName = ['rh_', num2str(curYear), '_' monthStr, '_01'];
    
    if exist([rhCurDir '/' fileName '.mat'], 'file') && skipExisting
        ['skipping ' rhCurDir '/' fileName]
        tempStartInd = tempStartInd + 1;
        hussStartInd = hussStartInd + 1;
        continue;
    end
    
    tempCurFileName = [tempMatDirNames{tempStartInd}, '/', tempMatFileName];
    hussCurFileName = [hussMatDirNames{hussStartInd}, '/', hussMatFileName];

    load(tempCurFileName);
    load(hussCurFileName);

    eval(['tempLat = ' tempMatFileNameNoExt '{1};']);
    eval(['tempLon = ' tempMatFileNameNoExt '{2};']);
    eval(['tempData = ' tempMatFileNameNoExt '{3};']);
    eval(['clear ' tempMatFileNameNoExt ';']);

    eval(['hussLat = ' hussMatFileNameNoExt '{1};']);
    eval(['hussLon = ' hussMatFileNameNoExt '{2};']);
    eval(['hussData = ' hussMatFileNameNoExt '{3};']);
    eval(['clear ' hussMatFileNameNoExt ';']);

    monthlyRh = [];

    tempStartInd = tempStartInd + 1;
    hussStartInd = hussStartInd + 1;
    
    if size(tempData,1) ~= size(hussData,1)
        ['lat dimensions do not match, skipping ' tempCurFileName]
        continue;
    end

    if size(tempData,2) ~= size(hussData,2)
        ['lon dimensions do not match, skipping ' tempCurFileName]
        continue;
    end

    if size(tempData,3) ~= size(hussData,3)
        ['data dimensions do not match, skipping ' tempCurFileName]
        continue;
    end

    pslData = ones(size(tempData)) .* 101325;
    
    % convert to kelvin if needed
    if tempData(1,1,1) < 200
        tempData = tempData + 273.15;
    end
    
    for d = 1:size(tempData, 3)
        es(:,:) = 611 .* exp((17.67 .* (tempData(:,:,d) - 273.16)) ./ (tempData(:,:,d) - 29.65));
        ws = (0.622 .* es(:,:)) ./ pslData(:,:,d);
        monthlyRh(:,:,d) = 100 .* hussData(:,:,d) ./ ws;
    end
    
    monthlyRh(monthlyRh > 1e10) = NaN;
    
    ['processing ' rhCurDir '/' fileName]
    eval([fileName ' = {tempLat, tempLon, monthlyRh};']);
    save([rhCurDir, '/', fileName, '.mat'], fileName, '-v7.3');

    eval(['clear ', fileName], ';');
    clear tempLat tempLon tempData monthlyRh;
    clear hussLat hussLon hussData;
    clear pslLat pslLon pslData;

    
end

