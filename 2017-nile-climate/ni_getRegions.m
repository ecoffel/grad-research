function [inds, regions, regionNames] = getRegions()

load lat;
load lon;

regionNames = {'nile', 'nile-north', 'nile-south'};

regionBounds = [[2 32]; [25, 44]];
[latIndsNile, lonIndsNile] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
% latIndsNorth = latIndsNorth - latIndsNile(1) + 1;
% lonIndsNorth = lonIndsNorth - lonIndsNile(1) + 1;
% latIndsSouth = latIndsSouth - latIndsNile(1) + 1;
% lonIndsSouth = lonIndsSouth - lonIndsNile(1) + 1;


keys = regionNames;
vals = {{latIndsNile, lonIndsNile}, ...
           {latIndsNorth, lonIndsNorth}, ...
           {latIndsSouth lonIndsSouth}};
inds = containers.Map(keys, vals);
       
              
keys = regionNames;
vals = {regionBounds, regionBoundsNorth, regionBoundsSouth};
regions = containers.Map(keys, vals);

end