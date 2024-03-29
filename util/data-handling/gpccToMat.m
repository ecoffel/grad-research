function gpcpToMat(rawNcDir, outputDir, varName, maxNum)

ncFileNames = dir([rawNcDir, '/', varName, '*.nc']);
ncFileNames = {ncFileNames.name};

fileCount = 0;

for k = 1:length(ncFileNames)
    if fileCount >= maxNum & maxNum ~= -1
        return
    end
    
    ncFileName = ncFileNames{k}
    
    ncid = netcdf.open([rawNcDir, '/', ncFileName]);
    [ndim, nvar, natts] = netcdf.inq(ncid);

    yearStr = '';
    
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
        
        if strcmp(attname, 'title')
            attIdTitle = i+1;
        end
        
        atts{i+1} = {attname, attval};
    end

    varIdLat = 0;
    varIdLon = 0;
    varIdLev = 0;
    varIdMain = 0;
    varIdTime = 0;
    
    vars = {};
    for i = 0:nvar-1
        [vname, vtype, vdim, vatts] = netcdf.inqVar(ncid,i);
        
        if strcmp(vname, 'lat')
            varIdLat = i+1;
        end
        
        if strcmp(vname, 'lon')
            varIdLon = i+1;
        end
        
        if length(findstr(vname, varName)) ~= 0
            varIdMain = i+1;
        end
        
        if strcmp(vname, 'time')
            varIdTime = i+1;
        end
        
        vars{i+1} = {vname, vtype, vdim, vatts};
    end

    scale_factor = 1;
    add_offset = 0;
    missing_val = 0;
    
    for i = 0:vars{varIdMain}{4}-1
        attname = netcdf.inqAttName(ncid, varIdMain-1, i);
        if strcmp(attname, 'scale_factor')
            scale_factor = double(netcdf.getAtt(ncid, varIdMain-1,'scale_factor'));
        elseif strcmp(attname, 'add_offset')
            add_offset = double(netcdf.getAtt(ncid, varIdMain-1,'add_offset'));
        elseif strcmp(attname, 'missing_value')
            missing_val = double(netcdf.getAtt(ncid, varIdMain-1,'missing_value'));
        end
    end
    
    lat = double(netcdf.getVar(ncid, varIdLat-1, [0], [dims{dimIdLat}{2}]));
    lon = double(netcdf.getVar(ncid, varIdLon-1, [0], [dims{dimIdLon}{2}]));
    
    [lon, lat] = meshgrid(lon, lat);
    %lat = flipud(lat);
    
    % starts at 1900 01 01 01 01 01
    starttime = datenum([1800 01 01 00 00 00]);
    time = [];
    
    % these are days since 1800-01-01 01:01:01
	timestep = netcdf.getVar(ncid, varIdTime-1, [0], [dims{dimIdTime}{2}]);
    
    for t = 1:length(timestep)
        time(t) = addtodate(starttime, timestep(t), 'day');
    end
    
    % check for output folder and make it if it doesn't exist
    folDataTarget = [outputDir, '/', varName, '/monthly/' num2str(year(time(1))) '-' num2str(year(time(end)))];
    
    if ~isdir(folDataTarget)
        mkdir(folDataTarget);
    else
        %continue;
    end
    
    ind = 0;

    % month of last time step, so we know when to save
    curStartDate = time(1);
    lastMonth = -1;
    monthlyInd = 1;
    monthlyData = [];

    while ind < dims{dimIdTime}{2}
        data = double(netcdf.getVar(ncid, varIdMain-1, [0, 0, ind], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, 1])) .* scale_factor + add_offset;
        data = permute(data, [2 1]);
        
        curMonth = month(time(ind+1));
        monthlyData = data;
       
        monthlyData = squeeze(monthlyData);
        monthlyData(monthlyData == missing_val) = NaN;

        monthlyDataSet = {lat, lon, flipud(squeeze(monthlyData))};

        % save the .mat file in the correct location and w/ the correct name
        fileName = [varName, '_', datestr(curStartDate, 'yyyy_mm_dd')];
        eval([fileName ' = monthlyDataSet;']);
        save([folDataTarget, '/', fileName, '.mat'], fileName);

        clear monthlyDataSet;
        monthlyData = [];
        monthlyInd = 1;
        lastMonth = curMonth;
        ind = ind + 1;
        curStartDate = time(ind+1);
        eval(['clear ' fileName ';']);
            
    end
    
 end

    clear data dims vars timestep;
    netcdf.close(ncid);
    fileCount = fileCount + 1;
end

