startYear = 2015;
endYear = 2018;


qsGldas = loadMonthlyData('E:\data\gldas\output\vic-1\Qs', 'Qs', 'startYear', startYear, 'endYear', endYear);
qsbGldas = loadMonthlyData('E:\data\gldas\output\vic-1\Qsb', 'Qsb', 'startYear', startYear, 'endYear', endYear);

qsGldas{3} = qsGldas{3} + qsbGldas{3};
qsGldas{2}(qsGldas{2} < 0) = 360 + qsGldas{2}(qsGldas{2} < 0);

monthLens = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
for m = 1:12
    qsGldas{3}(:, :, :, m) = qsGldas{3}(:, :, :, m) .* 3600 .* 24 .* monthLens(m);
end

plantLatLon = csvread('2019-electricity/entsoe-lat-lon.csv');
plantTxTimeSeries = [];

for i = 1:size(plantLatLon, 1)
    ind = plantLatLon(i,1);
    lat = plantLatLon(i,2);
    lon = plantLatLon(i,3);
    if lon < 0
        lon = lon+360;
    end
    

%     [latInd, lonInd] = latLonIndex(temp, [lat, lon]);
    [latInd, lonInd] = latLonIndexRange(qsGldas, [lat-.5 lat+.5], [lon-.5 lon+.5]);
%     [latInd, lonInd] = latLonIndexRange(temp, [lat-.5 lat+.5], [lon-.5 lon+.5]);


    qs = squeeze(nanmean(nanmean(qsGldas{3}(latInd, lonInd, :, :), 2), 1));
    
    curDate = datenum(startYear, 1, 1, 1, 0, 0);
    qsClean = [];
    qsYears = [];
    qsMonths = [];
    qsDays = [];
    
    yr = startYear;
    
    while yr < 2019
        dv = datevec(curDate);
        
        yr = dv(1);
        mn = dv(2);
        dy = dv(3);
        
        if yr > endYear
            break
        end
        
        qsYears(end+1) = yr;
        qsMonths(end+1) = mn;
        qsDays(end+1) = dy;
        qsClean(end+1) = qs(yr-startYear+1, mn);
        curDate = addtodate(curDate, 1, 'day');
    end
        
    if i == 1
        plantTxTimeSeries(1, :) = qsYears;
        plantTxTimeSeries(2, :) = qsMonths;
        plantTxTimeSeries(3, :) = qsDays;
    end
    
    plantTxTimeSeries(end+1,:) = qsClean;
end

csvwrite('2019-electricity/entsoe-qs-gldas.csv', plantTxTimeSeries);
