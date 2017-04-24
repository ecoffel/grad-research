%load('C:\Users\Ethan\Dropbox\School\Graduate School\Projects\2015-beetles\2015-beetles-paper\figures\tcrit-diff\toe-multi-run-mean--16-diff-model-range.mat');
load('toe-multi-run-mean--16-model-range');

spbLat = saveData.data{1};
spbLon = saveData.data{2};
data = saveData.data{3};

load lat;
load lon;
load waterGrid;

latBounds = [36 50];
lonBounds = [-90 -60] + 360;

[latInd, lonInd] = latLonIndexRange({lat, lon, []}, [min(min(spbLat)) max(max(spbLat))], [min(min(spbLon)) max(max(spbLon))]);

neWater = waterGrid(latInd, lonInd);

for xlat = 1:size(data, 1)
    for ylon = 1:size(data, 2)
        if neWater(xlat, ylon)
            data(xlat, ylon) = NaN;
        end
    end
end


['spatial TOE average = ' num2str(nanmean(nanmean(data)))]
