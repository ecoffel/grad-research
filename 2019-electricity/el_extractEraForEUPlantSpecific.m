if ~exist('temp')
    tempEra = loadDailyData('E:\data\era-interim\output\mx2t', 'startYear', 2015, 'endYear', 2018);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempEra{3}))))) > 100
        tempEra{3} = tempEra{3} - 273.15;
    end
    
%     temp = loadDailyData('E:\data\cpc-temp\output\tmax', 'startYear', 2007, 'endYear', 2018);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(temp{3}))))) > 100
%         temp{3} = temp{3} - 273.15;
%     end
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
    
    [latEraInd, lonEraInd] = latLonIndex(tempEra, [lat, lon]);
        
    txEra = squeeze(tempEra{3}(latEraInd, lonEraInd, :, :, :));
    
    curDate = datenum(2015, 1, 1, 1, 0, 0);
    txCleanEra = [];
    txYears = [];
    txMonths = [];
    txDays = [];
    for year = 1:size(txEra, 1)
        for month = 1:size(txEra, 2)
            for day = 1:size(txEra, 3)
            
                curTx = squeeze(txEra(year, month, day));
                if ~isnan(curTx)
                    vec = datevec(curDate);
                    txYears(end+1) = vec(1);
                    txMonths(end+1) = vec(2);
                    txDays(end+1) = vec(3);
                    txCleanEra(end+1) = curTx;
                    curDate = addtodate(curDate, 1, 'day');
                end
            end
        end
    end
    
    if i == 1
        plantTxTimeSeries(1, :) = txYears;
        plantTxTimeSeries(2, :) = txMonths;
        plantTxTimeSeries(3, :) = txDays;
    end
    
    plantTxTimeSeries(end+1,:) = txCleanEra;
end

csvwrite('2019-electricity/entsoe-tx-era.csv', plantTxTimeSeries);
%  
% T = table(countryTxTimeSeries, 'RowNames', {'year', 'month', 'day', countryIds{countryIdInds}});
%  
% % Write the table to a CSV file
% writetable(T, '2019-electricity/country-tx-era-2015-2018.csv', 'WriteRowNames', true);
