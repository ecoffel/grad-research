function ch_netRad(dataDir, regrid)

skipExisting = true;

regridStr = '/';
if regrid
    regridStr = '/regrid/';
end

% or cmip5
rsdsVar = 'rsds';
rsusVar = 'rsus';
rldsVar = 'rlds';
rlusVar = 'rlus';

rsdsDirNames = dir([dataDir '/' rsdsVar regridStr 'world']);
rsdsDirIndices = [rsdsDirNames(:).isdir];
rsdsDirNames = {rsdsDirNames(rsdsDirIndices).name}';

rsusDirNames = dir([dataDir '/' rsusVar regridStr 'world']);
rsusDirIndices = [rsusDirNames(:).isdir];
rsusDirNames = {rsusDirNames(rsusDirIndices).name}';

rldsDirNames = dir([dataDir '/' rldsVar regridStr 'world']);
rldsDirIndices = [rldsDirNames(:).isdir];
rldsDirNames = {rldsDirNames(rldsDirIndices).name}';

rlusDirNames = dir([dataDir '/' rlusVar regridStr 'world']);
rlusDirIndices = [rlusDirNames(:).isdir];
rlusDirNames = {rlusDirNames(rlusDirIndices).name}';


if length(rsdsDirNames) == 0
    rsdsDirNames{1} = '';
end

if length(rsusDirNames) == 0
    rsusDirNames{1} = '';
end

if length(rldsDirNames) == 0
    rldsDirNames{1} = '';
end

if length(rlusDirNames) == 0
    rlusDirNames{1} = '';
end

yearIndex = 1;
monthIndex = 1;

rsdsMatFileNames = {};
rsdsMatDirNames = {};
rsusMatFileNames = {};
rsusMatDirNames = {};
rldsMatFileNames = {};
rldsMatDirNames = {};
rlusMatFileNames = {};
rlusMatDirNames = {};

for d = 1:length(rsdsDirNames)
    if strcmp(rsdsDirNames{d}, '.') | strcmp(rsdsDirNames{d}, '..')
        continue;
    end
    
    rsdsCurDir = [dataDir '/' rsdsVar regridStr 'world/'  rsdsDirNames{d}];
    
    if ~isdir(rsdsCurDir)
        continue;
    end
    
    currsdsMatFileNames = dir([rsdsCurDir '/*.mat']);
    rsdsMatFileNames = {rsdsMatFileNames{:} currsdsMatFileNames.name};
    
    for i = 1:length({currsdsMatFileNames.name})
        rsdsMatDirNames = {rsdsMatDirNames{:} rsdsCurDir};
    end

end

for d = 1:length(rsusDirNames)
    if strcmp(rsusDirNames{d}, '.') | strcmp(rsusDirNames{d}, '..')
        continue;
    end
    
    rsusCurDir = [dataDir  '/' rsusVar regridStr 'world/' rsusDirNames{d}];
    
    if ~isdir(rsusCurDir)
        continue;
    end
    
    currsusMatFileNames = dir([rsusCurDir, '/*.mat']);
    rsusMatFileNames = {rsusMatFileNames{:} currsusMatFileNames.name};
    
    for i = 1:length({currsusMatFileNames.name})
        rsusMatDirNames = {rsusMatDirNames{:} rsusCurDir};
    end
end

for d = 1:length(rldsDirNames)
    if strcmp(rldsDirNames{d}, '.') | strcmp(rldsDirNames{d}, '..')
        continue;
    end
    
    rldsCurDir = [dataDir '/' rldsVar regridStr 'world/'  rldsDirNames{d}];
    
    if ~isdir(rldsCurDir)
        continue;
    end
    
    currldsMatFileNames = dir([rldsCurDir '/*.mat']);
    rldsMatFileNames = {rldsMatFileNames{:} currldsMatFileNames.name};
    
    for i = 1:length({currldsMatFileNames.name})
        rldsMatDirNames = {rldsMatDirNames{:} rldsCurDir};
    end

end

for d = 1:length(rlusDirNames)
    if strcmp(rlusDirNames{d}, '.') | strcmp(rlusDirNames{d}, '..')
        continue;
    end
    
    rlusCurDir = [dataDir  '/' rlusVar regridStr 'world/' rlusDirNames{d}];
    
    if ~isdir(rlusCurDir)
        continue;
    end
    
    currlusMatFileNames = dir([rlusCurDir, '/*.mat']);
    rlusMatFileNames = {rlusMatFileNames{:} currlusMatFileNames.name};
    
    for i = 1:length({currlusMatFileNames.name})
        rlusMatDirNames = {rlusMatDirNames{:} rlusCurDir};
    end
end

if length(rsdsMatFileNames) == 0 | length(rsusMatFileNames) == 0 ...
   | length(rldsMatFileNames) == 0 | length(rlusMatFileNames) == 0
    return;
end

monthIndex = 1;

% find index of matching first file name
rsdsStartInd = 1;
rsusStartInd = 1;
rldsStartInd = 1;
rlusStartInd = 1;

rsdsEndInd = length(rsdsMatFileNames);
rsusEndInd = length(rsusMatFileNames);
rldsEndInd = length(rldsMatFileNames);
rlusEndInd = length(rlusMatFileNames);

maxStartYear = -1;
maxStartMonth = -1;

minEndYear = -1;
minEndMonth = -1;

% find common start date
rsdsMatFileName = rsdsMatFileNames{1};
rsdsMatFileNameParts = strsplit(rsdsMatFileName, '.');
rsdsMatFileNameNoExt = rsdsMatFileNameParts{1};

rsusMatFileName = rsusMatFileNames{1};
rsusMatFileNameParts = strsplit(rsusMatFileName, '.');
rsusMatFileNameNoExt = rsusMatFileNameParts{1};

rldsMatFileName = rldsMatFileNames{1};
rldsMatFileNameParts = strsplit(rldsMatFileName, '.');
rldsMatFileNameNoExt = rldsMatFileNameParts{1};

rlusMatFileName = rlusMatFileNames{1};
rlusMatFileNameParts = strsplit(rlusMatFileName, '.');
rlusMatFileNameNoExt = rlusMatFileNameParts{1};




rsdsFileSubParts = strsplit(rsdsMatFileNameParts{1}, '_');
rsusFileSubParts = strsplit(rsusMatFileNameParts{1}, '_');
rldsFileSubParts = strsplit(rldsMatFileNameParts{1}, '_');
rlusFileSubParts = strsplit(rlusMatFileNameParts{1}, '_');

rsdsStartYear = str2num(rsdsFileSubParts{2});
rsusStartYear = str2num(rsusFileSubParts{2});
rldsStartYear = str2num(rldsFileSubParts{2});
rlusStartYear = str2num(rlusFileSubParts{2});

rsdsStartMonth = str2num(rsdsFileSubParts{3});
rsusStartMonth = str2num(rsusFileSubParts{3});
rldsStartMonth = str2num(rldsFileSubParts{3});
rlusStartMonth = str2num(rlusFileSubParts{3});

maxStartYear = max(rsdsStartYear, max(rsusStartYear, max(rlusStartYear, rldsStartYear)));
maxStartMonth = max(rsdsStartMonth, max(rsusStartMonth, max(rldsStartMonth, rlusStartMonth)));

while rsdsStartYear < maxStartYear | rsdsStartMonth < maxStartMonth
    rsdsStartInd = rsdsStartInd+1;

    rsdsMatFileName = rsdsMatFileNames{rsdsStartInd};
    rsdsMatFileNameParts = strsplit(rsdsMatFileName, '.');
    rsdsMatFileNameNoExt = rsdsMatFileNameParts{1};
    rsdsFileSubParts = strsplit(rsdsMatFileNameParts{1}, '_');

    rsdsStartYear = str2num(rsdsFileSubParts{2});
    rsdsStartMonth = str2num(rsdsFileSubParts{3});
end

while rsusStartYear < maxStartYear | rsusStartMonth < maxStartMonth
    rsusStartInd = rsusStartInd+1;

    rsusMatFileName = rsusMatFileNames{rsusStartInd};
    rsusMatFileNameParts = strsplit(rsusMatFileName, '.');
    rsusMatFileNameNoExt = rsusMatFileNameParts{1};
    rsusFileSubParts = strsplit(rsusMatFileNameParts{1}, '_');

    rsusStartYear = str2num(rsusFileSubParts{2});
    rsusStartMonth = str2num(rsusFileSubParts{3});
end

while rldsStartYear < maxStartYear | rldsStartMonth < maxStartMonth
    rldsStartInd = rldsStartInd+1;

    rldsMatFileName = rldsMatFileNames{rldsStartInd};
    rldsMatFileNameParts = strsplit(rldsMatFileName, '.');
    rldsMatFileNameNoExt = rldsMatFileNameParts{1};
    rldsFileSubParts = strsplit(rldsMatFileNameParts{1}, '_');

    rldsStartYear = str2num(rldsFileSubParts{2});
    rldsStartMonth = str2num(rldsFileSubParts{3});
end

while rlusStartYear < maxStartYear | rlusStartMonth < maxStartMonth
    rlusStartInd = rlusStartInd+1;

    rlusMatFileName = rlusMatFileNames{rlusStartInd};
    rlusMatFileNameParts = strsplit(rlusMatFileName, '.');
    rlusMatFileNameNoExt = rlusMatFileNameParts{1};
    rlusFileSubParts = strsplit(rlusMatFileNameParts{1}, '_');

    rlusStartYear = str2num(rlusFileSubParts{2});
    rlusStartMonth = str2num(rlusFileSubParts{3});
end

% find common end date
rsdsMatFileName = rsdsMatFileNames{end};
rsdsMatFileNameParts = strsplit(rsdsMatFileName, '.');
rsdsMatFileNameNoExt = rsdsMatFileNameParts{1};

rsusMatFileName = rsusMatFileNames{end};
rsusMatFileNameParts = strsplit(rsusMatFileName, '.');
rsusMatFileNameNoExt = rsusMatFileNameParts{1};

rldsMatFileName = rldsMatFileNames{end};
rldsMatFileNameParts = strsplit(rldsMatFileName, '.');
rldsMatFileNameNoExt = rldsMatFileNameParts{1};

rlusMatFileName = rlusMatFileNames{end};
rlusMatFileNameParts = strsplit(rlusMatFileName, '.');
rlusMatFileNameNoExt = rlusMatFileNameParts{1};

rsdsFileSubParts = strsplit(rsdsMatFileNameParts{1}, '_');
rsusFileSubParts = strsplit(rsusMatFileNameParts{1}, '_');
rldsFileSubParts = strsplit(rldsMatFileNameParts{1}, '_');
rlusFileSubParts = strsplit(rlusMatFileNameParts{1}, '_');

rsdsEndYear = str2num(rsdsFileSubParts{2});
rsusEndYear = str2num(rsusFileSubParts{2});
rldsEndYear = str2num(rldsFileSubParts{2});
rlusEndYear = str2num(rlusFileSubParts{2});

rsdsEndMonth = str2num(rsdsFileSubParts{3});
rsusEndMonth = str2num(rsusFileSubParts{3});
rldsEndMonth = str2num(rldsFileSubParts{3});
rlusEndMonth = str2num(rlusFileSubParts{3});

minEndYear = min(rsdsEndYear, max(rsusEndYear, max(rldsEndYear, rlusEndYear)));
minEndMonth = min(rsdsEndMonth, min(rsusEndMonth, min(rlusEndMonth, rldsEndMonth)));

while rsdsEndYear > minEndYear | rsdsEndMonth > minEndMonth
    rsdsEndInd = rsdsEndInd-1;

    rsdsMatFileName = rsdsMatFileNames{rsdsEndInd};
    rsdsMatFileNameParts = strsplit(rsdsMatFileName, '.');
    rsdsMatFileNameNoExt = rsdsMatFileNameParts{1};
    rsdsFileSubParts = strsplit(rsdsMatFileNameParts{1}, '_');

    rsdsEndYear = str2num(rsdsFileSubParts{2});
    rsdsEndMonth = str2num(rsdsFileSubParts{3});
end

while rsusEndYear > minEndYear | rsusEndMonth > minEndMonth
    rsusEndInd = rsusEndInd-1;

    rsusMatFileName = rsusMatFileNames{rsusEndInd};
    rsusMatFileNameParts = strsplit(rsusMatFileName, '.');
    rsusMatFileNameNoExt = rsusMatFileNameParts{1};
    rsusFileSubParts = strsplit(rsusMatFileNameParts{1}, '_');

    rsusEndYear = str2num(rsusFileSubParts{2});
    rsusEndMonth = str2num(rsusFileSubParts{3});
end

while rldsEndYear > minEndYear | rldsEndMonth > minEndMonth
    rldsEndInd = rldsEndInd-1;

    rldsMatFileName = rldsMatFileNames{rldsEndInd};
    rldsMatFileNameParts = strsplit(rldsMatFileName, '.');
    rldsMatFileNameNoExt = rldsMatFileNameParts{1};
    rldsFileSubParts = strsplit(rldsMatFileNameParts{1}, '_');

    rldsEndYear = str2num(rldsFileSubParts{2});
    rldsEndMonth = str2num(rldsFileSubParts{3});
end

while rlusEndYear > minEndYear | rlusEndMonth > minEndMonth
    rlusEndInd = rlusEndInd-1;

    rlusMatFileName = rlusMatFileNames{rlusEndInd};
    rlusMatFileNameParts = strsplit(rlusMatFileName, '.');
    rlusMatFileNameNoExt = rlusMatFileNameParts{1};
    rlusFileSubParts = strsplit(rlusMatFileNameParts{1}, '_');

    rlusEndYear = str2num(rlusFileSubParts{2});
    rlusEndMonth = str2num(rlusFileSubParts{3});
end

folDataTarget = [dataDir, '/netRad/regrid/world/', num2str(maxStartYear) num2str(maxStartMonth) '01-' num2str(minEndYear) num2str(minEndMonth) '31'];
if ~isdir(folDataTarget)
    mkdir(folDataTarget);
else
    %continue;
end

netRadCurDir = folDataTarget;

while rsdsStartInd <= rsdsEndInd & rsusStartInd <= rsusEndInd & ...
      rldsStartInd <= rldsEndInd & rlusStartInd <= rlusEndInd
    rsdsMatFileName = rsdsMatFileNames{rsdsStartInd};
    rsdsMatFileNameParts = strsplit(rsdsMatFileName, '.');
    rsdsMatFileNameNoExt = rsdsMatFileNameParts{1};

    rsusMatFileName = rsusMatFileNames{rsusStartInd};
    rsusMatFileNameParts = strsplit(rsusMatFileName, '.');
    rsusMatFileNameNoExt = rsusMatFileNameParts{1};
    
    rldsMatFileName = rldsMatFileNames{rldsStartInd};
    rldsMatFileNameParts = strsplit(rldsMatFileName, '.');
    rldsMatFileNameNoExt = rldsMatFileNameParts{1};

    rlusMatFileName = rlusMatFileNames{rlusStartInd};
    rlusMatFileNameParts = strsplit(rlusMatFileName, '.');
    rlusMatFileNameNoExt = rlusMatFileNameParts{1};

    rsdsFileSubParts = strsplit(rsdsMatFileNameParts{1}, '_');
    rsusFileSubParts = strsplit(rsusMatFileNameParts{1}, '_');
    rldsFileSubParts = strsplit(rldsMatFileNameParts{1}, '_');
    rlusFileSubParts = strsplit(rlusMatFileNameParts{1}, '_');

    rsdsStartYear = str2num(rsdsFileSubParts{2});
    rsusStartYear = str2num(rsusFileSubParts{2});
    rldsStartYear = str2num(rldsFileSubParts{2});
    rlusStartYear = str2num(rlusFileSubParts{2});

    rsdsStartMonth = str2num(rsdsFileSubParts{3});
    rsusStartMonth = str2num(rsusFileSubParts{3});
    rldsStartMonth = str2num(rldsFileSubParts{3});
    rlusStartMonth = str2num(rlusFileSubParts{3});

    if rsdsStartYear ~= rsusStartYear || ...
       rldsStartYear ~= rsusStartYear || ...
       rlusStartYear ~= rsusStartYear
        ['years do not match']
        return;
    else
        curYear = rsdsStartYear;
    end

    if rsdsStartMonth ~= rsusStartMonth || ...
       rldsStartMonth ~= rsusStartMonth || ...
       rlusStartMonth ~= rsusStartMonth
        ['months do not match']
        return;
    else
        curMonth = rsdsStartMonth;
    end
    
    monthStr = '';
    if curMonth < 10
        monthStr = ['0', num2str(curMonth)];
    else
        monthStr = num2str(curMonth);
    end

    fileName = ['netRad_', num2str(curYear), '_' monthStr, '_01'];
    
    if skipExisting && exist([netRadCurDir '/' fileName '.mat'], 'file')
        ['skipping ' netRadCurDir '/' fileName '.mat']
        rsdsStartInd = rsdsStartInd + 1;
        rsusStartInd = rsusStartInd + 1;
        rldsStartInd = rldsStartInd + 1;
        rlusStartInd = rlusStartInd + 1;
        continue;
    end

    rsdsCurFileName = [rsdsMatDirNames{rsdsStartInd}, '/', rsdsMatFileName];
    rsusCurFileName = [rsusMatDirNames{rsusStartInd}, '/', rsusMatFileName];
    rldsCurFileName = [rldsMatDirNames{rldsStartInd}, '/', rldsMatFileName];
    rlusCurFileName = [rlusMatDirNames{rlusStartInd}, '/', rlusMatFileName];

    load(rsdsCurFileName);
    load(rsusCurFileName);
    load(rldsCurFileName);
    load(rlusCurFileName);

    eval(['rsdsLat = ' rsdsMatFileNameNoExt '{1};']);
    eval(['rsdsLon = ' rsdsMatFileNameNoExt '{2};']);
    eval(['rsdsData = ' rsdsMatFileNameNoExt '{3};']);
    eval(['clear ' rsdsMatFileNameNoExt ';']);

    eval(['rsusLat = ' rsusMatFileNameNoExt '{1};']);
    eval(['rsusLon = ' rsusMatFileNameNoExt '{2};']);
    eval(['rsusData = ' rsusMatFileNameNoExt '{3};']);
    eval(['clear ' rsusMatFileNameNoExt ';']);
    
    eval(['rldsLat = ' rldsMatFileNameNoExt '{1};']);
    eval(['rldsLon = ' rldsMatFileNameNoExt '{2};']);
    eval(['rldsData = ' rldsMatFileNameNoExt '{3};']);
    eval(['clear ' rldsMatFileNameNoExt ';']);

    eval(['rlusLat = ' rlusMatFileNameNoExt '{1};']);
    eval(['rlusLon = ' rlusMatFileNameNoExt '{2};']);
    eval(['rlusData = ' rlusMatFileNameNoExt '{3};']);
    eval(['clear ' rlusMatFileNameNoExt ';']);

    
    rsdsStartInd = rsdsStartInd + 1;
    rsusStartInd = rsusStartInd + 1;
    rldsStartInd = rldsStartInd + 1;
    rlusStartInd = rlusStartInd + 1;
    
    if size(rsusData,1) ~= size(rsdsData,1) || ...
       size(rlusData,1) ~= size(rsdsData,1) || ...
       size(rldsData,1) ~= size(rsdsData,1)
        ['lat dimensions do not match, skipping ' rsdsCurFileName]
        clear rsdsLat rsdsLon rsdsData;
        clear rsusLat rsusLon rsusData;
        clear rldsLat rldsLon rldsData;
        clear rlusLat rlusLon rlusData;
        continue;
    end

    if size(rsusData,2) ~= size(rsdsData,2) || ...
       size(rlusData,2) ~= size(rsdsData,2) || ...
       size(rldsData,2) ~= size(rsdsData,2)
        ['lon dimensions do not match, skipping ' rsdsCurFileName]
        clear rsdsLat rsdsLon rsdsData;
        clear rsusLat rsusLon rsusData;
        clear rldsLat rldsLon rldsData;
        clear rlusLat rlusLon rlusData;
        continue;
    end

    if size(rsusData,3) ~= size(rsdsData,3) || ...
       size(rlusData,3) ~= size(rsdsData,3) || ...
       size(rldsData,3) ~= size(rsdsData,3)
        ['data dimensions do not match, skipping ' rsdsCurFileName]
        clear rsdsLat rsdsLon rsdsData;
        clear rsusLat rsusLon rsusData;
        clear rldsLat rldsLon rldsData;
        clear rlusLat rlusLon rlusData;
        continue;
    end

    netRad = [];
    
    for xpos = 1:size(rsdsData,1)
        for ypos = 1:size(rsdsData,2)
            for d = 1:size(rsdsData,3)

                rsds = rsdsData(xpos,ypos,d);
                rsus = rsusData(xpos,ypos,d);
                rlds = rldsData(xpos,ypos,d);
                rlus = rlusData(xpos,ypos,d);

                netRad(xpos, ypos, d) = (rsds-rsus)+(rlds-rlus);

            end
        end
    end

    
    ['processing ' netRadCurDir '/' fileName]
    eval([fileName ' = {rsdsLat, rsdsLon, netRad};']);
    save([netRadCurDir, '/', fileName, '.mat'], fileName, '-v7.3');

    eval(['clear ', fileName], ';');
    clear rsdsLat rsdsLon rsdsData netRad;
    clear rsusLat rsusLon rsusData;
    clear rlusLat rlusLon rlusData;
    clear rlusLat rlusLon rlusData;

end



