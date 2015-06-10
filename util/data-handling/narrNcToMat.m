% pressure levels extracted:
% 1, 1000 mb
% 7, 850 mb
% 17, 500 mb
% 21, 300 mb
% 25, 200 mb

% rerun before using 200 mb pressure level - it was extracted incorrectly


function narrNcToMat(rawNcDir, outputDir, varName, maxNum)

pressureLevels = [1 7 17 21 25];

ncFileNames = dir([rawNcDir, '/', varName, '.*.nc']);
ncFileNames = {ncFileNames.name};

fileCount = 0;

for k = 1:length(ncFileNames)
    if fileCount >= maxNum & maxNum ~= -1
        return
    end
    
    ncFileName = ncFileNames{k}
    
    ncid = netcdf.open([rawNcDir, '/', ncFileName]);
    [ndim, nvar, natts] = netcdf.inq(ncid);

    dataTime = '';
    
    % pull data out of the nc file name
    parts = strsplit(ncFileName, '/');
    parts = parts(end);
    parts = strsplit(parts{1}, '.');

    dataTime = lower(parts{end-1});
    
    if length(dataTime) == 6
        dataYear = dataTime(1:4);
        dataMonth = dataTime(5:6);
    elseif length(dataTime) == 4
        dataYear = dataTime(1:4);
        dataMonth = '01';
    end
    
    outputVarName = varName;
    if length(findstr('air.2m', ncFileName)) ~= 0
        outputVarName  = 'air_2m';
    end
    
    % check for output folder and make it if it doesn't exist
    folDataTarget = [outputDir, '/', outputVarName, '/', dataYear];
    if ~isdir(folDataTarget)
        mkdir(folDataTarget);
    else
        if length(dataTime) == 4
            continue;
        elseif length(dataTime) == 6 & exist([folDataTarget '/' outputVarName, '_', num2str(dataYear), '_', num2str(dataMonth, 2), '_01.mat'], 'file') == 2
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
        
        if length(findstr(dimname, 'level')) ~= 0
            dimIdLev = i+1;
        end
        
        if length(findstr(dimname, 'y')) ~= 0
            dimIdLat = i+1;
        end
        
        if length(findstr(dimname, 'x')) ~= 0
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
    varIdLev = 0;
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
        
        if length(findstr(vname, 'level')) ~= 0
            varIdLev = i+1;
        end
        
        vars{i+1} = {vname, vtype, vdim, vatts};
    end

    scaleFactor = 1;
    addOffset = 0;
    missingValue = NaN;
    fillValue = NaN;
    
    for i = 0:vars{varIdMain}{4}-1
        attname = netcdf.inqAttName(ncid, varIdMain-1, i);
        if strcmp(attname, 'scale_factor')
            scaleFactor = double(netcdf.getAtt(ncid, varIdMain-1,'scale_factor'));
        elseif strcmp(attname, 'add_offset')
            addOffset = double(netcdf.getAtt(ncid, varIdMain-1,'add_offset'));
        elseif strcmp(attname, 'missing_value')
            missingValue = int16(netcdf.getAtt(ncid, varIdMain-1,'missing_value'));
        elseif strcmp(attname, '_FillValue')
            fillValue = int16(netcdf.getAtt(ncid, varIdMain-1,'_FillValue'));
        end
    end
    
    deltaT = 0;
    
    % start at jan 1 of the file year
    startDate = datenum(double(str2num(dataYear)), double(str2num(dataMonth)), 1, 0, 0, 0);
    
    % find timestep
    if length(findstr('8x', atts{attIdTitle}{2})) ~= 0
        % 3 hr timestep
        deltaT = etime(datevec('03', 'HH'), datevec('00', 'HH'));
    elseif length(findstr('daily', atts{attIdTitle}{2})) ~= 0
        deltaT = etime(datevec('24', 'HH'), datevec('00', 'HH'));
    else
        deltaT = etime(datevec('24', 'HH'), datevec('00', 'HH'));
    end
    
    lat = double(netcdf.getVar(ncid, varIdLat-1, [0 0], [dims{dimIdLon}{2} dims{dimIdLat}{2}]));
    lat = permute(lat, [2, 1]);
    
    lon = double(netcdf.getVar(ncid, varIdLon-1, [0 0], [dims{dimIdLon}{2} dims{dimIdLat}{2}]));
    lon = permute(lon, [2, 1]);
    
    timestep = [];
    for t = 0:1:dims{dimIdTime}{2}-1
        timestep(t+1) = addtodate(startDate, t*deltaT, 'second');
    end
    
    if dimIdLev ~= -1
        for p=1:length(pressureLevels)
            data(:,:,p,:) = netcdf.getVar(ncid, varIdMain-1, [0, 0, pressureLevels(p), 0], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, 1, dims{dimIdTime}{2}]);
        end
        data = permute(data, [2 1 3 4]);
    else
        data(:,:,:) = netcdf.getVar(ncid, varIdMain-1, [0, 0, 0], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, dims{dimIdTime}{2}]);
        data = permute(data, [2 1 3]);
    end
    
    data = single(data);
    
    data(data == missingValue) = NaN;
    data(data == -missingValue) = NaN;
    
    if length(findstr('snod', ncFileName)) ~= 0
        data(data == 0) = NaN;
    end
    
    data = data * scaleFactor + addOffset;
    
%     if length(findstr('acpcp', ncFileName)) ~= 0
%         data(data>=65) = NaN;
%     elseif length(findstr('air.2m', ncFileName)) ~= 0
%         data(data>=400) = NaN;
%         data(data <=1) = NaN;
%     elseif length(findstr('hgt', ncFileName)) ~= 0
%         data(data >= 30000 | data <= -30000) = NaN;
%     elseif length(findstr('snod', ncFileName)) ~= 0
%         data(data == 0) = NaN;
%     end
    
    curTime = timestep(1);
    endTime = addtodate(startDate, dims{dimIdTime}{2}*deltaT, 'second');
    
    while curTime < endTime
        nextTime = addtodate(curTime, 1, 'month');
        
        % find indices in the timestep matrix
        curIndex = find(timestep >= curTime, 1, 'first');
        nextIndex = find(timestep < nextTime, 1, 'last');
        
        % get monthly data
        monthlyData = [];
        if dimIdLev == -1
            monthlyData = data(:, :, curIndex:nextIndex);
        else
            monthlyData = data(:, :, :, curIndex:nextIndex);
        end
        monthlyDataSet = {lat, lon, double(monthlyData)};
        
        % save the .mat file in the correct location and w/ the correct name
        fileName = [outputVarName, '_', datestr(timestep(curIndex), 'yyyy_mm_dd')];
        eval([fileName ' = monthlyDataSet;']);
        save([folDataTarget, '/', fileName, '.mat'], fileName, '-v7.3');
        
        clear monthlyData monthlyDataSet;
        eval(['clear ' fileName]);
        
        curTime = nextTime;
    end
    
    eval(['clear ' fileName ';']);
	clear data dims vars timestep;
    netcdf.close(ncid);
    fileCount = fileCount + 1;
end

