function wetBulb(dataDir, isRegridded, region, biasCorrect)

tempVar = 'tasmax';
rhVar = 'rh';

skipExisting = true;

regridStr = '';
if isRegridded
    regridStr = 'regrid';
end

bcStr = '';
if biasCorrect
    bcStr = '-bc';
end

tempDirNames = dir([dataDir '/' tempVar '/' regridStr '/' region bcStr]);
tempDirIndices = [tempDirNames(:).isdir];
tempDirNames = {tempDirNames(tempDirIndices).name}';

rhDirNames = dir([dataDir '/' rhVar '/' regridStr '/' region]);
rhDirIndices = [rhDirNames(:).isdir];
rhDirNames = {rhDirNames(rhDirIndices).name}';


if length(tempDirNames) == 0
    tempDirNames{1} = '';
end

if length(rhDirNames) == 0
    rhDirNames{1} = '';
end

yearIndex = 1;
monthIndex = 1;

tempMatFileNames = {};
tempMatDirNames = {};
rhMatFileNames = {};
rhMatDirNames = {};

for d = 1:length(tempDirNames)
    if strcmp(tempDirNames{d}, '.') | strcmp(tempDirNames{d}, '..')
        continue;
    end
    
    tempCurDir = [dataDir '/' tempVar '/' regridStr '/' region bcStr '/' tempDirNames{d}];
    
    if ~isdir(tempCurDir)
        continue;
    end
    
    curTempMatFileNames = dir([tempCurDir '/*.mat']);
    tempMatFileNames = {tempMatFileNames{:} curTempMatFileNames.name};
    
    for i = 1:length({curTempMatFileNames.name})
        tempMatDirNames = {tempMatDirNames{:} tempCurDir};
    end

end

for d = 1:length(rhDirNames)
    if strcmp(rhDirNames{d}, '.') | strcmp(rhDirNames{d}, '..')
        continue;
    end
    
    rhCurDir = [dataDir  '/' rhVar '/' regridStr '/' region '/' rhDirNames{d}];
    
    if ~isdir(rhCurDir)
        continue;
    end
    
    curHussMatFileNames = dir([rhCurDir, '/*.mat']);
    rhMatFileNames = {rhMatFileNames{:} curHussMatFileNames.name};
    
    for i = 1:length({curHussMatFileNames.name})
        rhMatDirNames = {rhMatDirNames{:} rhCurDir};
    end
end

if length(tempMatFileNames) == 0 | length(rhMatFileNames) == 0
    return;
end

monthIndex = 1;

% find index of matching first file name
tempStartInd = 1;
rhStartInd = 1;

tempEndInd = length(tempMatFileNames);
rhEndInd = length(rhMatFileNames);

maxStartYear = -1;
maxStartMonth = -1;

minEndYear = -1;
minEndMonth = -1;

% find common start date
tempMatFileName = tempMatFileNames{1};
tempMatFileNameParts = strsplit(tempMatFileName, '.');
tempMatFileNameNoExt = tempMatFileNameParts{1};

rhMatFileName = rhMatFileNames{1};
rhMatFileNameParts = strsplit(rhMatFileName, '.');
rhMatFileNameNoExt = rhMatFileNameParts{1};

tempFileSubParts = strsplit(tempMatFileNameParts{1}, '_');
rhFileSubParts = strsplit(rhMatFileNameParts{1}, '_');

tempStartYear = str2num(tempFileSubParts{2});
rhStartYear = str2num(rhFileSubParts{2});

tempStartMonth = str2num(tempFileSubParts{3});
rhStartMonth = str2num(rhFileSubParts{3});

maxStartYear = max(tempStartYear, rhStartYear);
maxStartMonth = max(tempStartMonth, rhStartMonth);

while tempStartYear < maxStartYear | tempStartMonth < maxStartMonth
    tempStartInd = tempStartInd+1;

    tempMatFileName = tempMatFileNames{tempStartInd};
    tempMatFileNameParts = strsplit(tempMatFileName, '.');
    tempMatFileNameNoExt = tempMatFileNameParts{1};
    tempFileSubParts = strsplit(tempMatFileNameParts{1}, '_');

    tempStartYear = str2num(tempFileSubParts{2});
    tempStartMonth = str2num(tempFileSubParts{3});
end

while rhStartYear < maxStartYear | rhStartMonth < maxStartMonth
    rhStartInd = rhStartInd+1;

    rhMatFileName = rhMatFileNames{rhStartInd};
    rhMatFileNameParts = strsplit(rhMatFileName, '.');
    rhMatFileNameNoExt = rhMatFileNameParts{1};
    rhFileSubParts = strsplit(rhMatFileNameParts{1}, '_');

    rhStartYear = str2num(rhFileSubParts{2});
    rhStartMonth = str2num(rhFileSubParts{3});
end

% find common end date
tempMatFileName = tempMatFileNames{end};
tempMatFileNameParts = strsplit(tempMatFileName, '.');
tempMatFileNameNoExt = tempMatFileNameParts{1};

rhMatFileName = rhMatFileNames{end};
rhMatFileNameParts = strsplit(rhMatFileName, '.');
rhMatFileNameNoExt = rhMatFileNameParts{1};

tempFileSubParts = strsplit(tempMatFileNameParts{1}, '_');
rhFileSubParts = strsplit(rhMatFileNameParts{1}, '_');

tempEndYear = str2num(tempFileSubParts{2});
rhEndYear = str2num(rhFileSubParts{2});

tempEndMonth = str2num(tempFileSubParts{3});
rhEndMonth = str2num(rhFileSubParts{3});

minEndYear = min(tempEndYear, rhEndYear);
minEndMonth = min(tempEndMonth, rhEndMonth);

while tempEndYear > minEndYear | tempEndMonth > minEndMonth
    tempEndInd = tempEndInd-1;

    tempMatFileName = tempMatFileNames{tempEndInd};
    tempMatFileNameParts = strsplit(tempMatFileName, '.');
    tempMatFileNameNoExt = tempMatFileNameParts{1};
    tempFileSubParts = strsplit(tempMatFileNameParts{1}, '_');

    tempEndYear = str2num(tempFileSubParts{2});
    tempEndMonth = str2num(tempFileSubParts{3});
end

while rhEndYear > minEndYear | rhEndMonth > minEndMonth
    rhEndInd = rhEndInd-1;

    rhMatFileName = rhMatFileNames{rhEndInd};
    rhMatFileNameParts = strsplit(rhMatFileName, '.');
    rhMatFileNameNoExt = rhMatFileNameParts{1};
    rhFileSubParts = strsplit(rhMatFileNameParts{1}, '_');

    rhEndYear = str2num(rhFileSubParts{2});
    rhEndMonth = str2num(rhFileSubParts{3});
end

folDataTarget = [dataDir, '/wb/', regridStr, '/', region, '/', num2str(maxStartYear) num2str(maxStartMonth) '01-' num2str(minEndYear) num2str(minEndMonth) '31'];
if ~isdir(folDataTarget)
    mkdir(folDataTarget);
else
    %continue;
end

wbCurDir = folDataTarget;

while tempStartInd <= tempEndInd & rhStartInd <= rhEndInd
    tempMatFileName = tempMatFileNames{tempStartInd};
    tempMatFileNameParts = strsplit(tempMatFileName, '.');
    tempMatFileNameNoExt = tempMatFileNameParts{1};

    rhMatFileName = rhMatFileNames{rhStartInd};
    rhMatFileNameParts = strsplit(rhMatFileName, '.');
    rhMatFileNameNoExt = rhMatFileNameParts{1};

    tempFileSubParts = strsplit(tempMatFileNameParts{1}, '_');
    rhFileSubParts = strsplit(rhMatFileNameParts{1}, '_');

    tempStartYear = str2num(tempFileSubParts{2});
    rhStartYear = str2num(rhFileSubParts{2});

    tempStartMonth = str2num(tempFileSubParts{3});
    rhStartMonth = str2num(rhFileSubParts{3});

    if tempStartYear ~= rhStartYear
        ['years do not match']
        return;
    else
        curYear = tempStartYear;
    end

    if tempStartMonth ~= rhStartMonth
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
        rhStartInd = rhStartInd + 1;
        continue;
    end

    tempCurFileName = [tempMatDirNames{tempStartInd}, '/', tempMatFileName];
    rhCurFileName = [rhMatDirNames{rhStartInd}, '/', rhMatFileName];

    load(tempCurFileName);
    load(rhCurFileName);

    eval(['tempLat = ' tempMatFileNameNoExt '{1};']);
    eval(['tempLon = ' tempMatFileNameNoExt '{2};']);
    eval(['tempData = ' tempMatFileNameNoExt '{3};']);
    eval(['clear ' tempMatFileNameNoExt ';']);

    eval(['rhLat = ' rhMatFileNameNoExt '{1};']);
    eval(['rhLon = ' rhMatFileNameNoExt '{2};']);
    eval(['rhData = ' rhMatFileNameNoExt '{3};']);
    eval(['clear ' rhMatFileNameNoExt ';']);
    
    tempStartInd = tempStartInd + 1;
    rhStartInd = rhStartInd + 1;

    if size(rhData,1) ~= size(tempData,1)
        ['lat dimensions do not match, skipping ' tempCurFileName]
        clear tempLat tempLon tempData;
        clear rhLat rhLon rhData;
        continue;
    end

    if size(rhData,2) ~= size(tempData,2)
        ['lon dimensions do not match, skipping ' tempCurFileName]
        clear tempLat tempLon tempData;
        clear rhLat rhLon rhData;
        continue;
    end

    if size(rhData,3) ~= size(tempData,3)
        ['data dimensions do not match, skipping ' tempCurFileName]
        clear tempLat tempLon tempData;
        clear rhLat rhLon rhData;
        continue;
    end

    wb = [];
    
    for xpos = 1:size(tempData,1)
        for ypos = 1:size(tempData,2)
            for d = 1:size(tempData,3)

                if tempData(xpos,ypos,d) > 200
                    T = (tempData(xpos,ypos,d) - 273.15);   % deg C
                else
                    T = (tempData(xpos,ypos,d));            % deg C
                end
                
                RH = rhData(xpos,ypos,d);               % percentage
                
                wb(xpos, ypos, d) = T * atan(0.151977 * sqrt(RH + 8.313659)) + ...
                                     atan(T + RH) - atan(RH - 1.676331) + ...
                                     0.00391838*(RH^(1.5)) * atan(0.023101*RH) - 4.686035;

            end

        end
    end

    ['processing ' wbCurDir '/' fileName]
    eval([fileName ' = {tempLat, tempLon, wb};']);
    save([wbCurDir, '/', fileName, '.mat'], fileName, '-v7.3');

    eval(['clear ', fileName], ';');
    clear tempLat tempLon tempData wb;
    clear rhLat rhLon rhData;

end






