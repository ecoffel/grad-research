largeArea = true;

% this is to allow for regridding to the 2 degree grid
if largeArea
    regionBounds = [[0 36]; [22, 47]]; 
else
    regionBounds = [[2 32]; [25, 44]];
end
monthLengths = [31 28 31 30 31 30 31 31 30 31 30 31];
fprintf('loading CHIRPS...\n');
for year = 1981:1:2016
    fprintf('chirps year %d...\n', year);
    chirpsPr = {};
    curchirps = loadMonthlyData('E:\data\chirps-v2\output\precip\monthly', 'precip', 'startYear', year, 'endYear', year);
    
    % convert to mean mm/day
    for month = 1:12
        curchirps{3}(:,:,:,month) = curchirps{3}(:,:,:,month) ./ monthLengths(month);
    end
    latChirps = curchirps{1};
    lonChirps = curchirps{2};
    
%     if year == 1981
%         save('lat-chirps.mat', 'latChirps');
%         save('lon-chirps.mat', 'lonChirps');
%     end
    
    [latInds, lonInds] = latLonIndexRange({latChirps,lonChirps,[]}, regionBounds(1,:), regionBounds(2,:));
    
    chirpsPr = {curchirps{1}(latInds, lonInds), curchirps{2}(latInds, lonInds), squeeze(curchirps{3}(latInds, lonInds, :, :))};
    
    if largeArea
        save(['2017-nile-climate/output/pr-monthly-chirps-' num2str(year) '-largeArea.mat'], 'chirpsPr');
    else
        save(['2017-nile-climate/output/pr-monthly-chirps-' num2str(year) '.mat'], 'chirpsPr');
    end
    clear curchirps chirpsPr;
end