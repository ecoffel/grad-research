function wetBulb(dataDir, isRegridded, region, biasCorrect)

load waterGrid;
waterGrid = logical(waterGrid);

tempVar = 'tasmax';
hussVar = 'huss';
pVar = 'psl';

skipExisting = false;
x4 = false;

x4Str = '';
if x4
    x4Str = 'x4/';
end

regridStr = '';
if isRegridded
    regridStr = 'regrid';
end

bcStr = '';
if biasCorrect
    bcStr = '-bc';
end

tempDirNames = dir([dataDir '/' tempVar '/' x4Str regridStr '/' region bcStr]);
tempDirIndices = [tempDirNames(:).isdir];
tempDirNames = {tempDirNames(tempDirIndices).name}';

hussDirNames = dir([dataDir '/' hussVar '/' x4Str regridStr '/' region]);
hussDirIndices = [hussDirNames(:).isdir];
hussDirNames = {hussDirNames(hussDirIndices).name}';

pDirNames = dir([dataDir '/' pVar '/' x4Str regridStr '/' region]);
pDirIndices = [pDirNames(:).isdir];
pDirNames = {pDirNames(pDirIndices).name}';


if length(tempDirNames) == 0
    tempDirNames{1} = '';
end

if length(hussDirNames) == 0
    hussDirNames{1} = '';
end

if length(pDirNames) == 0
    pDirNames{1} = '';
end

yearIndex = 1;
monthIndex = 1;

tempMatFileNames = {};
tempMatDirNames = {};
hussMatFileNames = {};
hussMatDirNames = {};
pMatFileNames = {};
pMatDirNames = {};

for d = 1:length(tempDirNames)
    if strcmp(tempDirNames{d}, '.') | strcmp(tempDirNames{d}, '..')
        continue;
    end
    
    tempCurDir = [dataDir '/' tempVar '/' x4Str regridStr '/' region bcStr '/' tempDirNames{d}];
    
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
    
    hussCurDir = [dataDir  '/' hussVar '/' x4Str regridStr '/' region '/' hussDirNames{d}];
    
    if ~isdir(hussCurDir)
        continue;
    end
    
    curhussMatFileNames = dir([hussCurDir, '/*.mat']);
    hussMatFileNames = {hussMatFileNames{:} curhussMatFileNames.name};
    
    for i = 1:length({curhussMatFileNames.name})
        hussMatDirNames = {hussMatDirNames{:} hussCurDir};
    end
end

for d = 1:length(pDirNames)
    if strcmp(pDirNames{d}, '.') | strcmp(pDirNames{d}, '..')
        continue;
    end
    
    pCurDir = [dataDir  '/' pVar '/' x4Str regridStr '/' region '/' pDirNames{d}];
    
    if ~isdir(pCurDir)
        continue;
    end
    
    curPMatFileNames = dir([pCurDir, '/*.mat']);
    pMatFileNames = {pMatFileNames{:} curPMatFileNames.name};
    
    for i = 1:length({curPMatFileNames.name})
        pMatDirNames = {pMatDirNames{:} pCurDir};
    end
end

if length(tempMatFileNames) == 0 | length(hussMatFileNames) == 0 | length(pMatFileNames) == 0
    return;
end

monthIndex = 1;

% find index of matching first file name
tempStartInd = 1;
hussStartInd = 1;
pStartInd = 1;

tempEndInd = length(tempMatFileNames);
hussEndInd = length(hussMatFileNames);
pEndInd = length(pMatFileNames);

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

pMatFileName = pMatFileNames{1};
pMatFileNameParts = strsplit(pMatFileName, '.');
pMatFileNameNoExt = pMatFileNameParts{1};

tempFileSubParts = strsplit(tempMatFileNameParts{1}, '_');
hussFileSubParts = strsplit(hussMatFileNameParts{1}, '_');
pFileSubParts = strsplit(pMatFileNameParts{1}, '_');

tempStartYear = str2num(tempFileSubParts{2});
hussStartYear = str2num(hussFileSubParts{2});
pStartYear = str2num(pFileSubParts{2});

tempStartMonth = str2num(tempFileSubParts{3});
hussStartMonth = str2num(hussFileSubParts{3});
pStartMonth = str2num(pFileSubParts{3});

maxStartYear = max(tempStartYear, hussStartYear);
maxStartMonth = max(tempStartMonth, hussStartMonth);

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

while pStartYear < maxStartYear | pStartMonth < maxStartMonth
    pStartInd = pStartInd+1;

    pMatFileName = pMatFileNames{pStartInd};
    pMatFileNameParts = strsplit(pMatFileName, '.');
    pMatFileNameNoExt = pMatFileNameParts{1};
    pFileSubParts = strsplit(pMatFileNameParts{1}, '_');

    pStartYear = str2num(pFileSubParts{2});
    pStartMonth = str2num(pFileSubParts{3});
end

% find common end date
tempMatFileName = tempMatFileNames{end};
tempMatFileNameParts = strsplit(tempMatFileName, '.');
tempMatFileNameNoExt = tempMatFileNameParts{1};

hussMatFileName = hussMatFileNames{end};
hussMatFileNameParts = strsplit(hussMatFileName, '.');
hussMatFileNameNoExt = hussMatFileNameParts{1};

pMatFileName = pMatFileNames{end};
pMatFileNameParts = strsplit(pMatFileName, '.');
pMatFileNameNoExt = pMatFileNameParts{1};

tempFileSubParts = strsplit(tempMatFileNameParts{1}, '_');
hussFileSubParts = strsplit(hussMatFileNameParts{1}, '_');
pFileSubParts = strsplit(pMatFileNameParts{1}, '_');

tempEndYear = str2num(tempFileSubParts{2});
hussEndYear = str2num(hussFileSubParts{2});
pEndYear = str2num(pFileSubParts{2});

tempEndMonth = str2num(tempFileSubParts{3});
hussEndMonth = str2num(hussFileSubParts{3});
pEndMonth = str2num(pFileSubParts{3});

minEndYear = min(tempEndYear, hussEndYear);
minEndMonth = min(tempEndMonth, hussEndMonth);

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

while pEndYear > minEndYear | pEndMonth > minEndMonth
    pEndInd = pEndInd-1;

    pMatFileName = pMatFileNames{pEndInd};
    pMatFileNameParts = strsplit(pMatFileName, '.');
    pMatFileNameNoExt = pMatFileNameParts{1};
    pFileSubParts = strsplit(pMatFileNameParts{1}, '_');

    pEndYear = str2num(pFileSubParts{2});
    pEndMonth = str2num(pFileSubParts{3});
end

folDataTarget = [dataDir, '/wb-davies-jones/', x4Str regridStr, '/', region, '/', num2str(maxStartYear) num2str(maxStartMonth) '01-' num2str(minEndYear) num2str(minEndMonth) '31'];
if ~isdir(folDataTarget)
    mkdir(folDataTarget);
else
    %continue;
end

wbCurDir = folDataTarget;

while tempStartInd <= tempEndInd & hussStartInd <= hussEndInd
    tempMatFileName = tempMatFileNames{tempStartInd};
    tempMatFileNameParts = strsplit(tempMatFileName, '.');
    tempMatFileNameNoExt = tempMatFileNameParts{1};

    hussMatFileName = hussMatFileNames{hussStartInd};
    hussMatFileNameParts = strsplit(hussMatFileName, '.');
    hussMatFileNameNoExt = hussMatFileNameParts{1};
    
    pMatFileName = pMatFileNames{pStartInd};
    pMatFileNameParts = strsplit(pMatFileName, '.');
    pMatFileNameNoExt = pMatFileNameParts{1};

    tempFileSubParts = strsplit(tempMatFileNameParts{1}, '_');
    hussFileSubParts = strsplit(hussMatFileNameParts{1}, '_');
    pFileSubParts = strsplit(pMatFileNameParts{1}, '_');

    tempStartYear = str2num(tempFileSubParts{2});
    hussStartYear = str2num(hussFileSubParts{2});
    pStartYear = str2num(pFileSubParts{2});

    tempStartMonth = str2num(tempFileSubParts{3});
    hussStartMonth = str2num(hussFileSubParts{3});
    pStartMonth = str2num(pFileSubParts{3});

    if tempStartYear ~= hussStartYear
        ['years do not match']
        return;
    else
        curYear = tempStartYear;
    end

    if tempStartMonth ~= hussStartMonth
        ['months do not match']
        return;
    else
        curMonth = tempStartMonth;
    end
    
    monthStr = '';
    if curMonth < 10
        monthStr = ['0', num2str(curMonth)];
    else
        monthStr = num2str(curMonth);
    end

    fileName = ['wb_', num2str(curYear), '_' monthStr, '_01'];
    
    if exist([wbCurDir '/' fileName '.mat'], 'file') && skipExisting
        ['skipping ' wbCurDir '/' fileName '.mat']
        tempStartInd = tempStartInd + 1;
        hussStartInd = hussStartInd + 1;
        continue;
    end

    tempCurFileName = [tempMatDirNames{tempStartInd}, '/', tempMatFileName];
    hussCurFileName = [hussMatDirNames{hussStartInd}, '/', hussMatFileName];
    pCurFileName = [pMatDirNames{pStartInd}, '/', pMatFileName];

    load(tempCurFileName);
    load(hussCurFileName);
    load(pCurFileName);

    eval(['tempLat = ' tempMatFileNameNoExt '{1};']);
    eval(['tempLon = ' tempMatFileNameNoExt '{2};']);
    eval(['tempData = ' tempMatFileNameNoExt '{3};']);
    eval(['clear ' tempMatFileNameNoExt ';']);

    eval(['hussLat = ' hussMatFileNameNoExt '{1};']);
    eval(['hussLon = ' hussMatFileNameNoExt '{2};']);
    eval(['hussData = ' hussMatFileNameNoExt '{3};']);
    eval(['clear ' hussMatFileNameNoExt ';']);
    
    eval(['pLat = ' pMatFileNameNoExt '{1};']);
    eval(['pLon = ' pMatFileNameNoExt '{2};']);
    eval(['pData = ' pMatFileNameNoExt '{3};']);
    eval(['clear ' pMatFileNameNoExt ';']);
    
    tempStartInd = tempStartInd + 1;
    hussStartInd = hussStartInd + 1;
    pStartInd = pStartInd + 1;

    if size(hussData,1) ~= size(tempData,1)
        ['lat dimensions do not match, skipping ' tempCurFileName]
        clear tempLat tempLon tempData;
        clear hussLat hussLon hussData;
        continue;
    end

    if size(hussData,2) ~= size(tempData,2)
        ['lon dimensions do not match, skipping ' tempCurFileName]
        clear tempLat tempLon tempData;
        clear hussLat hussLon hussData;
        continue;
    end

    if size(hussData,3) ~= size(tempData,3)
        ['data dimensions do not match, skipping ' tempCurFileName]
        clear tempLat tempLon tempData;
        clear hussLat hussLon hussData;
        continue;
    end

    wb = zeros(size(tempData, 1), size(tempData, 2), size(tempData, 3));
    wb(wb == 0) = NaN;
    
    for xpos = 1:size(tempData,1)
        
        ['xpos = ' num2str(xpos)]
        
        for ypos = 1:size(tempData,2)
            
            if waterGrid(xpos, ypos)
                continue;
            end
            
            for d = 1:size(tempData,3)

                if tempData(xpos,ypos,d) > 200
                    T = (tempData(xpos,ypos,d) - 273.15);   % deg C
                else
                    T = (tempData(xpos,ypos,d));            % deg C
                end
                
                [wb(xpos, ypos, d), Teq, epott] = kopp_wetBulb(T, pData(xpos, ypos, d), hussData(xpos, ypos, d));
                
%                 huss = hussData(xpos,ypos,d);               % percentage
%                 
%                 wb(xpos, ypos, d) = T * atan(0.151977 * sqrt(huss + 8.313659)) + ...
%                                      atan(T + huss) - atan(huss - 1.676331) + ...
%                                      0.00391838*(huss^(1.5)) * atan(0.023101*huss) - 4.686035;


            end

        end
    end

    ['processing ' wbCurDir '/' fileName]
    eval([fileName ' = {tempLat, tempLon, wb};']);
    save([wbCurDir, '/', fileName, '.mat'], fileName, '-v7.3');

    eval(['clear ', fileName], ';');
    clear tempLat tempLon tempData wb;
    clear hussLat hussLon hussData;

end






