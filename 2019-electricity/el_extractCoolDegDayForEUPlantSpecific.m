startYear = 2015;
endYear = 2018;

if ~exist('temp')
%     tempMax = loadDailyData('E:\data\era-interim\output\mx2t', 'startYear', startYear, 'endYear', endYear);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(tempMax{3}))))) > 100
%         tempMax{3} = tempMax{3} - 273.15;
%     end
%     
%     
%     tempMin = loadDailyData('E:\data\era-interim\output\mn2t', 'startYear', startYear, 'endYear', endYear);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(tempMin{3}))))) > 100
%         tempMin{3} = tempMin{3} - 273.15;
%     end
%   
% 
%     tempMax = loadDailyData('E:\data\ncep-reanalysis\output\tmax', 'startYear', 2015, 'endYear', 2018);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(tempMax{3}))))) > 100
%         tempMax{3} = tempMax{3} - 273.15;
%     end
% 
%     tempMin = loadDailyData('E:\data\ncep-reanalysis\output\tmin', 'startYear', 2015, 'endYear', 2018);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(tempMin{3}))))) > 100
%         tempMin{3} = tempMin{3} - 273.15;
%     end

    
    
    tempMax = loadDailyData('E:\data\cpc-temp\output\tmax', 'startYear', 2015, 'endYear', 2018);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempMax{3}))))) > 100
        tempMax{3} = tempMax{3} - 273.15;
    end
    
    
    tempMin = loadDailyData('E:\data\cpc-temp\output\tmin', 'startYear', 2015, 'endYear', 2018);
    if nanmean(nanmean(nanmean(nanmean(nanmean(tempMin{3}))))) > 100
        tempMin{3} = tempMin{3} - 273.15;
    end

end

plantLatLon = csvread('2019-electricity/entsoe-lat-lon.csv');
plantCDDTimeSeries = [];

for i = 1:size(plantLatLon, 1)
    ind = plantLatLon(i,1);
    lat = plantLatLon(i,2);
    lon = plantLatLon(i,3);
    if lon < 0
        lon = lon+360;
    end
    

%     [latInd, lonInd] = latLonIndex(temp, [lat, lon]);
    [latInd, lonInd] = latLonIndexRange(tempMax, [lat-.25 lat+.25], [lon-.25 lon+.25]);


    tx = squeeze(nanmean(nanmean(tempMax{3}(latInd, lonInd, :, :, :), 2), 1));
    tn = squeeze(nanmean(nanmean(tempMin{3}(latInd, lonInd, :, :, :), 2), 1));

    
    curDate = datenum(startYear, 1, 1, 1, 0, 0);
    txClean = [];
    tnClean = [];
    coolDeg = [];
    txYears = [];
    txMonths = [];
    txDays = [];
    
    for j = 1:numel(tx)
        dv = datevec(curDate);
        
        yr = dv(1);
        mn = dv(2);
        dy = dv(3);
        
        if yr > endYear
            break
        end
        
        txYears(end+1) = yr;
        txMonths(end+1) = mn;
        txDays(end+1) = dy;
        txClean(end+1) = tx(yr-startYear+1, mn, dy);
        tnClean(end+1) = tn(yr-startYear+1, mn, dy);
        coolDeg(end+1) = (txClean(end)+tnClean(end))/2 - 18.33;
        curDate = addtodate(curDate, 1, 'day');
    end
        
    if i == 1
        plantCDDTimeSeries(1, :) = txYears;
        plantCDDTimeSeries(2, :) = txMonths;
        plantCDDTimeSeries(3, :) = txDays;
    end
    
    plantCDDTimeSeries(end+1,:) = coolDeg;
end

csvwrite('2019-electricity/entsoe-cdd-cpc.csv', plantCDDTimeSeries);
%  
% T = table(countryTxTimeSeries, 'RowNames', {'year', 'month', 'day', countryIds{countryIdInds}});
%  
% % Write the table to a CSV file
% writetable(T, '2019-electricity/country-tx-era-2015-2018.csv', 'WriteRowNames', true);
