startYear = 2007;
endYear = 2018;

if ~exist('temp')
%     tempMax = loadDailyData('E:\data\era-interim\output\mx2t\', 'startYear', startYear, 'endYear', endYear);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(tempMax{3}))))) > 100
%         tempMax{3} = tempMax{3} - 273.15;
%     end
%     
%     tempMin = loadDailyData('E:\data\era-interim\output\mn2t\', 'startYear', startYear, 'endYear', endYear);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(tempMin{3}))))) > 100
%         tempMin{3} = tempMin{3} - 273.15;
%     end
    

%     tempMax = loadDailyData('E:\data\ncep-reanalysis\output\tmax', 'startYear', startYear, 'endYear', endYear);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(tempMax{3}))))) > 100
%         tempMax{3} = tempMax{3} - 273.15;
%     end
% 
%     tempMin = loadDailyData('E:\data\ncep-reanalysis\output\tmin', 'startYear', startYear, 'endYear', endYear);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(tempMin{3}))))) > 100
%         tempMin{3} = tempMin{3} - 273.15;
%     end
%     
    
    tempMax = loadDailyData('E:\data\cpc-temp\output\tmax', 'startYear', 2007, 'endYear', 2018);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempMax{3}))))) > 100
        tempMax{3} = tempMax{3} - 273.15;
    end
    
    tempMin = loadDailyData('E:\data\cpc-temp\output\tmin', 'startYear', 2007, 'endYear', 2018);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempMin{3}))))) > 100
        tempMin{3} = tempMin{3} - 273.15;
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
    
    [latInd, lonInd] = latLonIndexRange(tempMax, [lat-.25, lat+.25], [lon-.25, lon+.25]);
%     [latInd, lonInd] = latLonIndex(temp, [lat, lon]);
        
    
    tx = squeeze(nanmean(nanmean(tempMax{3}(latInd, lonInd, :, :, :), 2), 1));
    tn = squeeze(nanmean(nanmean(tempMin{3}(latInd, lonInd, :, :, :), 2), 1));
%     txEra = squeeze(nanmean(nanmean(tempEra{3}(latEraInd, lonEraInd, :, :, :), 2), 1));
%     txEra = squeeze(tempEra{3}(latEraInd, lonEraInd, :, :, :));
    
    curDate = datenum(startYear, 1, 1, 1, 0, 0);
    txClean = [];
    tnClean = [];
    cdd = [];
%     txCleanEra = [];
    for year = 1:length(startYear:endYear)
        for month = 1:12
            days = round(addtodate(curDate, 1, 'month') - curDate);
            curDate = addtodate(curDate, 1, 'month');
            txClean = [txClean; squeeze(tx(year, month, 1:days))];
            tnClean = [tnClean; squeeze(tn(year, month, 1:days))];
%             txCleanEra = [txCleanEra; squeeze(txEra(year, month, 1:days))];
        end
    end
    
    cdd = (txClean + tnClean) ./ 2 - 18.33;
        
    plantWbTimeSeries(i, :) = [ind, cdd'];
end

 csvwrite('2019-electricity/nuke-cdd-cpc.csv', plantWbTimeSeries);