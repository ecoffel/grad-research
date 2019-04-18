
function cruToMat(rawNcDir, outputDir, varName, maxNum)

ncFileNames = dir([rawNcDir, '/', 'cru*.nc']);
ncFileNames = {ncFileNames.name};

fileCount = 0;

for k = 1:length(ncFileNames)
    if fileCount >= maxNum & maxNum ~= -1
        return
    end
    
    ncFileName = ncFileNames{k}
    
    ncid = netcdf.open([rawNcDir, '/', ncFileName]);
    [ndim, nvar, natts] = netcdf.inq(ncid);

    %varName = '';
    year = '';
    
    % pull data out of the nc file name
    parts = strsplit(ncFileName, '/');
    parts = parts(end);
    parts = strsplit(parts{1}, '.');

    %if length(parts) == 3
    %varName = lower(parts{1});
    
    % check for output folder and make it if it doesn't exist
    folDataTarget = [outputDir, '/', varName];
    if ~isdir(folDataTarget)
        mkdir(folDataTarget);
    else
        %continue;
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
    
    attIdTitle = -1;
    
    atts = {};
    for i = 0:natts-1
        attname = netcdf.inqAttName(ncid, netcdf.getConstant('NC_GLOBAL'), i);
        attval = netcdf.getAtt(ncid, netcdf.getConstant('NC_GLOBAL'), attname);
        
        if length(findstr(attname, 'title')) ~= 0
            attIdTitle = i+1;
        end
        
        atts{i+1} = {attname, attval};
    end

    varIdLat = 0;
    varIdLon = 0;
    varIdMain = 0;
    
    vars = {};
    for i = 0:nvar-1
        [vname, vtype, vdim, vatts] = netcdf.inqVar(ncid,i);
        
        if length(findstr(vname, 'lat')) ~= 0
            varIdLat = i+1;
        end
        
        if length(findstr(vname, 'lon')) ~= 0
            varIdLon = i+1;
        end
        
        if length(findstr(vname, varName)) ~= 0
            varIdMain = i+1;
        end
        
        vars{i+1} = {vname, vtype, vdim, vatts};
    end

    scale_factor = 1;
    add_offset = 0;
    missing_value = -10000;
    
    for i = 0:vars{varIdMain}{4}-1
        attname = netcdf.inqAttName(ncid, varIdMain-1, i);
        if strcmp(attname, 'scale_factor')
            scale_factor = double(netcdf.getAtt(ncid, varIdMain-1,'scale_factor'));
        elseif strcmp(attname, 'add_offset')
            add_offset = double(netcdf.getAtt(ncid, varIdMain-1,'add_offset'));
        elseif strcmp(attname, 'missing_value')
            missing_value = double(netcdf.getAtt(ncid, varIdMain-1,'missing_value'));
        end
    end
    
    deltaT = 0;
    
    % start at jan 1 of the file year
    startDate = datenum(1900, 1, 1, 0, 0, 0);
   
    lat = double(netcdf.getVar(ncid, varIdLat-1, [0], [dims{dimIdLat}{2}]));
    lon = double(netcdf.getVar(ncid, varIdLon-1, [0], [dims{dimIdLon}{2}]));
    
    [lon, lat] = meshgrid(lon, lat);
    lon(lon<0) = lon(lon<0)+360;
    lon = circshift(lon,720/2,2);
    
    timestep = [startDate];
    for t = 1:dims{dimIdTime}{2}
        timestep(t+1) = addtodate(timestep(t), 1, 'month');
    end

    data(:,:,:) = netcdf.getVar(ncid, varIdMain-1, [0, 0, 0], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, dims{dimIdTime}{2}]);
    data = permute(data, [2 1 3]);
    data(data == missing_value) = NaN;
    
    data = circshift(data, 720/2, 2);
    
    t = 1;
    while t < length(timestep)
        monthlyData = double(data(:, :, t))*scale_factor + add_offset;
        
        monthlyDataSet = {lat, lon, squeeze(monthlyData)};

        % save the .mat file in the correct location and w/ the correct name
        fileName = [varName, '_', datestr(timestep(t), 'yyyy_mm_dd')];
        eval([fileName ' = monthlyDataSet;']);
        save([folDataTarget, '/', fileName, '.mat'], fileName);

        clear monthlyData monthlyDataSet;
        eval(['clear ' fileName ';']);
        t = t + 1;
    end
    
    clear data dims vars timestep;
    netcdf.close(ncid);
end

