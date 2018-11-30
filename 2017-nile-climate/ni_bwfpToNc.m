% TODO:
% 1. Automatically identify deltaT
% 2. Fix missing data at lon = 0

function sspNcToMat(rawNcDir, outputDir, origVarName, maxNum)

ncFileNames = dir([rawNcDir, '/', origVarName, '_*.nc']);
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

    varName = 'demand';
    year = '';
    
    % pull data out of the nc file name
    parts = strsplit(ncFileName, '/');
    parts = parts(end);
    parts = strsplit(parts{1}, '_');
    
    % check for output folder and make it if it doesn't exist
    folDataTarget = [outputDir, '/', origVarName];
    if ~isdir(folDataTarget)
        mkdir(folDataTarget);
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
    
    if length(findstr(outputDir, 'domind')) ~= 0
        data = double(netcdf.getVar(ncid, varIdMain, [0 0], [dims{dimIdLon}{2} dims{dimIdLat}{2}]));
        data = permute(data, [2 1]);
    else
        data = double(netcdf.getVar(ncid, varIdMain, [0 0 0], [dims{dimIdLon}{2} dims{dimIdLat}{2} 12]));
        data = permute(data, [2 1 3]);
    end
    
    % remove missing values
    data(abs(data) > 2e+09) = NaN;
    
    for m = 1:size(data, 3)
        curData = {lat, lon, data(:, :, m)};

        fileName = [origVarName, '_', num2str(m)];

        eval([fileName ' = curData;']);
        save([folDataTarget, '/', fileName, '.mat'], fileName);
        eval(['clear ' fileName ';']);
    end
    
    clear dims vars;
    netcdf.close(ncid);
    fileCount = fileCount + 1;
end

