% TODO:
% 1. Automatically identify deltaT
% 2. Fix missing data at lon = 0

function cmip5NcToMat_monthly(rawNcDir, outputDir, varName, maxNum)

ncFileNames = dir([rawNcDir, '/', varName, '_*.nc']);
ncFileNames = {ncFileNames.name};

fileCount = 0;
yearStep = 20;

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
    timeSpacing = '';
    modelName = '';
    emissionsScenario = '';
    runName = '';
    startDate = '';
    endDate = '';
    
    % pull data out of the nc file name
    parts = strsplit(ncFileName, '/');
    parts = parts(end);
    parts = strsplit(parts{1}, '_');

    if length(parts) == 6
        varName = lower(parts{1});
        timeSpacing = lower(parts{2});
        modelName = lower(parts{3});
        emissionsScenario = lower(parts{4});
        runName = lower(parts{5});
        
        timeRange = strsplit(lower(parts{6}), '.');
        timeRange = timeRange{1};
        timeRange = strsplit(timeRange, '-');
        startDate = timeRange{1};
        endDate = timeRange{2};
    end
    
    monthly = false;
    if length(findstr(timeSpacing, 'mon')) ~= 0
        monthly = true;
    end
    
    % check for output folder and make it if it doesn't exist
    folDataTarget = [outputDir, '/', modelName, '/', runName, '/', emissionsScenario, '/', varName, '/', timeSpacing, '/', startDate, '-', endDate];
    if ~isdir(folDataTarget)
        mkdir(folDataTarget);
    else
        if skipExistingFolders
            %continue;
        end
    end
    
    dimIdLat = -1;
    dimIdLon = -1;
    dimIdLev = -1;
    dimIdTime = -1;
    
    latLonDimSwitch = false;
    
    dims = {};
    for i = 0:ndim-1
        [dimname, dimlen] = netcdf.inqDim(ncid,i);
        
        if length(findstr(dimname, 'lev')) ~= 0
            dimIdLev = i+1;
        end
        
        if strcmp(dimname, 'lat') || strcmp(dimname, 'rlat') || strcmp(dimname, 'j')
            dimIdLat = i+1;
            if strcmp(dimname, 'j')
                latLonDimSwitch = true;
            end
        end
        
        if strcmp(dimname, 'lon')|| strcmp(dimname, 'rlon') || strcmp(dimname, 'i')
            dimIdLon = i+1;
            if strcmp(dimname, 'i')
                latLonDimSwitch = true;
            end
        end
        
        if strcmp(dimname, 'time')
            dimIdTime = i+1;
        end
        dims{i+1} = {dimname, dimlen};
    end

    varIdPLev = 0;
    varIdLat = 0;
    varIdLon = 0;
    varIdMain = 0;
    varIdTime = 0;
    
    vars = {};
    for i = 0:nvar-1
        [vname, vtype, vdim] = netcdf.inqVar(ncid,i);
        
        if strcmp(vname, 'lat')
            varIdLat = i;
        end
        
        if strcmp(vname, 'lon')
            varIdLon = i;
        end
        
        if strcmp(vname, 'time')
            varIdTime = i;
        end
        
        if length(findstr(vname, 'plev')) ~= 0
            varIdPLev = i;
        end
        
        if length(findstr(vname, varName)) ~= 0
            varIdMain = i;
        end
        
        vars{i+1} = {vname, vtype, vdim};
    end
    
    % get the missing value param
    missingVal = netcdf.getAtt(ncid, varIdMain, 'missing_value');
    
    % pull the start date out of the string
    if length(startDate) == 8
        startDate = datenum(startDate, 'yyyymmdd');
    elseif length(startDate) == 6
        startDate = datenum(startDate, 'yyyymm');
    end
    
    if length(endDate) == 8
        endDate = datenum(endDate, 'yyyymmdd');
    elseif length(endDate) == 6
        endDate = datenum(endDate, 'yyyymm');
    end

    if strcmp(varName, 'tos') && (length(findstr('ipsl', rawNcDir)) ~= 0 || ...
                                  length(findstr('gfdl', rawNcDir)) ~= 0 || ...
                                  length(findstr('cnrm', rawNcDir)) ~= 0 || ...
                                  length(findstr('noresm', rawNcDir)) ~= 0 || ...
                                  length(findstr('miroc', rawNcDir)) ~= 0 || ...
                                  length(findstr('bcc-csm', rawNcDir)) ~= 0 || ...
                                  length(findstr('mri-cgcm3', rawNcDir)) ~= 0 || ...
                                  length(findstr('access', rawNcDir)) ~= 0)
        lat = netcdf.getVar(ncid, varIdLat, [0 0], [dims{dimIdLon}{2} dims{dimIdLat}{2}]);
        lat = double(lat');
        
        lon = netcdf.getVar(ncid, varIdLon, [0 0], [dims{dimIdLon}{2} dims{dimIdLat}{2}]);
        lon = double(lon');
        
    else
        try
            try
                lat = double(netcdf.getVar(ncid, varIdLat, [0 0], [1 dims{dimIdLat}{2}]));
            catch
                lat = double(netcdf.getVar(ncid, varIdLat, [0 0], [dims{dimIdLat}{2} 1]));
            end
        catch
            lat = double(netcdf.getVar(ncid, varIdLat, [0], [dims{dimIdLat}{2}]));
        end

        try
            try
                lon = double(netcdf.getVar(ncid, varIdLon, [0 0], [1 dims{dimIdLon}{2}]));
            catch
                lon = double(netcdf.getVar(ncid, varIdLon, [0 0], [dims{dimIdLon}{2} 1]));
            end
        catch
            lon = double(netcdf.getVar(ncid, varIdLon, [0], [dims{dimIdLon}{2}]));
        end
        [lon, lat] = meshgrid(lon, lat);
    end
    
    useStartDate = false;
    
    if length(findstr('bcc-csm', rawNcDir)) ~= 0 || ...
       length(findstr('bnu-esm', rawNcDir)) ~= 0 || ...
       length(findstr('canesm', rawNcDir)) ~= 0 || ...
       length(findstr('cnrm', rawNcDir)) ~= 0 || ...
       length(findstr('inmcm', rawNcDir)) ~= 0 || ...
       length(findstr('ipsl', rawNcDir)) ~= 0 || ...
       length(findstr('csiro', rawNcDir)) ~= 0 || ...
       length(findstr('miroc', rawNcDir)) ~= 0
        startDate = datenum([1850 01 01 00 00 00]);
    else
        startDate = datenum([0001 01 01 00 00 00]);
    end
    
    timestep = netcdf.getVar(ncid, varIdTime, [0], [dims{dimIdTime}{2}]) + startDate;

    for t = 0:length(timestep)-1
    
        if dimIdLev ~= -1
            data(:,:,:,:) = single(netcdf.getVar(ncid, varIdMain, [0, 0, 0, t], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, dims{dimIdLev}{2}, t+1]));
            data = permute(data, [2 1 3 4]);
            
            plevs = single(netcdf.getVar(ncid, varIdPLev, 0, dims{dimIdLev}{2}));
        else
            data(:,:,:) = single(netcdf.getVar(ncid, varIdMain, [0, 0, t], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, 1]));
            data = permute(data, [2 1 3]);
        end
        
        if strcmp(varName, 'tos')
            if length(findstr(rawNcDir, 'miroc5')) ~= 0 || ...
               length(findstr(rawNcDir, 'mri-cgcm3')) ~= 0
                data(data == 0) = NaN;
            end
            data(data == missingVal) = NaN;
        end

        if length(datestr(timestep(t+1), 'yyyy_mm_dd')) == 0
            break;
        end
        fileName = [varName, '_', datestr(timestep(t+1), 'yyyy_mm_dd')];

        if skipExistingFiles
            if exist(fileName, 'file')
                continue;
            end
        end

        % get monthly data
        monthlyData = [];

        if dimIdLev ~= -1
            monthlyData = data(:, :, :, :);
            monthlyDataSet = {lat, lon, double(monthlyData), plevs};
        else
            monthlyData = data(:, :, :);
            monthlyDataSet = {lat, lon, double(monthlyData)};
        end

        % save the .mat file in the correct location and w/ the correct name
        if size(monthlyData, 3) > 0
            eval([fileName ' = monthlyDataSet;']);
            save([folDataTarget, '/', fileName, '.mat'], fileName);
            eval(['clear ' fileName ';']);
        end

        clear monthlyDataSet monthlyData data;
        
    end
    
    clear dims vars timestep;
    netcdf.close(ncid);
    fileCount = fileCount + 1;
end

