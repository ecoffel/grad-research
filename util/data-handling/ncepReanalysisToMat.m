%  levels =
%   1      1000
%   2       925
%   3       850
%   4       700
%   5       600
%   6       500
%   7       400
%   8       300
%   9       250
%   10      200
%   11      150
%   12      100
%   13      70
%   14      50
%   15      30
%   16      20
%   17      10

function ncepReanalysisToMat(rawNcDir, outputDir, varName, maxNum, selLev)

ncFileNames = dir([rawNcDir, '/', varName, '*.nc']);
ncFileNames = {ncFileNames.name};

fileCount = 0;

for k = 1:length(ncFileNames)
    if fileCount >= maxNum & maxNum ~= -1
        return
    end
    
    monthly = false;
    weekly = false;
    x4 = false;
    
    ncFileName = ncFileNames{k}
    
    if findstr(ncFileName, 'wkmean')
        weekly = true;
    %------------------- TEST HERE FOR MONTHLY FILES ---------------------
    elseif false
        
    end
    
    ncid = netcdf.open([rawNcDir, '/', ncFileName]);
    [ndim, nvar, natts] = netcdf.inq(ncid);

    varName = '';
    year = '';
    
    % pull data out of the nc file name
    parts = strsplit(ncFileName, '/');
    parts = parts(end);
    parts = strsplit(parts{1}, '.');

    %if length(parts) == 3
    if strcmp(parts{1}, 'soilw') && strcmp(parts{2}, '0-10cm')
        varName = 'soilw10';
    else
        varName = lower(parts{1});
    end
    year = lower(parts{end-1});
    
    if weekly
        yearParts = strsplit(year, '-');
        year = yearParts{1};
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
        
        if strcmp(vname, 'level')
            varIdLev = i+1;
        end
        
        if strcmp(vname, 'time')
            varIdTime = i+1;
        end
        
        vars{i+1} = {vname, vtype, vdim, vatts};
    end

    scale_factor = 1;
    add_offset = 0;
    
    for i = 0:vars{varIdMain}{4}-1
        attname = netcdf.inqAttName(ncid, varIdMain-1, i);
        if strcmp(attname, 'scale_factor')
            scale_factor = double(netcdf.getAtt(ncid, varIdMain-1,'scale_factor'));
        elseif strcmp(attname, 'add_offset')
            add_offset = double(netcdf.getAtt(ncid, varIdMain-1,'add_offset'));
        end
    end
    
    deltaT = 0;
    
    % start at jan 1 of the file year
    if monthly
        startDate = datenum(1979, 1, 1, 0, 0, 0);
    elseif weekly
        startDate = addtodate(netcdf.getVar(ncid, varIdTime-1, [0], [1]), 1800, 'year');
    else
        startDate = datenum(double(str2num(year)), 1, 1, 0, 0, 0);
    end
    
    % find timestep
    
    % we are monthly
    if monthly
        deltaT = etime(datevec('1', 'mm'), datevec('00', 'mm'));
    elseif weekly
        deltaT = etime(datevec('07', 'dd'), datevec('00', 'dd'));
    else
        % either daily or 4x daily
        if length(findstr('4x', atts{attIdTitle}{2})) ~= 0
            % 6 hr timestep
            deltaT = etime(datevec('6', 'HH'), datevec('00', 'HH'));
            x4 = true;
        elseif length(findstr('daily', atts{attIdTitle}{2})) ~= 0
            deltaT = etime(datevec('24', 'HH'), datevec('00', 'HH'));
        else
            deltaT = etime(datevec('24', 'HH'), datevec('00', 'HH'));
        end
    end

    % check for output folder and make it if it doesn't exist
    if monthly
        folDataTarget = [outputDir, '/', varName, '/monthly', year];
    elseif weekly
        folDataTarget = [outputDir, '/', varName, '/weekly/', year];
    elseif x4
        folDataTarget = [outputDir, '/', varName, '/x4/', year];
    else
        folDataTarget = [outputDir, '/', varName, '/', year];
    end
    
    if ~isdir(folDataTarget)
        mkdir(folDataTarget);
    else
        %continue;
    end
    
    lat = double(netcdf.getVar(ncid, varIdLat-1, [0], [dims{dimIdLat}{2}]));
    lon = double(netcdf.getVar(ncid, varIdLon-1, [0], [dims{dimIdLon}{2}]));
    
    [lon, lat] = meshgrid(lon, lat);
    lat = flipud(lat);
    
    timestep = [];
    for t = 0:1:dims{dimIdTime}{2}-1
        timestep(t+1) = addtodate(startDate, t*deltaT, 'second');
    end

    if dimIdLev ~= -1
        data(:,:,:,:) = netcdf.getVar(ncid, varIdMain-1, [0, 0, selLev(1), 0], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, selLev(end), dims{dimIdTime}{2}]);
        data = permute(data, [2 1 3 4]);
    else
        data(:,:,:) = netcdf.getVar(ncid, varIdMain-1, [0, 0, 0], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, dims{dimIdTime}{2}]);
        data = permute(data, [2 1 3]);
        %data = flipud(data);
    end
    
    curTime = timestep(1);
    
    if weekly
        
        % if we are daily or sub daily, separate into monthly files
        endTime = addtodate(startDate, dims{dimIdTime}{2}*deltaT, 'second');
        
        % ---- THIS LOOP NOT NEEDED BUT DOESN'T HURT... -----
        while curTime < endTime
            nextTime = addtodate(curTime, 7, 'day');

            % find indices in the timestep matrix
            curIndex = find(timestep >= curTime, 1, 'first');
            nextIndex = find(timestep < nextTime, 1, 'last');

            % get monthly data
            weeklyData = [];
            if dimIdLev ~= -1
                weeklyData = double(data(:, :, :, curIndex:nextIndex))*scale_factor + add_offset;  
            else
                weeklyData = double(data(:, :, curIndex:nextIndex))*scale_factor + add_offset;
            end
            
            weeklyData(:,:) = flipud(squeeze(weeklyData(:,:)));
            
            weeklyDataSet = {lat, lon, squeeze(weeklyData)};
            
            % save the .mat file in the correct location and w/ the correct name
            fileName = [varName, '_', datestr(timestep(curIndex), 'yyyy_mm_dd')];
            eval([fileName ' = weeklyDataSet;']);
            save([folDataTarget, '/', fileName, '.mat'], fileName);

            curTime = nextTime;
            clear weeklyData weeklyDataSet;
            eval(['clear ' fileName ';']);
        end
        
    elseif monthly
        % for monthly data we will export a single mat file with the full
        % dataset
        endTime = addtodate(startDate, dims{dimIdTime}{2}*deltaT, 'month');
        
        if dimIdLev ~= -1
            monthlyData = double(data(:, :, :, :))*scale_factor + add_offset;  
            
            for d=1:size(monthlyData, 4)
                for l = 1:size(monthlyData, 3)
                    monthlyData(:,:,l,d) = flipud(squeeze(monthlyData(:,:,l,d)));
                end
            end
            
        else
            monthlyData = double(data(:, :, :))*scale_factor + add_offset;
            
            for d=1:size(monthlyData,4)
                monthlyData(:,:,d) = flipud(squeeze(monthlyData(:,:,d)));
            end
        end
        
        monthlyDataSet = {lat, lon, squeeze(monthlyData)};
        
        % save the .mat file in the correct location and w/ the correct name
        fileName = [varName, '_mon_', datestr(startDate, 'yyyy_mm_dd')];
        eval([fileName ' = monthlyDataSet;']);
        save([folDataTarget, '/', fileName, '.mat'], fileName);

        clear monthlyData monthlyDataSet;
        eval(['clear ' fileName ';']);
        
    else
        
        % if we are daily or sub daily, separate into monthly files
        endTime = addtodate(startDate, dims{dimIdTime}{2}*deltaT, 'second');
        
        while curTime < endTime
            nextTime = addtodate(curTime, 1, 'month');

            % find indices in the timestep matrix
            curIndex = find(timestep >= curTime, 1, 'first');
            nextIndex = find(timestep < nextTime, 1, 'last');

            % get monthly data
            monthlyData = [];
            if dimIdLev ~= -1
                monthlyData = double(data(:, :, :, curIndex:nextIndex))*scale_factor + add_offset;  
                for d=1:size(monthlyData,length(size(monthlyData)))
                    monthlyData(:,:,:,d) = flipud(squeeze(monthlyData(:,:,:,d)));
                end
            else
                monthlyData = double(data(:, :, curIndex:nextIndex))*scale_factor + add_offset;
                
                for d=1:size(monthlyData,length(size(monthlyData)))
                    monthlyData(:,:,d) = flipud(squeeze(monthlyData(:,:,d)));
                end
            end
            
            monthlyData = squeeze(monthlyData);

            monthlyDataSet = {lat, lon, squeeze(monthlyData)};

            % save the .mat file in the correct location and w/ the correct name
            fileName = [varName, '_', datestr(timestep(curIndex), 'yyyy_mm_dd')];
            eval([fileName ' = monthlyDataSet;']);
            save([folDataTarget, '/', fileName, '.mat'], fileName);

            curTime = nextTime;
            clear monthlyData monthlyDataSet;
            eval(['clear ' fileName ';']);
        end
    end

    clear data dims vars timestep;
    netcdf.close(ncid);
    fileCount = fileCount + 1;
end

