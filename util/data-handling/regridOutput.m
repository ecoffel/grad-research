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
startyear = -1;
endyear = -1;
skipExisting = true;
latLonBounds = [];
v7 = false;
region = '';
tosMod = false;
gridCor = false;
monthly = false;

for i=1:2:length(varargin)
    key = varargin{i};
    val = varargin{i+1};
    switch key
        case 'plev'
            plev = val;
        case 'startYear'
            startyear = val;
        case 'endYear'
            endyear = val;
        case 'skipexisting'
            skipExisting = val;
        case 'latLonBounds'
            latLonBounds = val;
        case 'v7'
            v7 = val;
        case 'region'
            region = val;
        case 'tos-strangegrid'
            tosMod = true;
        case 'monthly'
            monthly = true;
    end
end

if tosMod
    gridCor = false;
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
    
    regridDir = [dataDir '/regrid/' region '/' dirNames{d}];
    if ~isdir(regridDir) & length(findstr(dataDir, 'regrid')) == 0 & length(findstr(dirNames{d}, 'regrid')) == 0
        mkdir(regridDir);
    end
    
    matFileNames = dir([curDir, '/*.mat']);
    matFileNames = {matFileNames.name};

    for k = 1:length(matFileNames)
        matFileName = matFileNames{k};

        % check if this file contains the target variable
        matFileNameParts = strsplit(matFileName, '_');
        if length(strfind(matFileNameParts{1}, varName)) == 0
            ['skipping ' matFileName '...']
            continue
        end

        matFileNameParts = strsplit(matFileName, '.');
        matFileNameNoExt = matFileNameParts{1};
        matFileNameParts = strsplit(matFileNameNoExt, '_');

        year = str2num(matFileNameParts{2});
        if (startyear ~= -1 && year < startyear) || (endyear ~= -1 && year > endyear)
            ['skipping ' matFileName '...']
            continue;
        end
        
        if plev == -1
            newFileName = [regridDir '/' matFileName]
        else
            plevStr = sprintf('%02d', plev);
            newFileName = [regridDir '/' matFileNameNoExt '_' plevStr '.mat']
        end
        
        if skipExisting
            if exist(newFileName, 'file') == 2
                ['skipping ' matFileName '...']
                continue;
            end
        end
        
        ['regridding ' matFileName '...']
        
        curFileName = [curDir, '/', matFileName];
        load(curFileName);
        
        lat = double(eval([matFileNameNoExt, '{1}']));
        lon = double(eval([matFileNameNoExt, '{2}']));        
        curMonthlyData = double(eval([matFileNameNoExt, '{3}']));
        
        % if it is a -180 to +180 grid, convert to 0 - 360
        if lon(1) < 0
            % adjust lon
            lon = lon + 180;
            % and shift data by 180 degrees to align with new lon grid
            curMonthlyData = circshift(curMonthlyData, size(curMonthlyData, 2), 2);
        end
        
        if ~tosMod
            if length(latLonBounds) > 0
                if latLonBounds(2, 1) < 0
                    latLonBounds(2, 1) = latLonBounds(2, 1) + 360;
                    latLonBounds(2, 2) = latLonBounds(2, 2) + 360;
                end

                [latIndexM, lonIndexM] = latLonIndexRange({lat, lon, curMonthlyData}, latLonBounds(1, 1:end), latLonBounds(2, 1:end));
                lat = lat(latIndexM, lonIndexM);
                lon = lon(latIndexM, lonIndexM);
                if length(size(curMonthlyData)) == 3
                    curMonthlyData = curMonthlyData(latIndexM, lonIndexM, :);
                elseif length(size(curMonthlyData)) == 4
                    curMonthlyData = curMonthlyData(latIndexM, lonIndexM, :, :);
                end

                [latIndexB, lonIndexB] = latLonIndexRange(baseGrid, latLonBounds(1, 1:end), latLonBounds(2, 1:end));
                baseGrid{1} = baseGrid{1}(latIndexB, lonIndexB);
                baseGrid{2} = baseGrid{2}(latIndexB, lonIndexB);
            end
        else
            lon = lon + 360;
            lon(lon > 360) = lon(lon > 360) - 360;
        end
        
        if plev == -1
            
            regridLat = [];
            regridLon = [];
            regridData = [];
            
            for d=1:size(curMonthlyData, 3)
                curData = squeeze(curMonthlyData(:,:,d));
                regridCurData = regridGriddata({lat, lon, curData}, baseGrid, gridCor);
                
                if length(regridLat) == 0 | length(regridLon) == 0
                    regridLat = regridCurData{1};
                    regridLon = regridCurData{2};
                end
                
                regridData(:,:,d) = regridCurData{3};
                clear curData regridCurData;
            end
            
            eval([matFileNameNoExt ' = {regridLat, regridLon, regridData};']);
            saved = false;
            while ~saved
                try
                    save([regridDir, '/', matFileNameNoExt, '.mat'], matFileNameNoExt, '-v7.3');
                    saved = true;
                catch
                    saved = false;
                end
            end
            eval(['clear ' matFileNameNoExt ';']);
            clear curData regridData;
        else
            regridLat = [];
            regridLon = [];
            regridData = [];
            
            for d=1:size(curMonthlyData, 4)
                curData = squeeze(curMonthlyData(:,:,plev,d));
                regridCurData = regridGriddata({lat, lon, curData}, baseGrid, gridCor);
                
                if length(regridLat) == 0 | length(regridLon) == 0
                    regridLat = regridCurData{1};
                    regridLon = regridCurData{2};
                end
                
                regridData(:,:,d) = regridCurData{3};
                clear curData regridCurData;
            end
            
            matFileNameNoExtPlev = [matFileNameNoExt '_' plevStr];
            
            eval([matFileNameNoExtPlev ' = {regridLat, regridLon, regridData};']);
            if v7
                save([regridDir, '/', matFileNameNoExtPlev, '.mat'], matFileNameNoExtPlev, '-v7');
            else
                save([regridDir, '/', matFileNameNoExtPlev, '.mat'], matFileNameNoExtPlev, '-v7.3');
            end
            eval(['clear ' matFileNameNoExt ';']);
            clear curData regridData;
        end
        
        clear curMonthlyData;
    end
end

