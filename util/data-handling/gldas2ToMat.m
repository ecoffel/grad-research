function gpcpToMat(rawNcDir, outputDir, maxNum)

varNames = ["Rainf_f_tavg", "Evap_tavg", "Qair_f_inst", "Qh_tavg", "Qle_tavg", "SoilMoi0_10cm_inst", ...
            "SoilMoi10_40cm_inst", "SoilMoi100_200cm_inst", "SWE_inst", "Tair_f_inst"];
varIds = ones(size(varNames)) .* -1;

ncFileNames = dir([rawNcDir, '/*.nc4']);
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
        
        if strcmp(dimname, 'lat')
            dimIdLat = i+1;
        end
        
        if strcmp(dimname, 'lon')
            dimIdLon = i+1;
        end
        
        if strcmp(dimname, 'time')
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
        
        for v = 1:length(varNames)
            if strcmp(vname, varNames{v})
                varIds(v) = i+1;
            end
        end
        
        if strcmp(vname, 'time')
            varIdTime = i+1;
        end
        
        vars{i+1} = {vname, vtype, vdim, vatts};
    end

    scale_factor = 1;
    add_offset = 0;
    missing_val = -9999.0;
    
    % loop over all data vars
    for v = varIds
        % over all attributes for this var
        for i = 0:vars{v}{4}-1

            attname = netcdf.inqAttName(ncid, v-1, i);
            if strcmp(attname, 'scale_factor')
                scale_factor = double(netcdf.getAtt(ncid, v-1,'scale_factor'));
            elseif strcmp(attname, 'add_offset')
                add_offset = double(netcdf.getAtt(ncid, v-1,'add_offset'));
            elseif strcmp(attname, 'missing_value')
                missing_val = double(netcdf.getAtt(ncid, v-1,'missing_value'));
            end
        end
    end
    
    lat = double(netcdf.getVar(ncid, varIdLat-1, [0], [dims{dimIdLat}{2}]));
    lon = double(netcdf.getVar(ncid, varIdLon-1, [0], [dims{dimIdLon}{2}]));
    
    [lon, lat] = meshgrid(lon, lat);
    %lat = flipud(lat);
    
    % starts at 1900 01 01 01 01 01
    starttime = datenum([1948 01 01 00 00 00]);
    
    % these are days since 1800-01-01 01:01:01
	timestep = netcdf.getVar(ncid, varIdTime-1, [0], [dims{dimIdTime}{2}]);
    time = addtodate(starttime, timestep, 'day');
    
    for v = 1:length(varNames)
        
        % check for output folder and make it if it doesn't exist
        folDataTarget = [outputDir, '/', varNames{v}];
        fileName = [varNames{v}, '_', datestr(time, 'yyyy_mm_dd')];
        
        if ~isdir(folDataTarget)
            mkdir(folDataTarget);
        elseif exist([folDataTarget '/' fileName '.mat'], 'file')
            %['skipping ' folDataTarget '/' fileName '.mat']
            %continue;
        end
        
        data = double(netcdf.getVar(ncid, varIds(v)-1, [0, 0, 0], [dims{dimIdLon}{2}, dims{dimIdLat}{2}, 1])) .* scale_factor + add_offset;
        data = permute(data, [2 1]);
        data(data == missing_val) = NaN;
        
        monthlyData = squeeze(data);

        monthlyDataSet = {lat, lon, squeeze(monthlyData)};

        % save the .mat file in the correct location and w/ the correct name
        
        eval([fileName ' = monthlyDataSet;']);
        save([folDataTarget, '/', fileName, '.mat'], fileName);

        clear monthlyDataSet;
        eval(['clear ' fileName ';']);
        
    end
    

    clear data dims vars timestep;
    netcdf.close(ncid);
    fileCount = fileCount + 1;
end

