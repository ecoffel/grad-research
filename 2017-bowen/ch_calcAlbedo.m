function ch_calcAlbedo(dataDir, regrid)

skipExisting = false;

regridStr = '/';
if regrid
    regridStr = '/regrid/';
end

% ncep reanalysis
% or cmip5
rsdscsVar = 'rsdt';
rsuscsVar = 'rsut';

rsdscsDirNames = dir([dataDir '/' rsdscsVar regridStr 'world']);
rsdscsDirIndices = [rsdscsDirNames(:).isdir];
rsdscsDirNames = {rsdscsDirNames(rsdscsDirIndices).name}';

rsuscsDirNames = dir([dataDir '/' rsuscsVar regridStr 'world']);
rsuscsDirIndices = [rsuscsDirNames(:).isdir];
rsuscsDirNames = {rsuscsDirNames(rsuscsDirIndices).name}';


if length(rsdscsDirNames) == 0
    rsdscsDirNames{1} = '';
end

if length(rsuscsDirNames) == 0
    rsuscsDirNames{1} = '';
end

yearIndex = 1;
monthIndex = 1;

rsdscsMatFileNames = {};
rsdscsMatDirNames = {};
rsuscsMatFileNames = {};
rsuscsMatDirNames = {};

for d = 1:length(rsdscsDirNames)
    if strcmp(rsdscsDirNames{d}, '.') | strcmp(rsdscsDirNames{d}, '..')
        continue;
    end
    
    rsdscsCurDir = [dataDir '/' rsdscsVar regridStr 'world/'  rsdscsDirNames{d}];
    
    if ~isdir(rsdscsCurDir)
        continue;
    end
    
    currsdscsMatFileNames = dir([rsdscsCurDir '/*.mat']);
    rsdscsMatFileNames = {rsdscsMatFileNames{:} currsdscsMatFileNames.name};
    
    for i = 1:length({currsdscsMatFileNames.name})
        rsdscsMatDirNames = {rsdscsMatDirNames{:} rsdscsCurDir};
    end

end

for d = 1:length(rsuscsDirNames)
    if strcmp(rsuscsDirNames{d}, '.') | strcmp(rsuscsDirNames{d}, '..')
        continue;
    end
    
    rsuscsCurDir = [dataDir  '/' rsuscsVar regridStr 'world/' rsuscsDirNames{d}];
    
    if ~isdir(rsuscsCurDir)
        continue;
    end
    
    currsuscsMatFileNames = dir([rsuscsCurDir, '/*.mat']);
    rsuscsMatFileNames = {rsuscsMatFileNames{:} currsuscsMatFileNames.name};
    
    for i = 1:length({currsuscsMatFileNames.name})
        rsuscsMatDirNames = {rsuscsMatDirNames{:} rsuscsCurDir};
    end
end

if length(rsdscsMatFileNames) == 0 | length(rsuscsMatFileNames) == 0
    return;
end

monthIndex = 1;

% find index of matching first file name
rsdscsStartInd = 1;
rsuscsStartInd = 1;

rsdscsEndInd = length(rsdscsMatFileNames);
rsuscsEndInd = length(rsuscsMatFileNames);

maxStartYear = -1;
maxStartMonth = -1;

minEndYear = -1;
minEndMonth = -1;

% find common start date
rsdscsMatFileName = rsdscsMatFileNames{1};
rsdscsMatFileNameParts = strsplit(rsdscsMatFileName, '.');
rsdscsMatFileNameNoExt = rsdscsMatFileNameParts{1};

rsuscsMatFileName = rsuscsMatFileNames{1};
rsuscsMatFileNameParts = strsplit(rsuscsMatFileName, '.');
rsuscsMatFileNameNoExt = rsuscsMatFileNameParts{1};

rsdscsFileSubParts = strsplit(rsdscsMatFileNameParts{1}, '_');
rsuscsFileSubParts = strsplit(rsuscsMatFileNameParts{1}, '_');

rsdscsStartYear = str2num(rsdscsFileSubParts{2});
rsuscsStartYear = str2num(rsuscsFileSubParts{2});

rsdscsStartMonth = str2num(rsdscsFileSubParts{3});
rsuscsStartMonth = str2num(rsuscsFileSubParts{3});

maxStartYear = max(rsdscsStartYear, rsuscsStartYear);
maxStartMonth = max(rsdscsStartMonth, rsuscsStartMonth);

while rsdscsStartYear < maxStartYear | rsdscsStartMonth < maxStartMonth
    rsdscsStartInd = rsdscsStartInd+1;

    rsdscsMatFileName = rsdscsMatFileNames{rsdscsStartInd};
    rsdscsMatFileNameParts = strsplit(rsdscsMatFileName, '.');
    rsdscsMatFileNameNoExt = rsdscsMatFileNameParts{1};
    rsdscsFileSubParts = strsplit(rsdscsMatFileNameParts{1}, '_');

    rsdscsStartYear = str2num(rsdscsFileSubParts{2});
    rsdscsStartMonth = str2num(rsdscsFileSubParts{3});
end

while rsuscsStartYear < maxStartYear | rsuscsStartMonth < maxStartMonth
    rsuscsStartInd = rsuscsStartInd+1;

    rsuscsMatFileName = rsuscsMatFileNames{rsuscsStartInd};
    rsuscsMatFileNameParts = strsplit(rsuscsMatFileName, '.');
    rsuscsMatFileNameNoExt = rsuscsMatFileNameParts{1};
    rsuscsFileSubParts = strsplit(rsuscsMatFileNameParts{1}, '_');

    rsuscsStartYear = str2num(rsuscsFileSubParts{2});
    rsuscsStartMonth = str2num(rsuscsFileSubParts{3});
end

% find common end date
rsdscsMatFileName = rsdscsMatFileNames{end};
rsdscsMatFileNameParts = strsplit(rsdscsMatFileName, '.');
rsdscsMatFileNameNoExt = rsdscsMatFileNameParts{1};

rsuscsMatFileName = rsuscsMatFileNames{end};
rsuscsMatFileNameParts = strsplit(rsuscsMatFileName, '.');
rsuscsMatFileNameNoExt = rsuscsMatFileNameParts{1};

rsdscsFileSubParts = strsplit(rsdscsMatFileNameParts{1}, '_');
rsuscsFileSubParts = strsplit(rsuscsMatFileNameParts{1}, '_');

rsdscsEndYear = str2num(rsdscsFileSubParts{2});
rsuscsEndYear = str2num(rsuscsFileSubParts{2});

rsdscsEndMonth = str2num(rsdscsFileSubParts{3});
rsuscsEndMonth = str2num(rsuscsFileSubParts{3});

minEndYear = min(rsdscsEndYear, rsuscsEndYear);
minEndMonth = min(rsdscsEndMonth, rsuscsEndMonth);

while rsdscsEndYear > minEndYear | rsdscsEndMonth > minEndMonth
    rsdscsEndInd = rsdscsEndInd-1;

    rsdscsMatFileName = rsdscsMatFileNames{rsdscsEndInd};
    rsdscsMatFileNameParts = strsplit(rsdscsMatFileName, '.');
    rsdscsMatFileNameNoExt = rsdscsMatFileNameParts{1};
    rsdscsFileSubParts = strsplit(rsdscsMatFileNameParts{1}, '_');

    rsdscsEndYear = str2num(rsdscsFileSubParts{2});
    rsdscsEndMonth = str2num(rsdscsFileSubParts{3});
end

while rsuscsEndYear > minEndYear | rsuscsEndMonth > minEndMonth
    rsuscsEndInd = rsuscsEndInd-1;

    rsuscsMatFileName = rsuscsMatFileNames{rsuscsEndInd};
    rsuscsMatFileNameParts = strsplit(rsuscsMatFileName, '.');
    rsuscsMatFileNameNoExt = rsuscsMatFileNameParts{1};
    rsuscsFileSubParts = strsplit(rsuscsMatFileNameParts{1}, '_');

    rsuscsEndYear = str2num(rsuscsFileSubParts{2});
    rsuscsEndMonth = str2num(rsuscsFileSubParts{3});
end

folDataTarget = [dataDir, '/albedo/regrid/world/', num2str(maxStartYear) num2str(maxStartMonth) '01-' num2str(minEndYear) num2str(minEndMonth) '31'];
if ~isdir(folDataTarget)
    mkdir(folDataTarget);
else
    %continue;
end

bowenCurDir = folDataTarget;

while rsdscsStartInd <= rsdscsEndInd & rsuscsStartInd <= rsuscsEndInd
    rsdscsMatFileName = rsdscsMatFileNames{rsdscsStartInd};
    rsdscsMatFileNameParts = strsplit(rsdscsMatFileName, '.');
    rsdscsMatFileNameNoExt = rsdscsMatFileNameParts{1};

    rsuscsMatFileName = rsuscsMatFileNames{rsuscsStartInd};
    rsuscsMatFileNameParts = strsplit(rsuscsMatFileName, '.');
    rsuscsMatFileNameNoExt = rsuscsMatFileNameParts{1};

    rsdscsFileSubParts = strsplit(rsdscsMatFileNameParts{1}, '_');
    rsuscsFileSubParts = strsplit(rsuscsMatFileNameParts{1}, '_');

    rsdscsStartYear = str2num(rsdscsFileSubParts{2});
    rsuscsStartYear = str2num(rsuscsFileSubParts{2});

    rsdscsStartMonth = str2num(rsdscsFileSubParts{3});
    rsuscsStartMonth = str2num(rsuscsFileSubParts{3});

    if rsdscsStartYear ~= rsuscsStartYear
        ['years do not match']
        return;
    else
        curYear = rsdscsStartYear;
    end

    if rsdscsStartMonth ~= rsuscsStartMonth
        ['months do not match']
        return;
    else
        curMonth = rsdscsStartMonth;
    end
    
    monthStr = '';
    if curMonth < 10
        monthStr = ['0', num2str(curMonth)];
    else
        monthStr = num2str(curMonth);
    end

    fileName = ['albedo_', num2str(curYear), '_' monthStr, '_01'];
    
    if skipExisting && exist([bowenCurDir '/' fileName '.mat'], 'file')
        ['skipping ' bowenCurDir '/' fileName '.mat']
        rsdscsStartInd = rsdscsStartInd + 1;
        rsuscsStartInd = rsuscsStartInd + 1;
        continue;
    end

    rsdscsCurFileName = [rsdscsMatDirNames{rsdscsStartInd}, '/', rsdscsMatFileName];
    rsuscsCurFileName = [rsuscsMatDirNames{rsuscsStartInd}, '/', rsuscsMatFileName];

    load(rsdscsCurFileName);
    load(rsuscsCurFileName);

    eval(['rsdscsLat = ' rsdscsMatFileNameNoExt '{1};']);
    eval(['rsdscsLon = ' rsdscsMatFileNameNoExt '{2};']);
    eval(['rsdscsData = ' rsdscsMatFileNameNoExt '{3};']);
    eval(['clear ' rsdscsMatFileNameNoExt ';']);

    eval(['rsuscsLat = ' rsuscsMatFileNameNoExt '{1};']);
    eval(['rsuscsLon = ' rsuscsMatFileNameNoExt '{2};']);
    eval(['rsuscsData = ' rsuscsMatFileNameNoExt '{3};']);
    eval(['clear ' rsuscsMatFileNameNoExt ';']);

    
    rsdscsStartInd = rsdscsStartInd + 1;
    rsuscsStartInd = rsuscsStartInd + 1;
    
    if size(rsuscsData,1) ~= size(rsdscsData,1)
        ['lat dimensions do not match, skipping ' rsdscsCurFileName]
        clear rsdscsLat rsdscsLon rsdscsData;
        clear rsuscsLat rsuscsLon rsuscsData;
        continue;
    end

    if size(rsuscsData,2) ~= size(rsdscsData,2)
        ['lon dimensions do not match, skipping ' rsdscsCurFileName]
        clear rsdscsLat rsdscsLon rsdscsData;
        clear rsuscsLat rsuscsLon rsuscsData;
        continue;
    end

    if size(rsuscsData,3) ~= size(rsdscsData,3)
        ['data dimensions do not match, skipping ' rsdscsCurFileName]
        clear rsdscsLat rsdscsLon rsdscsData;
        clear rsuscsLat rsuscsLon rsuscsData;
        continue;
    end

    albedo = [];
    
    for xpos = 1:size(rsdscsData,1)
        for ypos = 1:size(rsdscsData,2)
            for d = 1:size(rsdscsData,3)

                rsdscs = rsdscsData(xpos,ypos,d);
                rsuscs = rsuscsData(xpos,ypos,d);

                albedo(xpos, ypos, d) = rsuscs / rsdscs;

            end
        end
    end

    
    ['processing ' bowenCurDir '/' fileName]
    eval([fileName ' = {rsdscsLat, rsdscsLon, albedo};']);
    save([bowenCurDir, '/', fileName, '.mat'], fileName, '-v7.3');

    eval(['clear ', fileName], ';');
    clear rsdscsLat rsdscsLon rsdscsData albedo;
    clear rsuscsLat rsuscsLon rsuscsData;

end


