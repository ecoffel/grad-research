startYear = 2007;
endYear = 2018;

if ~exist('qs')
    qs = loadMonthlyData('E:\data\gldas-noah-v2\output\Qs_acc', 'Qs_acc', 'startYear', startYear, 'endYear', endYear);
    if nanmean(nanmean(nanmean(nanmean(nanmean(qs{3}))))) > 100
        qs{3} = qs{3} - 273.15;
    end
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
    
    [latInd, lonInd] = latLonIndexRange(qs, [lat-.25, lat+.25], [lon-.25, lon+.25]);

    tx = squeeze(nanmean(nanmean(qs{3}(latInd, lonInd, :, :, :), 2), 1));
    
    curDate = datenum(startYear, 1, 1, 1, 0, 0);
    txClean = [];
    for year = 1:length(startYear:endYear)
        for month = 1:12
            days = round(addtodate(curDate, 1, 'month') - curDate);
            curDate = addtodate(curDate, 1, 'month');
            txClean = [txClean; squeeze(tx(year, month, 1:days))];
        end
    end
        
    plantWbTimeSeries(i, :) = [ind, txClean'];
end

 csvwrite('2019-electricity/nuke-tx-cpc.csv', plantWbTimeSeries);