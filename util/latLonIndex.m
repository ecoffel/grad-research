function [latIndex, lonIndex] = latLonIndex(data, latLonTarget)

% implmement 2-d search

latDist = data{1}-latLonTarget(1);
lonDist = data{2}-latLonTarget(2);
totalDist = abs(latDist)+abs(lonDist);

[latIndex, lonIndex] = ind2sub(size(totalDist),dsearchn(totalDist(:),0));

end