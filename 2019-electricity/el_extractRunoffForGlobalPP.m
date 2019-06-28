
startYear = 1981;
endYear = 2018;

% plantLatLon = csvread('2019-electricity/entsoe-nuke-lat-lon.csv');
plantLatLon = csvread('2019-electricity/global-pp-lat-lon-all-cap.csv');

plantQsTimeSeries = [];

for y = startYear:endYear

    curPlantQsTimeSeries = [];
    
    fprintf('processing %d\n', y)
    
    qsGldasVic = loadMonthlyData('E:\data\gldas\output\vic-1\Qs', 'Qs', 'startYear', y, 'endYear', y);
    qsbGldasVic = loadMonthlyData('E:\data\gldas\output\vic-1\Qsb', 'Qsb', 'startYear', y, 'endYear', y);
    qsGldasVic{3} = qsbGldasVic{3} + qsbGldasVic{3};
    qsGldasVic{2}(qsGldasVic{2} < 0) = 360 + qsGldasVic{2}(qsGldasVic{2} < 0);
    
    
    qsGldasNoah = loadMonthlyData('E:\data\gldas\output\noah-1-1979-2018\Qs', 'Qs', 'startYear', y, 'endYear', y);
    qsbGldasNoah = loadMonthlyData('E:\data\gldas\output\noah-1-1979-2018\Qsb', 'Qsb', 'startYear', y, 'endYear', y);
    qsGldasNoah{3} = qsbGldasNoah{3} + qsbGldasNoah{3};
    qsGldasNoah{2}(qsGldasNoah{2} < 0) = 360 + qsGldasNoah{2}(qsGldasNoah{2} < 0);
    
    
    qsGldasMosaic = loadMonthlyData('E:\data\gldas\output\mosaic-1-1979-2018\Qs', 'Qs', 'startYear', y, 'endYear', y);
    qsbGldasMosaic = loadMonthlyData('E:\data\gldas\output\mosaic-1-1979-2018\Qsb', 'Qsb', 'startYear', y, 'endYear', y);
    qsGldasMosaic{3} = qsbGldasMosaic{3} + qsbGldasMosaic{3};
    qsGldasMosaic{2}(qsGldasMosaic{2} < 0) = 360 + qsGldasMosaic{2}(qsGldasMosaic{2} < 0);

    monthLens = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    for m = 1:12
        qsGldasVic{3}(:, :, :, m) = qsGldasVic{3}(:, :, :, m) .* 3600 .* 24 .* monthLens(m);
        qsGldasNoah{3}(:, :, :, m) = qsGldasNoah{3}(:, :, :, m) .* 3600 .* 24 .* monthLens(m);
        qsGldasMosaic{3}(:, :, :, m) = qsGldasMosaic{3}(:, :, :, m) .* 3600 .* 24 .* monthLens(m);
    end


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
        
        curDate = datenum(y, 1, 1, 1, 0, 0);
        qsClean = [];
        qsYears = [];
        qsMonths = [];
        qsDays = [];

        vec = datevec(curDate);
        while vec(1) < y+1
            qsYears(end+1) = vec(1);
            qsMonths(end+1) = vec(2);
            qsDays(end+1) = vec(3);

            curQs = squeeze(qs(vec(2)));
            if ~isnan(curQs)
                qsClean(end+1) = curQs;
            else
                qsClean(end+1) = NaN;
            end

            curDate = addtodate(curDate, 1, 'day');
            vec = datevec(curDate);
        end

        if i == 1
            curPlantQsTimeSeries(1, :) = qsYears;
            curPlantQsTimeSeries(2, :) = qsMonths;
            curPlantQsTimeSeries(3, :) = qsDays;
        end

        % add current year of temps to current plant
        curPlantQsTimeSeries(i+3, :) = qsClean;
    end
    
    plantQsTimeSeries = cat(2, plantQsTimeSeries, curPlantQsTimeSeries);
    
end

finalQsAnomTimeSeries = [];
finalQsAnomTimeSeries(1:3,:) = plantQsTimeSeries(1:3,:);
for p = 4:size(plantQsTimeSeries, 1)
    finalQsAnomTimeSeries(p,:) = (plantQsTimeSeries(p,:)-movmean(plantQsTimeSeries(p,:),365*10))./movstd(plantQsTimeSeries(p,:),365*10);
end

csvwrite('2019-electricity/global-pp-runoff-all-cap.csv', plantQsTimeSeries);
csvwrite('2019-electricity/global-pp-runoff-anom-all-cap.csv', finalQsAnomTimeSeries);

