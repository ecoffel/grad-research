fprintf('regridding CHIRPS...\n');
prChirps = [];

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

% load pre-processed chirps with nile region selected
for year = 1981:1:2016
    fprintf('processing CHIRPS year %d...\n', year);
    load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\pr-monthly-chirps-' num2str(year) '-largeArea.mat']);
    for month = 1:12
        prRegrid = regridGriddata({flipud(chirpsPr{1}), chirpsPr{2}, flipud(chirpsPr{3}(:, :, month))}, {lat(latInds, lonInds), lon(latInds, lonInds), []}, false, false);
        prChirps(:, :, year-1981+1, month) = prRegrid{3};
    end 
end
save(['C:\git-ecoffel\grad-research\2017-nile-climate\output\pr-monthly-chirps-regrid.mat'], 'prChirps');
