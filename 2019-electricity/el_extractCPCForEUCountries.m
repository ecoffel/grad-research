if ~exist('temp')
    temp = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', 2015, 'endYear', 2018);
    if nanmean(nanmean(nanmean(nanmean(nanmean(temp{3}))))) > 100
        temp{3} = temp{3} - 273.15;
    end
    
    load waterGrid;
    waterGrid = logical(waterGrid);
    
    tempLat = temp{1};
    tempLon = temp{2};
    tempData = temp{3};
    mask = zeros(size(temp{1}));
    mask(1:63, :) = 1;
    mask(80:90, :) = 1;
    mask(:, 15:173) = 1;
    
    for year = 1:size(tempData,3)
        for month = 1:size(tempData,4)
            for day = 1:size(tempData,5)
                t = tempData(:,:,year,month,day);
                t(logical(mask)) = NaN;
                t(waterGrid) = NaN;
                tempData(:,:,year,month,day) = t;
            end
        end
    end
    
    
%     
%     temp = loadDailyData('E:\data\cpc-temp\output\tmax', 'startYear', 2015, 'endYear', 2018);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(temp{3}))))) > 100
%         temp{3} = temp{3} - 273.15;
%     end
%     
%     tempLat = temp{1};
%     tempLon = temp{2};
%     tempData = temp{3};
%     mask = zeros(size(temp{1}));
%     mask(1:255, :) = 1;
%     mask(330:360, :) = 1;
%     mask(:, 60:600) = 1;
%     
%     for year = 1:size(tempData,3)
%         for month = 1:size(tempData,4)
%             for day = 1:size(tempData,5)
%                 t = tempData(:,:,year,month,day);
%                 t(logical(mask)) = NaN;
%                 tempData(:,:,year,month,day) = t;
%             end
%         end
%     end
end

euCodes = {'AL', 'AD', 'AM', 'AT', 'BY', 'BE', 'BA', 'BG', 'CH', 'CY', 'CZ', 'DE', ...
               'DK', 'EE', 'ES', 'FO', 'FI', 'FR', 'GB', 'GE', 'GI', 'GR', 'HU', 'HR', ...
               'IE', 'IS', 'IT', 'LT', 'LU', 'LV', 'MC', 'MK', 'MT', 'NO', 'NL', 'PO', ...
               'PT', 'RO', 'SE', 'SI', 'SK', 'SM', 'VA'};

countryIds = {};
countryLats = [];
countryLons = [];

fid = fopen('2019-electricity/country-coords.csv');
line = fgetl(fid);
line = fgetl(fid);
while ischar(line)
    C = strsplit(line,',');
    line = fgetl(fid);
    
    if ismember(C{end-21}, euCodes)
        countryIds{end+1} = C{end-21};
        countryLons(end+1) = str2num(C{end-1});
        countryLats(end+1) = str2num(C{end});
    end
end
fclose(fid);

countryGridPoints = {};
for c = 1:length(countryIds)
    countryGridPoints{c} = [];
end

for xlat = 1:size(tempLat, 1)
    for ylon = 1:size(tempLon, 2)
        if ~isnan(tempData(xlat, ylon, 1, 1, 1))
            lat1 = tempLat(xlat, ylon);
            lon1 = tempLon(xlat, ylon);
            if lon1 < 0
                lon1 = 360 - lon1;
            end

            xList = [];
            yList = [];
            dInd = -1;
            dMax = -1;

            for c = 1:length(countryIds)
                latCountry = countryLats(c);
                lonCountry = countryLons(c);
                if lonCountry < 0
                    lonCountry = lonCountry+360;
                end
                
                d = distance(lat1, lon1, latCountry, lonCountry);
                if dMax == -1
                    dMax = d;
                    dInd = c;
                elseif d < dMax
                    dMax = d;
                    dInd = c;
                end
            end

            countryGridPoints{dInd} = [countryGridPoints{dInd}; [xlat, ylon]];
        end
    end
end
    
countryTxTimeSeries = [];
countryIdInds = [];
n = 1;
for c = 1:length(countryIds)
    if length(countryGridPoints{c}) == 0
        continue
    end
    countryIdInds(end+1) = c;
    xlist = countryGridPoints{c}(:,1);
    ylist = countryGridPoints{c}(:,2);
    
    curDate = datenum(2015, 1, 1, 1, 0, 0);
    
    tx = [];
    txYears = [];
    txMonths = [];
    txDays = [];
    for y = 1:size(tempData, 3)
        for m = 1:size(tempData, 4)
            for d = 1:size(tempData, 5)
                
                curTx = nanmean(nanmean(squeeze(tempData(xlist, ylist, y, m, d)), 2), 1);
                if ~isnan(curTx)
                    vec = datevec(curDate);
                    txYears(end+1) = vec(1);
                    txMonths(end+1) = vec(2);
                    txDays(end+1) = vec(3);
                    tx(end+1) = curTx;
                    curDate = addtodate(curDate, 1, 'day');
                end
                
            end
        end
    end
    
    if n == 1
        countryTxTimeSeries(1, :) = txYears;
        countryTxTimeSeries(2, :) = txMonths;
        countryTxTimeSeries(3, :) = txDays;
        n = n+1;
    end
    countryTxTimeSeries(end+1,:) = tx;
end

T = table(countryTxTimeSeries, 'RowNames', {'year', 'month', 'day', countryIds{countryIdInds}});
 
% Write the table to a CSV file
writetable(T, '2019-electricity/country-tx-era-2015-2018.csv', 'WriteRowNames', true);

