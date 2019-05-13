startYear = 2007;
endYear = 2018;

if ~exist('temp')
    temp = loadDailyData('E:\data\era-interim\output\mx2t\075x075\mx2t', 'startYear', startYear, 'endYear', endYear);
    if nanmean(nanmean(nanmean(nanmean(nanmean(temp{3}))))) > 100
        temp{3} = temp{3} - 273.15;
    end
    

%     temp = loadDailyData('E:\data\ncep-reanalysis\output\tmax', 'startYear', 2007, 'endYear', 2018);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(temp{3}))))) > 100
%         temp{3} = temp{3} - 273.15;
%     end

%     temp = loadDailyData('E:\data\cpc-temp\output\tmax', 'startYear', 2007, 'endYear', 2018);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(temp{3}))))) > 100
%         temp{3} = temp{3} - 273.15;
%     end
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
    
%     [latInd, lonInd] = latLonIndexRange(temp, [lat-.25, lat+.25], [lon-.25, lon+.25]);
    [latInd, lonInd] = latLonIndex(temp, [lat, lon]);
        
%     [latEraInd, lonEraInd] = latLonIndex(tempEra, [lat, lon]);%-.5, lat+.5], [lon-.5, lon+.5]);
    
    
    tx = squeeze(nanmean(nanmean(temp{3}(latInd, lonInd, :, :, :), 2), 1));
%     txEra = squeeze(nanmean(nanmean(tempEra{3}(latEraInd, lonEraInd, :, :, :), 2), 1));
%     txEra = squeeze(tempEra{3}(latEraInd, lonEraInd, :, :, :));
    
    curDate = datenum(startYear, 1, 1, 1, 0, 0);
    txClean = [];
%     txCleanEra = [];
    for year = 1:length(startYear:endYear)
        for month = 1:12
            days = round(addtodate(curDate, 1, 'month') - curDate);
            curDate = addtodate(curDate, 1, 'month');
            txClean = [txClean; squeeze(tx(year, month, 1:days))];
%             txCleanEra = [txCleanEra; squeeze(txEra(year, month, 1:days))];
        end
    end
        
    plantWbTimeSeries(i, :) = [ind, txClean'];
end

 csvwrite('2019-electricity/nuke-tx-era-075.csv', plantWbTimeSeries);