if ~exist('eraTemp')
    eraTemp = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', 2007, 'endYear', 2018);
    if nanmean(nanmean(nanmean(nanmean(nanmean(eraTemp{3}))))) > 100
        eraTemp{3} = eraTemp{3} - 273.15;
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
    
    [latInd, lonInd] = latLonIndex(eraTemp, [lat, lon]);
    
    tx = squeeze(eraTemp{3}(latInd, lonInd, :, :, :));
    
    curDate = datenum(2007, 1, 1, 1, 0, 0);
    txClean = [];
    for year = 1:length(2007:2018)
        for month = 1:12
            days = round(addtodate(curDate, 1, 'month') - curDate);
            curDate = addtodate(curDate, 1, 'month');
            txClean = [txClean; squeeze(tx(year, month, 1:days))];
        end
    end
    
    plantWbTimeSeries(i, :) = [ind, txClean'];
end

csvwrite('2019-electricity/nuke-tx-era.csv', plantWbTimeSeries);