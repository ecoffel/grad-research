load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

coordPairs = [];
i = 1;
for la = latInds
    for lo = lonInds
        coordPairs(i, :) = [la, lo];
        i = i+1;
    end
end

f = fopen('ni-region.txt','w');
for i = 1:size(coordPairs,1)
    fprintf(f,'%d,%d\r\n',coordPairs(i,1),coordPairs(i,2));
end

