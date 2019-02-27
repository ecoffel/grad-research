largeArea = false;
monthly = false;

% this is to allow for regridding to the 2 degree grid
if largeArea
    regionBounds = [[-1 36]; [22, 47]]; 
else
    regionBounds = [[2 32]; [25, 44]];
end

baseDir = '2017-nile-climate/output/';
baseDir = 'E:\data\projects\seasonality';

regionBounds = [[30 55]; [-125, -65]+360]

fprintf('loading CPC...\n');
for year = 1980:1:2016
    fprintf('cpc year %d...\n', year);
    cpcTemp = {};
    curcpc = loadDailyData('E:\data\cpc-temp\output\tmax\regrid\world', 'startYear', year, 'endYear', year);
    
    if monthly
        curcpc = dailyToMonthly(curcpc);
    end
    
    latCpc = curcpc{1};
    lonCpc = curcpc{2};
    
    if year == 1981
        save([baseDir '/lat-cpc.mat'], 'latCpc');
        save([baseDir '/lon-cpc.mat'], 'lonCpc');
    end
    
    [latInds, lonInds] = latLonIndexRange({latCpc,lonCpc,[]}, regionBounds(1,:), regionBounds(2,:));
    
    cpcTemp = {curcpc{1}(latInds, lonInds), curcpc{2}(latInds, lonInds), squeeze(curcpc{3}(latInds, lonInds, :, :))};
    
    if largeArea
        save([baseDir '/temp-monthly-cpc-' num2str(year) '-largeArea.mat'], 'cpcTemp');
    else
        save([baseDir '/tmin-monthly-cpc-' num2str(year) '.mat'], 'cpcTemp');
    end
    clear curcpc cpcTemp;
end