% why is the last december in a nc file not translated?

function narccapNcToMat(rawNcDir, outputDir, varName, maxNum)

ncFileNames = dir([rawNcDir, '/', varName, '_*.nc']);
ncFileNames = {ncFileNames.name};

fileCount = 0;

for k = 1:length(ncFileNames)
    if fileCount >= maxNum & maxNum ~= -1
        return
    end
    
    ncFileName = ncFileNames{k}
    
    ncid = netcdf.open([rawNcDir, '/', ncFileName]);
    [ndim, nvar] = netcdf.inq(ncid);

    rcmName = '';
    gcmName = '';
    modelTime = '';
    plev = '';
    
    % pull data out of the nc file name
    parts = strsplit(ncFileName, '/');
    parts = parts(end);
    parts = strsplit(parts{1}, '_');

    if length(parts) == 5
        rcmName = lower(parts{2});
        gcmName = lower(parts{3});
        plev = lower(parts{4}(2:end));
        modelTime = strsplit(parts{5}, '.');
        modelTime = lower(modelTime{1});
    elseif length(parts) == 4
        rcmName = lower(parts{2});
        gcmName = lower(parts{3});
        modelTime = strsplit(parts{4}, '.');
        modelTime = lower(modelTime{1});
    end

    % check for output folder and make it if it doesn't exist
    folDataTarget = [outputDir, '/', rcmName, '/', gcmName, '/', varName, plev, '/', modelTime];
    regridDataTarget = [outputDir, '/', rcmName, '/', gcmName, '/', varName, plev, '/regrid/', modelTime];
    if ~isdir(folDataTarget) & ~isdir(regridDataTarget)
        mkdir(folDataTarget);
    else
        continue;
    end
    
    dimIdLat = -1;
    dimIdLon = -1;
    dimIdTime = -1;
    dims = {};
    for i = 0:ndim-1
        [dimname, dimlen] = netcdf.inqDim(ncid,i);
        
        if length(findstr(dimname, 'yc')) ~= 0
            dimIdLat = i+1;
        end
        
        if length(findstr(dimname, 'xc')) ~= 0
            dimIdLon = i+1;
        end
        
        if length(findstr(dimname, 'time')) ~= 0
            dimIdTime = i+1;
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
        
        if length(findstr(vname, varName)) ~= 0
            varIdMain = i;
        end
        
        vars{i+1} = {vname, vtype, vdim};
    end
    
    % timestep of data, in seconds
    deltaT = 0;
    if strcmp(varName, 'tasmax') | strcmp(varName, 'tasmin') | ...
            strcmp(varName, 'spdmax')
        % 1 day time step
        deltaT = etime(datevec('24', 'HH'), datevec('00', 'HH'));
    else
        % 3 hour time step
        deltaT = etime(datevec('03', 'HH'), datevec('00', 'HH'));
    end
        
    % pull the start date out of the string
    startDate = datenum(modelTime, 'yyyymmddHH');

    lat = double(netcdf.getVar(ncid, varIdLat, [0 0], [dims{dimIdLon}{2} dims{dimIdLat}{2}]));
    lat = permute(lat, [2, 1]);

    lon = double(netcdf.getVar(ncid, varIdLon, [0 0], [dims{dimIdLon}{2} dims{dimIdLat}{2}]));
    lon = permute(lon, [2, 1]);
    
    if strcmp(rcmName, 'hrm3')
        lon = lon+360;
    end
    
    timestep = [];
    febDayCounter = 1;
    if strcmp(gcmName, 'ncep')
        % standard gregorian
        for t = 0:1:dims{dimIdTime}{2}-1
            timestep(t+1) = addtodate(startDate, t*deltaT, 'second');
        end
    elseif strcmp(gcmName, 'ccsm') | strcmp(gcmName, 'cgcm3') | strcmp(gcmName, 'gfdl') | strcmp(gcmName, 'wrfg')
        % 365 day no leap
        leapYrAcc = 0;
        for t = 0:1:dims{dimIdTime}{2}-1
            testTime = addtodate(startDate, (t+leapYrAcc)*deltaT, 'second');
            [testYr, testMonth, testDay] = datevec(testTime);
            if testMonth == 2 & testDay == 29
                leapYrAcc = leapYrAcc+1;
            end
            
            timestep(t+1) = addtodate(startDate, (t+leapYrAcc)*deltaT, 'second');
        end
    elseif strcmp(gcmName, 'hadcm3')
        % 360 day (30 days/month)
        dayAcc = 0;
        febDayCount = -1;
        for t = 0:1:dims{dimIdTime}{2}-1
            testTime = addtodate(startDate, (t+dayAcc)*deltaT, 'second');
            %[curYr, curMonth] = datevec(timestep(t));
            [nextYr, nextMonth, nextDay] = datevec(testTime);
            
            if nextMonth ~= 2 & nextDay > 30
                dayAcc = dayAcc+1;
            elseif nextMonth == 2 & nextDay >= 28
                if febDayCount == -1
                    febDayCount = nextDay;
                elseif febDayCount > 30
                    febDayCount = -1;
                else
                    dayAcc = dayAcc-1;
                    febDayCount = febDayCount+1;
                end
            end
            
            timestep(t+1) = addtodate(startDate, (t+dayAcc)*deltaT, 'second');
        end
    end
    
    
    data(:,:,:) = netcdf.getVar(ncid, varIdMain, [0, 0, 0], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, dims{dimIdTime}{2}]);
    data = permute(data, [2, 1, 3]);
    data(data>= 1.0e20) = NaN;
    
    curTime = timestep(1);
    endTime = addtodate(startDate, dims{dimIdTime}{2}*deltaT, 'second');

    while curTime < endTime
        nextTime = addtodate(curTime, 1, 'month');
        
        % find indices in the timestep matrix
        curIndex = find(timestep >= curTime, 1, 'first');
        nextIndex = find(timestep < nextTime, 1, 'last');
        
        % get monthly data
        monthlyDataSet = {lat, lon, double(data(:, :, curIndex:nextIndex))};

        % save the .mat file in the correct location and w/ the correct name
        fileName = [varName plev, '_', datestr(timestep(curIndex), 'yyyy_mm_dd')];
        eval([fileName ' = monthlyDataSet;']);
        save([folDataTarget, '/', fileName, '.mat'], fileName, '-v7.3');
        
        eval(['clear ' fileName ';']);
        clear monthlyDataSet;
        
        curTime = nextTime;
    end
    
    clear monthlyData data dims vars timestep;
    netcdf.close(ncid);
    fileCount = fileCount + 1;
end

