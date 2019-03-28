if ~exist('cpcTemp')
    cpcTemp = loadDailyData('E:\data\cpc-temp\output\tmax', 'startYear', 2015, 'endYear', 2018);
    if nanmean(nanmean(nanmean(nanmean(nanmean(cpcTemp{3}))))) > 100
        cpcTemp{3} = cpcTemp{3} - 273.15;
    end
    
    cpcLat = cpcTemp{1};
    cpcLon = cpcTemp{2};
    cpcData = cpcTemp{3};
    mask = zeros(size(cpcTemp{1}));
    mask(1:255, :) = 1;
    mask(330:360, :) = 1;
    mask(:, 60:600) = 1;
    
    for year = 1:size(cpcData,3)
        for month = 1:size(cpcData,4)
            for day = 1:size(cpcData,5)
                t = cpcData(:,:,year,month,day);
                t(logical(mask)) = NaN;
                cpcData(:,:,year,month,day) = t;
            end
        end
    end
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

for xlat = 1:size(cpcLat, 1)
    for ylon = 1:size(cpcLon, 2)
        if ~isnan(cpcData(xlat, ylon, 1, 1, 1))
            lat1 = cpcLat(xlat, ylon);
            lon1 = cpcLon(xlat, ylon);
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
    for y = 1:size(cpcData, 3)
        for m = 1:size(cpcData, 4)
            for d = 1:size(cpcData, 5)
                
                curTx = nanmean(nanmean(squeeze(cpcData(xlist, ylist, y, m, d)), 2), 1);
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
writetable(T, '2019-electricity/country-tx-cpc-2015-2018.csv', 'WriteRowNames', true);

