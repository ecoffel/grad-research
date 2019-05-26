startYear = 2007;
endYear = 2018;

qsGldas = loadMonthlyData('E:\data\gldas\output\vic-1\Qs', 'Qs', 'startYear', startYear, 'endYear', endYear);
qsbGldas = loadMonthlyData('E:\data\gldas\output\vic-1\Qsb', 'Qsb', 'startYear', startYear, 'endYear', endYear);

qsGldas{3} = qsGldas{3} + qsbGldas{3};
qsGldas{2}(qsGldas{2} < 0) = 360 + qsGldas{2}(qsGldas{2} < 0);

monthLens = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
for m = 1:12
    qsGldas{3}(:, :, :, m) = qsGldas{3}(:, :, :, m) .* 3600 .* 24 .* monthLens(m);
end

plantLatLon = csvread('2019-electricity/nuke-lat-lon.csv');
plantWbTimeSeries = [];

for i = 1:size(plantLatLon, 1)
    ind = plantLatLon(i,1);
    lat = plantLatLon(i,2);
    lon = plantLatLon(i,3);
    if lon < 0
        lon = lon+360;
    end
    
    [latInd, lonInd] = latLonIndexRange(qsGldas, [lat-1.5, lat+1.5], [lon-1.5, lon+1.5]);

    qs = squeeze(nanmean(nanmean(qsGldas{3}(latInd, lonInd, :, :, :), 2), 1));
    
    curDate = datenum(startYear, 1, 1, 1, 0, 0);
    qsClean = [];
    for year = 1:length(startYear:endYear)
        for month = 1:12
            curDate = addtodate(curDate, 1, 'month');
            qsClean = [qsClean; squeeze(qs(year, month))];
        end
    end
        
    plantWbTimeSeries(i, :) = [ind, qsClean'];
end

 csvwrite('2019-electricity/nuke-qs-gldas.csv', plantWbTimeSeries);