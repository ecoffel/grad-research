startYear = 2015;
endYear = 2018;

qsGldasVic = loadMonthlyData('E:\data\gldas\output\vic-1\Qs', 'Qs', 'startYear', startYear, 'endYear', endYear);
qsbGldasVic = loadMonthlyData('E:\data\gldas\output\vic-1\Qsb', 'Qsb', 'startYear', startYear, 'endYear', endYear);
qsGldasVic{3} = qsGldasVic{3} + qsbGldasVic{3};
qsGldasVic{2}(qsGldasVic{2} < 0) = 360 + qsGldasVic{2}(qsGldasVic{2} < 0);


qsGldasNoah = loadMonthlyData('E:\data\gldas\output\noah-1-1979-2018\Qs', 'Qs', 'startYear', startYear, 'endYear', endYear);
qsbGldasNoah = loadMonthlyData('E:\data\gldas\output\noah-1-1979-2018\Qsb', 'Qsb', 'startYear', startYear, 'endYear', endYear);
qsGldasNoah{3} = qsGldasNoah{3} + qsbGldasNoah{3};
qsGldasNoah{2}(qsGldasNoah{2} < 0) = 360 + qsGldasNoah{2}(qsGldasNoah{2} < 0);


qsGldasMosaic = loadMonthlyData('E:\data\gldas\output\mosaic-1-1979-2018\Qs', 'Qs', 'startYear', startYear, 'endYear', endYear);
qsbGldasMosaic = loadMonthlyData('E:\data\gldas\output\mosaic-1-1979-2018\Qsb', 'Qsb', 'startYear', startYear, 'endYear', endYear);
qsGldasMosaic{3} = qsGldasMosaic{3} + qsbGldasMosaic{3};
qsGldasMosaic{2}(qsGldasMosaic{2} < 0) = 360 + qsGldasMosaic{2}(qsGldasMosaic{2} < 0);

monthLens = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
for m = 1:12
    qsGldasVic{3}(:, :, :, m) = qsGldasVic{3}(:, :, :, m) .* 3600 .* 24 .* monthLens(m);
    qsGldasNoah{3}(:, :, :, m) = qsGldasNoah{3}(:, :, :, m) .* 3600 .* 24 .* monthLens(m);
    qsGldasMosaic{3}(:, :, :, m) = qsGldasMosaic{3}(:, :, :, m) .* 3600 .* 24 .* monthLens(m);
end

plantLatLon = csvread('2019-electricity/entsoe-lat-lon-nonforced.csv');
plantTxTimeSeries = [];

for i = 1:size(plantLatLon, 1)
    ind = plantLatLon(i,1);
    lat = plantLatLon(i,2);
    lon = plantLatLon(i,3);
    if lon < 0
        lon = lon+360;
    end
    
    [latGldasInd, lonGldasInd] = latLonIndexRange(qsGldasVic, [lat-.5, lat+.5], [lon-.5, lon+.5]);
    qsVic = squeeze(nanmean(nanmean(qsGldasVic{3}(latGldasInd, lonGldasInd, :, :), 2), 1));
    qsNoah = squeeze(nanmean(nanmean(qsGldasNoah{3}(latGldasInd, lonGldasInd, :, :), 2), 1));
    qsMosaic = squeeze(nanmean(nanmean(qsGldasMosaic{3}(latGldasInd, lonGldasInd, :, :), 2), 1));

    qs = (qsVic + qsNoah + qsMosaic) ./ 3;

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
        qsClean(end+1) = qs(yr-startYear+1, mn)/nanmean(qs(:,mn));
        curDate = addtodate(curDate, 1, 'day');
    end
        
    if i == 1
        plantTxTimeSeries(1, :) = qsYears;
        plantTxTimeSeries(2, :) = qsMonths;
        plantTxTimeSeries(3, :) = qsDays;
    end
    
    plantTxTimeSeries(end+1,:) = qsClean;
end

csvwrite('2019-electricity/entsoe-qs-gldas-all-nonforced-perc.csv', plantTxTimeSeries);
