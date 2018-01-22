function ch_calcEF(dataDir, regrid)

skipExisting = true;

regridStr = '/';
if regrid
    regridStr = '/regrid/';
end

% ncep reanalysis
if length(strfind(dataDir, 'ncep')) > 0
    hfssVar = 'shtfl';
    hflsVar = 'lhtfl';
elseif length(strfind(dataDir, 'era')) > 0
    hfssVar = 'sshf';
    hflsVar = 'slhf';
else
    % or cmip5
    hfssVar = 'hfss';
    hflsVar = 'hfls';
end

hfssDirNames = dir([dataDir '/' hfssVar regridStr 'world']);
hfssDirIndices = [hfssDirNames(:).isdir];
hfssDirNames = {hfssDirNames(hfssDirIndices).name}';

hflsDirNames = dir([dataDir '/' hflsVar regridStr 'world']);
hflsDirIndices = [hflsDirNames(:).isdir];
hflsDirNames = {hflsDirNames(hflsDirIndices).name}';


if length(hfssDirNames) == 0
    hfssDirNames{1} = '';
end

if length(hflsDirNames) == 0
    hflsDirNames{1} = '';
end

yearIndex = 1;
monthIndex = 1;

hfssMatFileNames = {};
hfssMatDirNames = {};
hflsMatFileNames = {};
hflsMatDirNames = {};

for d = 1:length(hfssDirNames)
    if strcmp(hfssDirNames{d}, '.') | strcmp(hfssDirNames{d}, '..')
        continue;
    end
    
    hfssCurDir = [dataDir '/' hfssVar regridStr 'world/'  hfssDirNames{d}];
    
    if ~isdir(hfssCurDir)
        continue;
    end
    
    curHfssMatFileNames = dir([hfssCurDir '/*.mat']);
    hfssMatFileNames = {hfssMatFileNames{:} curHfssMatFileNames.name};
    
    for i = 1:length({curHfssMatFileNames.name})
        hfssMatDirNames = {hfssMatDirNames{:} hfssCurDir};
    end

end

for d = 1:length(hflsDirNames)
    if strcmp(hflsDirNames{d}, '.') | strcmp(hflsDirNames{d}, '..')
        continue;
    end
    
    hflsCurDir = [dataDir  '/' hflsVar regridStr 'world/' hflsDirNames{d}];
    
    if ~isdir(hflsCurDir)
        continue;
    end
    
    curHflsMatFileNames = dir([hflsCurDir, '/*.mat']);
    hflsMatFileNames = {hflsMatFileNames{:} curHflsMatFileNames.name};
    
    for i = 1:length({curHflsMatFileNames.name})
        hflsMatDirNames = {hflsMatDirNames{:} hflsCurDir};
    end
end

if length(hfssMatFileNames) == 0 | length(hflsMatFileNames) == 0
    return;
end

monthIndex = 1;

% find index of matching first file name
hfssStartInd = 1;
hflsStartInd = 1;

hfssEndInd = length(hfssMatFileNames);
hflsEndInd = length(hflsMatFileNames);

maxStartYear = -1;
maxStartMonth = -1;

minEndYear = -1;
minEndMonth = -1;

% find common start date
hfssMatFileName = hfssMatFileNames{1};
hfssMatFileNameParts = strsplit(hfssMatFileName, '.');
hfssMatFileNameNoExt = hfssMatFileNameParts{1};

hflsMatFileName = hflsMatFileNames{1};
hflsMatFileNameParts = strsplit(hflsMatFileName, '.');
hflsMatFileNameNoExt = hflsMatFileNameParts{1};

hfssFileSubParts = strsplit(hfssMatFileNameParts{1}, '_');
hflsFileSubParts = strsplit(hflsMatFileNameParts{1}, '_');

hfssStartYear = str2num(hfssFileSubParts{2});
hflsStartYear = str2num(hflsFileSubParts{2});

hfssStartMonth = str2num(hfssFileSubParts{3});
hflsStartMonth = str2num(hflsFileSubParts{3});

maxStartYear = max(hfssStartYear, hflsStartYear);
maxStartMonth = max(hfssStartMonth, hflsStartMonth);

while hfssStartYear < maxStartYear | hfssStartMonth < maxStartMonth
    hfssStartInd = hfssStartInd+1;

    hfssMatFileName = hfssMatFileNames{hfssStartInd};
    hfssMatFileNameParts = strsplit(hfssMatFileName, '.');
    hfssMatFileNameNoExt = hfssMatFileNameParts{1};
    hfssFileSubParts = strsplit(hfssMatFileNameParts{1}, '_');

    hfssStartYear = str2num(hfssFileSubParts{2});
    hfssStartMonth = str2num(hfssFileSubParts{3});
end

while hflsStartYear < maxStartYear | hflsStartMonth < maxStartMonth
    hflsStartInd = hflsStartInd+1;

    hflsMatFileName = hflsMatFileNames{hflsStartInd};
    hflsMatFileNameParts = strsplit(hflsMatFileName, '.');
    hflsMatFileNameNoExt = hflsMatFileNameParts{1};
    hflsFileSubParts = strsplit(hflsMatFileNameParts{1}, '_');

    hflsStartYear = str2num(hflsFileSubParts{2});
    hflsStartMonth = str2num(hflsFileSubParts{3});
end

% find common end date
hfssMatFileName = hfssMatFileNames{end};
hfssMatFileNameParts = strsplit(hfssMatFileName, '.');
hfssMatFileNameNoExt = hfssMatFileNameParts{1};

hflsMatFileName = hflsMatFileNames{end};
hflsMatFileNameParts = strsplit(hflsMatFileName, '.');
hflsMatFileNameNoExt = hflsMatFileNameParts{1};

hfssFileSubParts = strsplit(hfssMatFileNameParts{1}, '_');
hflsFileSubParts = strsplit(hflsMatFileNameParts{1}, '_');

hfssEndYear = str2num(hfssFileSubParts{2});
hflsEndYear = str2num(hflsFileSubParts{2});

hfssEndMonth = str2num(hfssFileSubParts{3});
hflsEndMonth = str2num(hflsFileSubParts{3});

minEndYear = min(hfssEndYear, hflsEndYear);
minEndMonth = min(hfssEndMonth, hflsEndMonth);

while hfssEndYear > minEndYear | hfssEndMonth > minEndMonth
    hfssEndInd = hfssEndInd-1;

    hfssMatFileName = hfssMatFileNames{hfssEndInd};
    hfssMatFileNameParts = strsplit(hfssMatFileName, '.');
    hfssMatFileNameNoExt = hfssMatFileNameParts{1};
    hfssFileSubParts = strsplit(hfssMatFileNameParts{1}, '_');

    hfssEndYear = str2num(hfssFileSubParts{2});
    hfssEndMonth = str2num(hfssFileSubParts{3});
end

while hflsEndYear > minEndYear | hflsEndMonth > minEndMonth
    hflsEndInd = hflsEndInd-1;

    hflsMatFileName = hflsMatFileNames{hflsEndInd};
    hflsMatFileNameParts = strsplit(hflsMatFileName, '.');
    hflsMatFileNameNoExt = hflsMatFileNameParts{1};
    hflsFileSubParts = strsplit(hflsMatFileNameParts{1}, '_');

    hflsEndYear = str2num(hflsFileSubParts{2});
    hflsEndMonth = str2num(hflsFileSubParts{3});
end

folDataTarget = [dataDir, '/EF/regrid/world/', num2str(maxStartYear) num2str(maxStartMonth) '01-' num2str(minEndYear) num2str(minEndMonth) '31'];
if ~isdir(folDataTarget)
    mkdir(folDataTarget);
else
    %continue;
end

bowenCurDir = folDataTarget;

while hfssStartInd <= hfssEndInd & hflsStartInd <= hflsEndInd
    hfssMatFileName = hfssMatFileNames{hfssStartInd};
    hfssMatFileNameParts = strsplit(hfssMatFileName, '.');
    hfssMatFileNameNoExt = hfssMatFileNameParts{1};

    hflsMatFileName = hflsMatFileNames{hflsStartInd};
    hflsMatFileNameParts = strsplit(hflsMatFileName, '.');
    hflsMatFileNameNoExt = hflsMatFileNameParts{1};

    hfssFileSubParts = strsplit(hfssMatFileNameParts{1}, '_');
    hflsFileSubParts = strsplit(hflsMatFileNameParts{1}, '_');

    hfssStartYear = str2num(hfssFileSubParts{2});
    hflsStartYear = str2num(hflsFileSubParts{2});

    hfssStartMonth = str2num(hfssFileSubParts{3});
    hflsStartMonth = str2num(hflsFileSubParts{3});

    if hfssStartYear ~= hflsStartYear
        ['years do not match']
        return;
    else
        curYear = hfssStartYear;
    end

    if hfssStartMonth ~= hflsStartMonth
        ['months do not match']
        return;
    else
        curMonth = hfssStartMonth;
    end
    
    monthStr = '';
    if curMonth < 10
        monthStr = ['0', num2str(curMonth)];
    else
        monthStr = num2str(curMonth);
    end

    fileName = ['ef_', num2str(curYear), '_' monthStr, '_01'];
    
    if skipExisting && exist([bowenCurDir '/' fileName '.mat'], 'file')
        ['skipping ' bowenCurDir '/' fileName '.mat']
        hfssStartInd = hfssStartInd + 1;
        hflsStartInd = hflsStartInd + 1;
        continue;
    end

    hfssCurFileName = [hfssMatDirNames{hfssStartInd}, '/', hfssMatFileName];
    hflsCurFileName = [hflsMatDirNames{hflsStartInd}, '/', hflsMatFileName];

    load(hfssCurFileName);
    load(hflsCurFileName);

    eval(['hfssLat = ' hfssMatFileNameNoExt '{1};']);
    eval(['hfssLon = ' hfssMatFileNameNoExt '{2};']);
    eval(['hfssData = ' hfssMatFileNameNoExt '{3};']);
    eval(['clear ' hfssMatFileNameNoExt ';']);

    eval(['hflsLat = ' hflsMatFileNameNoExt '{1};']);
    eval(['hflsLon = ' hflsMatFileNameNoExt '{2};']);
    eval(['hflsData = ' hflsMatFileNameNoExt '{3};']);
    eval(['clear ' hflsMatFileNameNoExt ';']);

    
    hfssStartInd = hfssStartInd + 1;
    hflsStartInd = hflsStartInd + 1;
    
    if size(hflsData,1) ~= size(hfssData,1)
        ['lat dimensions do not match, skipping ' hfssCurFileName]
        clear hfssLat hfssLon hfssData;
        clear hflsLat hflsLon hflsData;
        continue;
    end

    if size(hflsData,2) ~= size(hfssData,2)
        ['lon dimensions do not match, skipping ' hfssCurFileName]
        clear hfssLat hfssLon hfssData;
        clear hflsLat hflsLon hflsData;
        continue;
    end

    if size(hflsData,3) ~= size(hfssData,3)
        ['data dimensions do not match, skipping ' hfssCurFileName]
        clear hfssLat hfssLon hfssData;
        clear hflsLat hflsLon hflsData;
        continue;
    end

    ef = [];
    
    for xpos = 1:size(hfssData,1)
        for ypos = 1:size(hfssData,2)
            for d = 1:size(hfssData,3)

                hfss = hfssData(xpos,ypos,d);
                hfls = hflsData(xpos,ypos,d);

                ef(xpos, ypos, d) = hfls / (hfss+hfls);

            end
        end
    end

    
    ['processing ' bowenCurDir '/' fileName]
    eval([fileName ' = {hfssLat, hfssLon, ef};']);
    save([bowenCurDir, '/', fileName, '.mat'], fileName, '-v7.3');

    eval(['clear ', fileName], ';');
    clear hfssLat hfssLon hfssData ef;
    clear hflsLat hflsLon hflsData;

end


