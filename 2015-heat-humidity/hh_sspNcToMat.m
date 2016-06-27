% TODO:
% 1. Automatically identify deltaT
% 2. Fix missing data at lon = 0

function sspNcToMat(rawNcDir, outputDir, varName, maxNum)

ncFileNames = dir([rawNcDir, '/', varName, '_*.nc']);
ncFileNames = {ncFileNames.name};

fileCount = 0;

skipExistingFolders = false;
skipExistingFiles = false;

for k = 1:length(ncFileNames)
    if fileCount >= maxNum & maxNum ~= -1
        return
    end
    
    ncFileName = ncFileNames{k}
    
    ncid = netcdf.open([rawNcDir, '/', ncFileName]);
    [ndim, nvar] = netcdf.inq(ncid);

    varName = '';
    year = '';
    
    % pull data out of the nc file name
    parts = strsplit(ncFileName, '/');
    parts = parts(end);
    parts = strsplit(parts{1}, '_');

    if length(parts) == 2
        varName = lower(parts{1});
        yearParts = strsplit(parts{2}, '.');
        year = lower(yearParts{1});
    end
    
    % check for output folder and make it if it doesn't exist
    folDataTarget = [outputDir, '/', varName];
    if ~isdir(folDataTarget)
        mkdir(folDataTarget);
    else
        if skipExistingFolders
            continue;
        end
    end
    
    dimIdLat = -1;
    dimIdLon = -1;
    dimIdLev = -1;
    dimIdTime = -1;
    
    dims = {};
    for i = 0:ndim-1
        [dimname, dimlen] = netcdf.inqDim(ncid,i);
        
        if length(findstr(dimname, 'lat')) ~= 0
            dimIdLat = i+1;
        end
        
        if length(findstr(dimname, 'lon')) ~= 0
            dimIdLon = i+1;
        end
        
        dims{i+1} = {dimname, dimlen};
    end

    varIdLat = 0;
    varIdLon = 0;
    varIdMain = 0;
    
    vars = {};
    for i = 0:nvar-1
        [vname, vtype, vdim] = netcdf.inqVar(ncid,i);
        
        if length(findstr(vname, 'lat')) ~= 0
            varIdLat = i;
        end
        
        if length(findstr(vname, 'lon')) ~= 0
            varIdLon = i;
        end
        
        if length(findstr(upper(vname), [upper(varName) '_' num2str(year)])) ~= 0
            varIdMain = i;
        end
        
        vars{i+1} = {vname, vtype, vdim};
    end

    lat = double(netcdf.getVar(ncid, varIdLat, [0], [dims{dimIdLat}{2}]));
    lon = double(netcdf.getVar(ncid, varIdLon, [0], [dims{dimIdLon}{2}]));
    
    [lon, lat] = meshgrid(lon, lat);
    
    data = double(netcdf.getVar(ncid, varIdMain, [0 0], [dims{dimIdLon}{2} dims{dimIdLat}{2}]))';
    
    % remove missing values
    data(data > 2e+09) = NaN;
    
    data = {lat, lon, data};
    
    fileName = [varName, '_', num2str(year)];
            
    if skipExistingFiles
        if exist([folDataTarget '\' fileName], 'file')
            continue;
        end
    end
    
    eval([fileName ' = data;']);
    save([folDataTarget, '/', fileName, '.mat'], fileName);
    eval(['clear ' fileName ';']);
    
    clear dims vars;
    netcdf.close(ncid);
    fileCount = fileCount + 1;
end

