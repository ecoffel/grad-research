dataDir = 'e:/data/ecoffel/data/projects/green-water/sacks/';

sacksLat = [];
sacksLon = [];
sacksEndOfPlanting = [];
sacksStartOfHarvest = [];

crops = {'Maize', 'Soybeans', 'Rice', 'Wheat'};

for c = 1:length(crops)

    ncid = netcdf.open([dataDir crops{c} '.crop.calendar.fill.nc']);
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
    varIdPlantEnd = 0;
    varIdHarvestStart = 0;
    
    vars = {};
    for i = 0:nvar-1
        [vname, vtype, vdim, vatts] = netcdf.inqVar(ncid,i);

        if strcmp(vname, 'latitude')
            varIdLat = i+1;
        end

        if strcmp(vname, 'longitude')
            varIdLon = i+1;
        end

        if strcmp(vname, 'plant.end')
            varIdPlantEnd = i+1;
        end
        
        if strcmp(vname, 'harvest.start')
            varIdHarvestStart = i+1;
        end

        vars{i+1} = {vname, vtype, vdim, vatts};
    end


    lat = double(netcdf.getVar(ncid, varIdLat-1, [0], [dims{dimIdLat}{2}]));
    lon = double(netcdf.getVar(ncid, varIdLon-1, [0], [dims{dimIdLon}{2}]));

    [lon, lat] = meshgrid(lon, lat);

    if length(sacksLat) == 0
        sacksLat = lat;
        sacksLon = lon;
    end

    plantingEnd = double(netcdf.getVar(ncid, varIdPlantEnd-1, [0, 0], [dims{dimIdLon}{2}, dims{dimIdLat}{2}]))';
    plantingEnd(plantingEnd > 1000) = NaN;
    
    harvestStart = double(netcdf.getVar(ncid, varIdHarvestStart-1, [0, 0], [dims{dimIdLon}{2}, dims{dimIdLat}{2}]))';
    harvestStart(harvestStart > 1000) = NaN;
    

    calendar = {sacksLat, sacksLon, plantingEnd, harvestStart};
    save(['2019-green-water/sacks-' crops{c} '.mat'], 'calendar');

end


