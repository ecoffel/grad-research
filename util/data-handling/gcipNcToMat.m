
function gcipNcToMat(rawNcDir, outputDir, varName)

    ncFileNames = dir([rawNcDir, '/', varName, '*.nc']);
    ncFileNames = {ncFileNames.name};

    skipExistingFolders = true;

    for k = 1:length(ncFileNames)
        ncFileName = ncFileNames{k}

        ncid = netcdf.open([rawNcDir, '/', ncFileName]);
        [ndim, nvar] = netcdf.inq(ncid);


        % check for output folder and make it if it doesn't exist
%         folDataTarget = [outputDir, '/', modelName, '/mon/', runName, '/', emissionsScenario, '/', varName, '/', startDate, '-', endDate];
%         if ~isdir(folDataTarget)
%             mkdir(folDataTarget);
%         else
%             if skipExistingFolders
%                 continue;
%             end
%         end

        dimIdLat = -1;
        dimIdLon = -1;
        dimIdTime = -1;

        dims = {};
        for i = 0:ndim-1
            [dimname, dimlen] = netcdf.inqDim(ncid,i);

            if strcmp(dimname, 'YCells')
                dimIdLat = i+1;
            end

            if strcmp(dimname, 'XCells')
                dimIdLon = i+1;
            end

            if strcmp(dimname, 'ProjectionHr')
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

            if strcmp(vname, 'latitude')
                varIdLat = i;
            end

            if strcmp(vname, 'longitude')
                varIdLon = i;
            end

            if strcmp(vname, 'ProjectionHr')
                varIdTime = i;
            end

            if strcmp(vname, 'APCP_SFC')
                varIdMain = i;
            end

            vars{i+1} = {vname, vtype, vdim, vatts};
        end

        % 'days since xxxx-xx-xx'
%         startDate = netcdf.getAtt(ncid, varIdTime, 'units');
%         startDate = strsplit(startDate, ' ');
%         startDate = startDate{3};
%         startDate = strsplit(startDate, '-');
% 
%         startYear = str2num(startDate{1});
%         startMonth = str2num(startDate{2});
%         startDay = str2num(startDate{3});
% 
%         % get the missing value param
%         scale_factor = 1;
%         add_offset = 0;
%         missingVal = -9999;
% 
%         % get attributes
%         for i = 0:vars{varIdMain+1}{4}-1
%             attname = netcdf.inqAttName(ncid, varIdMain, i);
%             if strcmp(attname, 'scale_factor')
%                 scale_factor = double(netcdf.getAtt(ncid, varIdMain,'scale_factor'));
%             elseif strcmp(attname, 'add_offset')
%                 add_offset = double(netcdf.getAtt(ncid, varIdMain,'add_offset'));
%             elseif strcmp(attname, 'missing_value')
%                 missingVal = double(netcdf.getAtt(ncid, varIdMain,'missing_value'));
%             end
%         end

        lat = double(netcdf.getVar(ncid, varIdLat, [0 0], [dims{dimIdLon}{2} dims{dimIdLat}{2}]));
        lon = double(netcdf.getVar(ncid, varIdLon, [0 0], [dims{dimIdLon}{2} dims{dimIdLat}{2}]));
        data = double(netcdf.getVar(ncid, varIdMain, [0 0 0], [dims{dimIdLon}{2} dims{dimIdLat}{2} 1]));
        
%             % get next time step...
%             data = double(netcdf.getVar(ncid, varIdMain, [0, 0, ind], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, 1]));
%             data = data .* scale_factor + add_offset;
%             data = squeeze(permute(data, [2 1]));
%             data(data == missingVal) = NaN;
% 
%             curMonth = month(time(ind+1));
% 
%             % skip empty months (hopefully just first one)
%             if length(data) == 0
%                 continue;
%             end
% 
%             monthlyDataSet = {lat, lon, squeeze(data)};
% 
%             % save the .mat file in the correct location and w/ the correct name
%             fileName = [varName, '_', datestr(time(ind+1), 'yyyy_mm_dd')];
%             eval([fileName ' = monthlyDataSet;']);
%             save([folDataTarget, '/', fileName, '.mat'], fileName);
% 
%             clear monthlyDataSet;
%             lastMonth = curMonth;
%             curStartDate = time(ind+1);
%             eval(['clear ' fileName ';']);
% 
%             ind = ind + 1;
%         end
% 
%         % save the final month
%         monthlyDataSet = {lat, lon, flipud(squeeze(data))};
%         fileName = [varName, '_', datestr(curStartDate, 'yyyy_mm_dd')];
%         eval([fileName ' = monthlyDataSet;']);
%         save([folDataTarget, '/', fileName, '.mat'], fileName);
%         clear monthlyDataSet;
%         eval(['clear ' fileName ';']);
% 
%         clear data dims vars timestep;
        netcdf.close(ncid);
    end

