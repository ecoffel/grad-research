function [latIndexRange, lonIndexRange] = latLonIndexRange(data, latRange, lonRange)

[latIndex1, lonIndex1] = latLonIndex(data, [latRange(1), lonRange(1)]);
[latIndex2, lonIndex2] = latLonIndex(data, [latRange(2), lonRange(2)]);

latIndexRange = [latIndex1:latIndex2];

if lonIndex1 <= lonIndex2
    lonIndexRange = [lonIndex1:lonIndex2];
else
    lonIndexRange = [lonIndex1:size(data{2},2), 1:lonIndex2];
end

end