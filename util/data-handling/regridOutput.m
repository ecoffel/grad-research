function regridOutput(dataDir, varName, baseGrid, varargin)

if ~exist(dataDir)
    [dataDir ' does not exist, quitting']
    return;
end

if mod(length(varargin), 2) ~= 0
    'Error: must have an even number of arg/val pairs'    
    return
end

plev = -1;
yearstart = -1;
yearend = -1;
skipExisting = true;

for i=1:2:length(varargin)
    key = varargin{i};
    val = varargin{i+1};
    switch key
        case 'plev'
            plev = val;
        case 'yearStart'
            yearstart = val;
        case 'yearEnd'
            yearend = val;
        case 'skipexisting'
            skipExisting = val;
    end
end

dirNames = dir(dataDir);
dirIndices = [dirNames(:).isdir];
dirNames = {dirNames(dirIndices).name}';

if length(dirNames) == 0
    dirNames(1) = '';
end

startMonth = -1;
monthIndex = 1;

monthlyData = {};
lat = [];
lon = [];

for d = 1:length(dirNames)
    curDir = [dataDir '/' dirNames{d}];
    
    if strcmp(dirNames{d}, '.') || strcmp(dirNames{d}, '..') || strcmp(dirNames{d}, 'regrid')
        continue;
    end
    
    regridDir = [dataDir '/regrid/' dirNames{d}];
    if ~isdir(regridDir) & length(findstr(dataDir, 'regrid')) == 0 & length(findstr(dirNames{d}, 'regrid')) == 0
        mkdir(regridDir);
    end
    
    matFileNames = dir([curDir, '/*.mat']);
    matFileNames = {matFileNames.name};

    for k = 1:length(matFileNames)
        matFileName = matFileNames{k};

        ['regridding ' matFileName '...']
        
        % check if this file contains the target variable
        matFileNameParts = strsplit(matFileName, '_');
        if length(strfind(matFileNameParts{1}, varName)) == 0
            continue
        end

        matFileNameParts = strsplit(matFileName, '.');
        matFileNameNoExt = matFileNameParts{1};
        matFileNameParts = strsplit(matFileNameNoExt, '_');

        if plev == -1
            newFileName = [regridDir '/' matFileName]
        else
            plevStr = sprintf('%02d', plev);
            newFileName = [regridDir '/' matFileNameNoExt '_' plevStr '.mat']
        end
        
        if skipExisting
            if exist(newFileName, 'file') == 2
                continue;
            end
        end
        
        curFileName = [curDir, '/', matFileName];
        load(curFileName);
        
        lat = double(eval([matFileNameNoExt, '{1}']));
        lon = double(eval([matFileNameNoExt, '{2}']));        
        curMonthlyData = double(eval([matFileNameNoExt, '{3}']));
        
        if plev == -1
            
            regridLat = [];
            regridLon = [];
            regridData = [];
            
            for d=1:size(curMonthlyData, 3)
                curData = squeeze(curMonthlyData(:,:,d));
                regridCurData = regridGriddata({lat, lon, curData}, baseGrid);
                
                if length(regridLat) == 0 | length(regridLon) == 0
                    regridLat = regridCurData{1};
                    regridLon = regridCurData{2};
                end
                
                regridData(:,:,d) = regridCurData{3};
                clear curData regridCurData;
            end
            
            eval([matFileNameNoExt ' = {regridLat, regridLon, regridData};']);
            save([regridDir, '/', matFileNameNoExt, '.mat'], matFileNameNoExt, '-v7.3');
            eval(['clear ' matFileNameNoExt ';']);
            clear curData regridData;
        else
            regridLat = [];
            regridLon = [];
            regridData = [];
            
            for d=1:size(curMonthlyData, 4)
                curData = squeeze(curMonthlyData(:,:,plev,d));
                regridCurData = regridGriddata({lat, lon, curData}, baseGrid);
                
                if length(regridLat) == 0 | length(regridLon) == 0
                    regridLat = regridCurData{1};
                    regridLon = regridCurData{2};
                end
                
                regridData(:,:,d) = regridCurData{3};
                clear curData regridCurData;
            end
            
            matFileNameNoExtPlev = [matFileNameNoExt '_' plevStr];
            
            eval([matFileNameNoExtPlev ' = {regridLat, regridLon, regridData};']);
            save([regridDir, '/', matFileNameNoExtPlev, '.mat'], matFileNameNoExtPlev, '-v7.3');
            eval(['clear ' matFileNameNoExt ';']);
            clear curData regridData;
        end
        
        clear curMonthlyData;
    end
end

