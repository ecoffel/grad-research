
function cmip5NcToMat(rawNcDir, outputDir, varName)

    ncFileNames = dir([rawNcDir, '/', varName, '_*.nc']);
    ncFileNames = {ncFileNames.name};

    skipExistingFolders = true;

    for k = 1:length(ncFileNames)
        ncFileName = ncFileNames{k}

        if ~contains(ncFileName, 'Amon') && ~contains(ncFileName, 'Lmon')
            continue;
        end
        
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
        folDataTarget = [outputDir, '/', modelName, '/mon/', runName, '/', emissionsScenario, '/', varName, '/', startDate, '-', endDate];
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
            [vname, vtype, vdim, vatts] = netcdf.inqVar(ncid,i);

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

            if strcmp(vname, varName)
                varIdMain = i;
            end

            vars{i+1} = {vname, vtype, vdim, vatts};
        end

        % 'days since xxxx-xx-xx'
        startDate = netcdf.getAtt(ncid, varIdTime, 'units');
        startDate = strsplit(startDate, ' ');
        startDate = startDate{3};
        startDate = strsplit(startDate, '-');

        startYear = str2num(startDate{1});
        startMonth = str2num(startDate{2});
        startDay = str2num(startDate{3});

        % get the missing value param
        scale_factor = 1;
        add_offset = 0;
        missingVal = -9999;

        % get attributes
        for i = 0:vars{varIdMain+1}{4}-1
            attname = netcdf.inqAttName(ncid, varIdMain, i);
            if strcmp(attname, 'scale_factor')
                scale_factor = double(netcdf.getAtt(ncid, varIdMain,'scale_factor'));
            elseif strcmp(attname, 'add_offset')
                add_offset = double(netcdf.getAtt(ncid, varIdMain,'add_offset'));
            elseif strcmp(attname, 'missing_value')
                missingVal = double(netcdf.getAtt(ncid, varIdMain,'missing_value'));
            end
        end

        lat = double(netcdf.getVar(ncid, varIdLat, [0], [dims{dimIdLat}{2}]));
        lon = double(netcdf.getVar(ncid, varIdLon, [0], [dims{dimIdLon}{2}]));

        [lon, lat] = meshgrid(lon, lat);
        %lat = flipud(lat);

        starttime = datenum([startYear startMonth startDay 00 00 00]);
        time = [];

        % days since x
        timestep = netcdf.getVar(ncid, varIdTime, [0], [dims{dimIdTime}{2}]);
        
        noleap = false;
        
        % add on time offset to this file
        if length(findstr(rawNcDir, 'hadgem2')) > 0
            starttime = addtodate(starttime, floor(timestep(1) / 30), 'month');
        elseif length(findstr(rawNcDir, 'fgoals')) > 0
            leapyearcount = sum(leapyear(0000:year(timestep(1))));
            starttime = addtodate(starttime, (timestep(1)+leapyearcount)*24, 'hour');
            noleap = true;
        else
            starttime = addtodate(starttime, timestep(1)*24, 'hour');
        end
        
        % timestamps for all files (1 month apart)
        for t = 1:length(timestep)
            time(t) = addtodate(starttime, (t-1), 'month');
        end

        ind = 0;

        % month of last time step, so we know when to save
        curStartDate = -1;
        lastMonth = -1;
        monthlyInd = 1;
        dailyData = [];
        

        while ind < dims{dimIdTime}{2}
            % get next time step...
            data = double(netcdf.getVar(ncid, varIdMain, [0, 0, ind], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, 1]));
            data = data .* scale_factor + add_offset;
            data = squeeze(permute(data, [2 1]));
            data(data == missingVal) = NaN;

            curMonth = month(time(ind+1));

            % skip empty months (hopefully just first one)
            if length(data) == 0
                continue;
            end

            monthlyDataSet = {lat, lon, squeeze(data)};

            % save the .mat file in the correct location and w/ the correct name
            fileName = [varName, '_', datestr(time(ind+1), 'yyyy_mm_dd')];
            eval([fileName ' = monthlyDataSet;']);
            save([folDataTarget, '/', fileName, '.mat'], fileName);

            clear monthlyDataSet;
            lastMonth = curMonth;
            curStartDate = time(ind+1);
            eval(['clear ' fileName ';']);

            ind = ind + 1;
        end

        % save the final month
        monthlyDataSet = {lat, lon, flipud(squeeze(data))};
        fileName = [varName, '_', datestr(curStartDate, 'yyyy_mm_dd')];
        eval([fileName ' = monthlyDataSet;']);
        save([folDataTarget, '/', fileName, '.mat'], fileName);
        clear monthlyDataSet;
        eval(['clear ' fileName ';']);

        clear data dims vars timestep;
        netcdf.close(ncid);
    end
end

