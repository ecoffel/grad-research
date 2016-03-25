% TODO:
% 1. Automatically identify deltaT
% 2. Fix missing data at lon = 0

function cmip5NcToMat(rawNcDir, outputDir, varName, maxNum)

ncFileNames = dir([rawNcDir, '/', varName, '_*.nc']);
ncFileNames = {ncFileNames.name};

fileCount = 0;
yearStep = 10;

skipExistingFolders = true;
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
    
    % check for output folder and make it if it doesn't exist
    folDataTarget = [outputDir, '/', modelName, '/', runName, '/', emissionsScenario, '/', varName, '/', startDate, '-', endDate];
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
        
        if length(findstr(dimname, 'lev')) ~= 0
            dimIdLev = i+1;
        end
        
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

    varIdPLev = 0;
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
        
        if length(findstr(vname, 'plev')) ~= 0
            varIdPLev = i;
        end
        
        if length(findstr(vname, varName)) ~= 0
            varIdMain = i;
        end
        
        vars{i+1} = {vname, vtype, vdim};
    end
    
    % 24 hr timestep
    deltaT = etime(datevec('24', 'HH'), datevec('00', 'HH'));
        
    % pull the start date out of the string
    startDate = datenum(startDate, 'yyyymmdd');
    endDate = datenum(endDate, 'yyyymmdd');

    lat = double(netcdf.getVar(ncid, varIdLat, [0 0], [1 dims{dimIdLat}{2}]));
    lon = double(netcdf.getVar(ncid, varIdLon, [0 0], [1 dims{dimIdLon}{2}]));
    
    [lon, lat] = meshgrid(lon, lat);
    
    timestep = [];
    febDayCounter = 1;
    curYearIndex = 1;
    calType = -1;
    
    if length(findstr(modelName, 'ncep')) ~= 0 | ...
       length(findstr(modelName, 'mpi')) ~= 0 | ...
       length(findstr(modelName, 'cmcc')) ~= 0 | ...
       length(findstr(modelName, 'cnrm')) ~= 0 | ...
       length(findstr(modelName, 'miroc')) ~= 0 | ...
       length(findstr(modelName, 'mri')) ~= 0 | ...
       length(findstr(modelName, 'ec')) ~= 0
        calType = 1;
        
        % standard gregorian
        for t = 0:1:dims{dimIdTime}{2}-1
            timestep(t+1) = addtodate(startDate, t*deltaT, 'second');
        end
        
        yearDays = [];
        
        startDateVec = datevec(startDate);
        endDateVec = datevec(endDate);
        for y = startDateVec(1):endDateVec(1)
            yearDays(end+1) = yeardays(y);
        end
        
        curTimeStepStart = 0;
        curTimeStepEnd = 0;
        for y = 1:min(length(yearDays), yearStep)
            curTimeStepEnd = curTimeStepEnd + yearDays(y)*(deltaT / (3600*24));
        end
    elseif length(findstr(modelName, 'ccsm')) ~= 0 | ...
           length(findstr(modelName, 'cgcm')) ~= 0 | ...
           length(findstr(modelName, 'gfdl')) ~= 0 | ...
           length(findstr(modelName, 'cesm')) ~= 0 | ...
           length(findstr(modelName, 'can')) ~= 0 | ...
           length(findstr(modelName, 'nor')) ~= 0 | ...
           length(findstr(modelName, 'bnu')) ~= 0 | ...
           length(findstr(modelName, 'ipsl')) ~= 0 | ...
           length(findstr(modelName, 'csiro')) ~= 0 | ...
           length(findstr(modelName, 'inmcm')) ~= 0
        calType = 2;
        
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
        
        curTimeStepStart = 0;
        curTimeStepEnd = yearStep / (deltaT / (3600*24*365));
    elseif length(findstr(modelName, 'hadcm3')) ~= 0 | ...
           length(findstr(modelName, 'hadgem2')) ~= 0
        calType = 3;
        
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
        
        curTimeStepStart = 0;
        curTimeStepEnd = yearStep / (deltaT / (3600*24*360));
    end
    
    while curTimeStepStart < length(timestep)
    
        if dimIdLev ~= -1
            data(:,:,:,:) = single(netcdf.getVar(ncid, varIdMain, [0, 0, 0, curTimeStepStart], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, dims{dimIdLev}{2}, min(curTimeStepEnd-curTimeStepStart, dims{dimIdTime}{2}-curTimeStepStart)]));
            data = permute(data, [2 1 3 4]);
            
            plevs = single(netcdf.getVar(ncid, varIdPLev, 0, dims{dimIdLev}{2}));
        else
            data(:,:,:) = single(netcdf.getVar(ncid, varIdMain, [0, 0, curTimeStepStart], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, min(curTimeStepEnd-curTimeStepStart, dims{dimIdTime}{2}-curTimeStepStart)]));
            data = permute(data, [2 1 3]);
        end

        curTime = timestep(curTimeStepStart+1);
        endTime = timestep(min(curTimeStepEnd+1, length(timestep))); %addtodate(startDate, (curTimeStepEnd+1)*deltaT, 'second');

        startIndex = find(timestep >= curTime, 1, 'first');
        while curTime < endTime
            nextTime = addtodate(curTime, 1, 'month');

            % find indices in the timestep matrix
            curIndex = find(timestep >= curTime, 1, 'first');
            nextIndex = find(timestep < nextTime, 1, 'last');
            
            if length(datestr(timestep(curIndex), 'yyyy_mm_dd')) == 0
                break;
            end
            fileName = [varName, '_', datestr(timestep(curIndex), 'yyyy_mm_dd')];
            
            if skipExistingFiles
                if exist(fileName, 'file')
                    continue;
                end
            end
            
            % get monthly data
            monthlyData = [];
            
            if dimIdLev ~= -1
                timeIndexRange = (curIndex-startIndex+1:min(size(data, 4), nextIndex-startIndex+1));
                monthlyData = data(:, :, :, timeIndexRange);
                monthlyDataSet = {lat, lon, double(monthlyData), plevs};
            else
                timeIndexRange = (curIndex-startIndex+1:min(size(data, 3), nextIndex-startIndex+1));
                monthlyData = data(:, :, timeIndexRange);
                monthlyDataSet = {lat, lon, double(monthlyData)};
            end
            
            % save the .mat file in the correct location and w/ the correct name
            if size(monthlyData, 3) > 0 | length(datestr(timestep(curIndex))) > 0
                eval([fileName ' = monthlyDataSet;']);
                save([folDataTarget, '/', fileName, '.mat'], fileName);
                eval(['clear ' fileName ';']);
            end
            
            clear monthlyDataSet monthlyData;

            curTime = nextTime;
        end
        curYearIndex = curYearIndex+yearStep;
        
        % fix the curTimeStepEnd point. it must not be > size(timestep)
        curTimeStepStart = curTimeStepStart + size(data, length(size(data)));
        if calType == 1
            for y = curYearIndex:curYearIndex+yearStep
                curTimeStepEnd = curTimeStepEnd + yearDays(y-curYearIndex+1)*(deltaT / (3600*24));
                if curTimeStepEnd > length(timestep)
                    curTimeStepEnd = length(timestep);
                    break;
                end
            end
        elseif calType == 2
            curTimeStepEnd = curTimeStepEnd + yearStep / (deltaT / (3600*24*365));
            if curTimeStepEnd > length(timestep)
                curTimeStepEnd = length(timestep);
            end
        elseif calType == 3
            curTimeStepEnd = curTimeStepEnd + yearStep / (deltaT / (3600*24*360));
            if curTimeStepEnd > length(timestep)
                curTimeStepEnd = length(timestep);
            end
        end
        
        clear data;
    end
    
    clear dims vars timestep;
    netcdf.close(ncid);
    fileCount = fileCount + 1;
end

