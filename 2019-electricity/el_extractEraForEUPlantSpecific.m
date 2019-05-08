if ~exist('temp')
%     temp = loadDailyData('E:\data\era-interim\output\mx2t', 'startYear', 2015, 'endYear', 2018);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(temp{3}))))) > 100
%         temp{3} = temp{3} - 273.15;
%     end
    
%     temp = loadDailyData('E:\data\cpc-temp\output\tmax', 'startYear', 2015, 'endYear', 2018);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(temp{3}))))) > 100
%         temp{3} = temp{3} - 273.15;
%     end
    
    
    temp = loadDailyData('E:\data\cpc-temp\output\tmax', 'startYear', 2015, 'endYear', 2018);
    if nanmean(nanmean(nanmean(nanmean(nanmean(temp{3}))))) > 100
        temp{3} = temp{3} - 273.15;
    end
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
    
    [latInd, lonInd] = latLonIndexRange(temp, [lat-.5 lat+.5], [lon-.5 lon+.5]);
        
    tx = squeeze(nanmean(nanmean(temp{3}(latInd, lonInd, :, :, :), 2), 1));
    
    curDate = datenum(2015, 1, 1, 1, 0, 0);
    txClean = [];
    txYears = [];
    txMonths = [];
    txDays = [];
    for year = 1:size(tx, 1)
        for month = 1:size(tx, 2)
            for day = 1:size(tx, 3)
            
                curTx = squeeze(tx(year, month, day));
                if ~isnan(curTx)
                    vec = datevec(curDate);
                    txYears(end+1) = vec(1);
                    txMonths(end+1) = vec(2);
                    txDays(end+1) = vec(3);
                    txClean(end+1) = curTx;
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
    
    plantTxTimeSeries(end+1,:) = txClean;
end

csvwrite('2019-electricity/entsoe-tx-cpc.csv', plantTxTimeSeries);
%  
% T = table(countryTxTimeSeries, 'RowNames', {'year', 'month', 'day', countryIds{countryIdInds}});
%  
% % Write the table to a CSV file
% writetable(T, '2019-electricity/country-tx-era-2015-2018.csv', 'WriteRowNames', true);
