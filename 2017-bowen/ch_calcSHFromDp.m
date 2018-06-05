function ch_calcSHFromDp(dataDir, regrid)

skipExisting = true;

regridStr = '/';
if regrid
    regridStr = '/regrid/';
end

if length(strfind(dataDir, 'era')) > 0
    dpVar = 'd2m';
    spVar = 'sp';
end

dpDirNames = dir([dataDir '/' dpVar regridStr 'world']);
dpDirIndices = [dpDirNames(:).isdir];
dpDirNames = {dpDirNames(dpDirIndices).name}';

spDirNames = dir([dataDir '/' spVar regridStr 'world']);
spDirIndices = [spDirNames(:).isdir];
spDirNames = {spDirNames(spDirIndices).name}';


if length(dpDirNames) == 0
    dpDirNames{1} = '';
end

if length(spDirNames) == 0
    spDirNames{1} = '';
end

yearIndex = 1;
monthIndex = 1;

dpMatFileNames = {};
dpMatDirNames = {};
spMatFileNames = {};
spMatDirNames = {};

for d = 1:length(dpDirNames)
    if strcmp(dpDirNames{d}, '.') | strcmp(dpDirNames{d}, '..')
        continue;
    end
    
    dpCurDir = [dataDir '/' dpVar regridStr 'world/'  dpDirNames{d}];
    
    if ~isdir(dpCurDir)
        continue;
    end
    
    curDpMatFileNames = dir([dpCurDir '/*.mat']);
    dpMatFileNames = {dpMatFileNames{:} curDpMatFileNames.name};
    
    for i = 1:length({curDpMatFileNames.name})
        dpMatDirNames = {dpMatDirNames{:} dpCurDir};
    end

end

for d = 1:length(spDirNames)
    if strcmp(spDirNames{d}, '.') | strcmp(spDirNames{d}, '..')
        continue;
    end
    
    spCurDir = [dataDir  '/' spVar regridStr 'world/' spDirNames{d}];
    
    if ~isdir(spCurDir)
        continue;
    end
    
    curSpMatFileNames = dir([spCurDir, '/*.mat']);
    spMatFileNames = {spMatFileNames{:} curSpMatFileNames.name};
    
    for i = 1:length({curSpMatFileNames.name})
        spMatDirNames = {spMatDirNames{:} spCurDir};
    end
end

if length(dpMatFileNames) == 0 | length(spMatFileNames) == 0
    return;
end

monthIndex = 1;

% find index of matching first file name
dpStartInd = 1;
spStartInd = 1;

dpEndInd = length(dpMatFileNames);
spEndInd = length(spMatFileNames);

maxStartYear = -1;
maxStartMonth = -1;

minEndYear = -1;
minEndMonth = -1;

% find common start date
dpMatFileName = dpMatFileNames{1};
dpMatFileNameParts = strsplit(dpMatFileName, '.');
dpMatFileNameNoExt = dpMatFileNameParts{1};

spMatFileName = spMatFileNames{1};
spMatFileNameParts = strsplit(spMatFileName, '.');
spMatFileNameNoExt = spMatFileNameParts{1};

dpFileSubParts = strsplit(dpMatFileNameParts{1}, '_');
spFileSubParts = strsplit(spMatFileNameParts{1}, '_');

dpStartYear = str2num(dpFileSubParts{2});
spStartYear = str2num(spFileSubParts{2});

dpStartMonth = str2num(dpFileSubParts{3});
spStartMonth = str2num(spFileSubParts{3});

maxStartYear = max(dpStartYear, spStartYear);
maxStartMonth = max(dpStartMonth, spStartMonth);

while dpStartYear < maxStartYear | dpStartMonth < maxStartMonth
    dpStartInd = dpStartInd+1;

    dpMatFileName = dpMatFileNames{dpStartInd};
    dpMatFileNameParts = strsplit(dpMatFileName, '.');
    dpMatFileNameNoExt = dpMatFileNameParts{1};
    dpFileSubParts = strsplit(dpMatFileNameParts{1}, '_');

    dpStartYear = str2num(dpFileSubParts{2});
    dpStartMonth = str2num(dpFileSubParts{3});
end

while spStartYear < maxStartYear | spStartMonth < maxStartMonth
    spStartInd = spStartInd+1;

    spMatFileName = spMatFileNames{spStartInd};
    spMatFileNameParts = strsplit(spMatFileName, '.');
    spMatFileNameNoExt = spMatFileNameParts{1};
    spFileSubParts = strsplit(spMatFileNameParts{1}, '_');

    spStartYear = str2num(spFileSubParts{2});
    spStartMonth = str2num(spFileSubParts{3});
end

% find common end date
dpMatFileName = dpMatFileNames{end};
dpMatFileNameParts = strsplit(dpMatFileName, '.');
dpMatFileNameNoExt = dpMatFileNameParts{1};

spMatFileName = spMatFileNames{end};
spMatFileNameParts = strsplit(spMatFileName, '.');
spMatFileNameNoExt = spMatFileNameParts{1};

dpFileSubParts = strsplit(dpMatFileNameParts{1}, '_');
spFileSubParts = strsplit(spMatFileNameParts{1}, '_');

dpEndYear = str2num(dpFileSubParts{2});
spEndYear = str2num(spFileSubParts{2});

dpEndMonth = str2num(dpFileSubParts{3});
spEndMonth = str2num(spFileSubParts{3});

minEndYear = min(dpEndYear, spEndYear);
minEndMonth = min(dpEndMonth, spEndMonth);

while dpEndYear > minEndYear | dpEndMonth > minEndMonth
    dpEndInd = dpEndInd-1;

    dpMatFileName = dpMatFileNames{dpEndInd};
    dpMatFileNameParts = strsplit(dpMatFileName, '.');
    dpMatFileNameNoExt = dpMatFileNameParts{1};
    dpFileSubParts = strsplit(dpMatFileNameParts{1}, '_');

    dpEndYear = str2num(dpFileSubParts{2});
    dpEndMonth = str2num(dpFileSubParts{3});
end

while spEndYear > minEndYear | spEndMonth > minEndMonth
    spEndInd = spEndInd-1;

    spMatFileName = spMatFileNames{spEndInd};
    spMatFileNameParts = strsplit(spMatFileName, '.');
    spMatFileNameNoExt = spMatFileNameParts{1};
    spFileSubParts = strsplit(spMatFileNameParts{1}, '_');

    spEndYear = str2num(spFileSubParts{2});
    spEndMonth = str2num(spFileSubParts{3});
end

folDataTarget = [dataDir, '/huss/regrid/world/', num2str(maxStartYear) num2str(maxStartMonth) '01-' num2str(minEndYear) num2str(minEndMonth) '31'];
if ~isdir(folDataTarget)
    mkdir(folDataTarget);
else
    %continue;
end

hussCurDir = folDataTarget;

while dpStartInd <= dpEndInd & spStartInd <= spEndInd
    dpMatFileName = dpMatFileNames{dpStartInd};
    dpMatFileNameParts = strsplit(dpMatFileName, '.');
    dpMatFileNameNoExt = dpMatFileNameParts{1};

    spMatFileName = spMatFileNames{spStartInd};
    spMatFileNameParts = strsplit(spMatFileName, '.');
    spMatFileNameNoExt = spMatFileNameParts{1};

    dpFileSubParts = strsplit(dpMatFileNameParts{1}, '_');
    spFileSubParts = strsplit(spMatFileNameParts{1}, '_');

    dpStartYear = str2num(dpFileSubParts{2});
    spStartYear = str2num(spFileSubParts{2});

    dpStartMonth = str2num(dpFileSubParts{3});
    spStartMonth = str2num(spFileSubParts{3});

    if dpStartYear ~= spStartYear
        ['years do not match']
        return;
    else
        curYear = dpStartYear;
    end

    if dpStartMonth ~= spStartMonth
        ['months do not match']
        return;
    else
        curMonth = dpStartMonth;
    end
    
    monthStr = '';
    if curMonth < 10
        monthStr = ['0', num2str(curMonth)];
    else
        monthStr = num2str(curMonth);
    end

    fileName = ['huss_', num2str(curYear), '_' monthStr, '_01'];
    
    if skipExisting && exist([hussCurDir '/' fileName '.mat'], 'file')
        ['skipping ' hussCurDir '/' fileName '.mat']
        dpStartInd = dpStartInd + 1;
        spStartInd = spStartInd + 1;
        continue;
    end

    dpCurFileName = [dpMatDirNames{dpStartInd}, '/', dpMatFileName];
    spCurFileName = [spMatDirNames{spStartInd}, '/', spMatFileName];

    load(dpCurFileName);
    load(spCurFileName);

    eval(['dpLat = ' dpMatFileNameNoExt '{1};']);
    eval(['dpLon = ' dpMatFileNameNoExt '{2};']);
    eval(['dpData = ' dpMatFileNameNoExt '{3};']);
    eval(['clear ' dpMatFileNameNoExt ';']);

    eval(['spLat = ' spMatFileNameNoExt '{1};']);
    eval(['spLon = ' spMatFileNameNoExt '{2};']);
    eval(['spData = ' spMatFileNameNoExt '{3};']);
    eval(['clear ' spMatFileNameNoExt ';']);

    dpStartInd = dpStartInd + 1;
    spStartInd = spStartInd + 1;
    
    if size(spData,1) ~= size(dpData,1)
        ['lat dimensions do not match, skipping ' dpCurFileName]
        clear dpLat dpLon dpData;
        clear spLat spLon spData;
        continue;
    end

    if size(spData,2) ~= size(dpData,2)
        ['lon dimensions do not match, skipping ' dpCurFileName]
        clear dpLat dpLon dpData;
        clear spLat spLon spData;
        continue;
    end

    if size(spData,3) ~= size(dpData,3)
        ['data dimensions do not match, skipping ' dpCurFileName]
        clear dpLat dpLon dpData;
        clear spLat spLon spData;
        continue;
    end

    huss = [];
    
    for xpos = 1:size(dpData,1)
        for ypos = 1:size(dpData,2)
            for d = 1:size(dpData,3)

                % deg c
                dp = dpData(xpos,ypos,d) - 273.15;
                
                % mb
                sp = spData(xpos,ypos,d) * 0.01;

                e = 6.112 * exp((17.67 * dp)/(dp + 243.5));
                huss(xpos, ypos, d) = (.622*e)/(sp-(0.378*e));

            end
        end
    end

    
    ['processing ' hussCurDir '/' fileName]
    eval([fileName ' = {dpLat, dpLon, huss};']);
    save([hussCurDir, '/', fileName, '.mat'], fileName, '-v7.3');

    eval(['clear ', fileName], ';');
    clear dpLat dpLon dpData;
    clear spLat spLon spData huss;

end


