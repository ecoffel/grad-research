dataDir = 'e:/data/ecoffel/data/projects/green-water/iizumi/wheat/';

iizumiLat = [];
iizumiLon = [];
iizumiMaizeYield = [];

for year = 1981:2011
    ncid = netcdf.open([dataDir, 'yield_' num2str(year) '.nc4']);
    [ndim, nvar, natts] = netcdf.inq(ncid);

    yearStr = '';
    
    dimIdLat = -1;
    dimIdLon = -1;
    
    dims = {};
    for i = 0:ndim-1
        [dimname, dimlen] = netcdf.inqDim(ncid,i);
        
        if length(findstr(dimname, 'lat')) ~= 0
            dimIdLat = i+1;
        end
        
        if length(findstr(dimname, 'lon')) ~= 0
            dimIdLon = i+1;
        end
        
        dims{i+1} = {dimname, dimlen};
    end
    
    varIdLat = 0;
    varIdLon = 0;
    varIdMain = 0;
    
    vars = {};
    for i = 0:nvar-1
        [vname, vtype, vdim, vatts] = netcdf.inqVar(ncid,i);
        
        if strcmp(vname, 'lat')
            varIdLat = i+1;
        end
        
        if strcmp(vname, 'lon')
            varIdLon = i+1;
        end
        
        if strcmp(vname, 'var')
            varIdMain = i+1;
        end
        
        vars{i+1} = {vname, vtype, vdim, vatts};
    end

    
    lat = double(netcdf.getVar(ncid, varIdLat-1, [0], [dims{dimIdLat}{2}]));
    lon = double(netcdf.getVar(ncid, varIdLon-1, [0], [dims{dimIdLon}{2}]));
    
    [lon, lat] = meshgrid(lon, lat);
    
    if length(iizumiLat) == 0
        iizumiLat = lat;
        iizumiLon = lon;
    end
    
    yield = double(netcdf.getVar(ncid, varIdMain-1, [0, 0], [dims{dimIdLon}{2}, dims{dimIdLat}{2}]))';
    yield(yield < 0) = NaN;
    
    iizumiYield(:, :, year-1981+1) = yield;
    
end

iizumiWheat = {iizumiLat, iizumiLon, iizumiYield};
save('2019-green-water/iizumiWheat.mat', 'iizumiWheat');

