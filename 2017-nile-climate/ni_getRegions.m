function [inds, regions, regionNames] = getRegions()

load lat;
load lon;

regionNames = {'nile', 'nile-north', 'nile-south', 'nile-blue', 'nile-white', 'nile-ethiopia'};

regionBoundsAll = [[2 32]; [25, 44]];
[latIndsNile, lonIndsNile] = latLonIndexRange({lat,lon,[]}, regionBoundsAll(1,:), regionBoundsAll(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[14.5 32]; [29, 34]];
regionBoundsBlue = [[8 14]; [34, 40]];
regionBoundsWhite = [[3 14]; [27, 33.5]];
regionBoundsEthiopia = [[3.4 14.8]; [31, 45.5]];


[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
[latIndsBlue, lonIndsBlue] = latLonIndexRange({lat,lon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhite, lonIndsWhite] = latLonIndexRange({lat,lon,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
[latIndsEthiopia, lonIndsEthiopia] = latLonIndexRange({lat,lon,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
% latIndsNorth = latIndsNorth - latIndsNile(1) + 1;
% lonIndsNorth = lonIndsNorth - lonIndsNile(1) + 1;
% latIndsSouth = latIndsSouth - latIndsNile(1) + 1;
% lonIndsSouth = lonIndsSouth - lonIndsNile(1) + 1;

keys = regionNames;
vals = {{latIndsNile, lonIndsNile}, ...
           {latIndsNorth, lonIndsNorth}, ...
           {latIndsSouth,lonIndsSouth}, ...
           {latIndsBlue, lonIndsBlue}, ...
           {latIndsWhite, lonIndsWhite}, ...
           {latIndsEthiopia, lonIndsEthiopia}};
       
inds = containers.Map(keys, vals);       
              
keys = regionNames;
vals = {regionBoundsAll, regionBoundsNorth, regionBoundsSouth, regionBoundsBlue, regionBoundsWhite, regionBoundsEthiopia};
regions = containers.Map(keys, vals);

end