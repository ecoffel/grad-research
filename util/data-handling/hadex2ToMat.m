function hadex2ToMat(rawNcDir, outputDir, varName, maxNum)

ncFileNames = dir([rawNcDir, '/*_', varName, '_*.nc']);
ncFileNames = {ncFileNames.name};

fileCount = 0;
yearStep = 10;

skipExistingFolders = true;
skipExistingFiles = false;

monthlyVars = {'txx', 'rx1day'};
annualVars = {'cdd'};

for k = 1:length(ncFileNames)
    if fileCount >= maxNum & maxNum ~= -1
        return
    end
    
    ncFileName = ncFileNames{k}
    
    ncid = netcdf.open([rawNcDir, '/', ncFileName]);
    [ndim, nvar] = netcdf.inq(ncid);

    varName = '';
    startDate = '';
    endDate = '';
    
    % pull data out of the nc file name
    parts = strsplit(ncFileName, '/');
    parts = parts(end);
    parts = strsplit(parts{1}, '_');

    varName = lower(parts{2});
    timeRange = strsplit(lower(parts{3}), '-');
    startDate = timeRange{1};
    endDate = timeRange{2};
    
    % check for output folder and make it if it doesn't exist
    folDataTarget = [outputDir, '/', varName, '/', startDate, '-', endDate];
    if ~isdir(folDataTarget)
        mkdir(folDataTarget);
    else
        if skipExistingFolders
            continue;
        end
    end
    
    dimIdLat = -1;
    dimIdLon = -1;
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
        
        if length(findstr(dimname, 'time')) ~= 0
            dimIdTime = i+1;
        end
        
        dims{i+1} = {dimname, dimlen};
    end

    varIdLat = 0;
    varIdLon = 0;
    
    if length(find(strcmp(monthlyVars, lower(varName)))) ~= 0
        dataVars = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Ann'};
        dataVarIds = {};
    elseif length(strcmp(annualVars, lower(varName))) ~= 0
        dataVars = {'Ann'};
        dataVarIds = {};
    end
    
    vars = {};
    for i = 0:nvar-1
        [vname, vtype, vdim] = netcdf.inqVar(ncid,i);
        
        if length(findstr(vname, 'lat')) ~= 0
            varIdLat = i;
        end
        
        if length(findstr(vname, 'lon')) ~= 0
            varIdLon = i;
        end
        
        ind = find(strcmp(dataVars, vname));
        if length(ind) ~= 0
            dataVarIds{ind} = i;
        end
        
        vars{i+1} = {vname, vtype, vdim};
    end
    
    lat = double(netcdf.getVar(ncid, varIdLat, [0], [dims{dimIdLat}{2}]));
    lon = double(netcdf.getVar(ncid, varIdLon, [0], [dims{dimIdLon}{2}]));
    
    [lat, lon] = meshgrid(lat, lon);
    
    lat = lat';
    lon = lon';
    
    % loop through and extract each month
    for m = 1:length(dataVars)
        data(:,:,:) = netcdf.getVar(ncid, dataVarIds{m}, [0, 0, 0], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, dims{dimIdTime}{2}]);
        
        dataT = [];
        for t = 1:size(data, 3)
            dataT(:,:,t) = data(:,:,t)';
        end
        
        clear data;
        
        fillValue = netcdf.getAtt(ncid, dataVarIds{m}, '_FillValue');
        dataT(dataT == fillValue) = NaN;
        
        if strcmp(dataVars{m}, 'Ann')
            fileName = [varName, '_ann'];
        else
            fileName = [varName, '_', sprintf('%02d', m)];
        end
        
        if skipExistingFiles
            if exist(fileName, 'file')
                continue;
            end
        end
        
        monthlyDataSet = {lat, lon, double(dataT)};
        
        % save the .mat file in the correct location and w/ the correct name
        if size(dataT, 3) > 0 | length(datestr(timestep(curIndex))) > 0
            eval([fileName ' = monthlyDataSet;']);
            save([folDataTarget, '/', fileName, '.mat'], fileName);
            eval(['clear ' fileName ';']);
        end

        clear dataT monthlyDataSet;
    end
    
    clear dims vars timestep;
    netcdf.close(ncid);
    fileCount = fileCount + 1;
end









