year1 = 2004;
year2 = 2018;

if ~exist('temp')
%     cpcTemp = loadDailyData('E:\data\cpc-temp\output\tmax', 'startYear', year1, 'endYear', year2);
%     if nanmean(nanmean(nanmean(nanmean(nanmean(cpcTemp{3}))))) > 100
%         cpcTemp{3} = cpcTemp{3} - 273.15;
%     end
%     
%     cpcLat = cpcTemp{1};
%     cpcLon = cpcTemp{2};
%     cpcData = cpcTemp{3};
%     mask = zeros(size(cpcTemp{1}));
%     mask(1:230, :) = 1;
%     mask(278:360, :) = 1;
%     mask(:, 1:471) = 1;
%     mask(:, 586:720) = 1;
%     mask(230:242, 485:510) = 1;
%     mask(230:238, 510:517) = 1;
%     mask(230:235, 517:520) = 1;
%     mask(273:278, 543:579) = 1;
%     mask(270:275, 555:577) = 1;
%     mask(265:275, 557:561) = 1;
% 
%     for year = 1:size(cpcData,3)
%         for month = 1:size(cpcData,4)
%             for day = 1:size(cpcData,5)
%                 t = cpcData(:,:,year,month,day);
%                 t(logical(mask)) = NaN;
%                 cpcData(:,:,year,month,day) = t;
%             end
%         end
%     end
    
    
    
    
    temp = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', year1, 'endYear', year2);
    if nanmean(nanmean(nanmean(nanmean(nanmean(temp{3}))))) > 100
        temp{3} = temp{3} - 273.15;
    end
    
    tempLat = temp{1};
    tempLon = temp{2};
    tempData = temp{3};
    
    load waterGrid;
    waterGrid=logical(waterGrid);
    
    mask = zeros(size(temp{1}));
    mask(1:57, :) = 1;
    mask(71:90, :) = 1;
    mask(:, 1:100) = 1;
    mask(:, 147:180) = 1;
    mask(57:60, 122:127) = 1;
    mask(57:59, 127:129) = 1;
    mask(68:71, 137:144) = 1;
%     d = tempData(:,:,1,1,1);
%     d(logical(mask))=NaN;
%     d(waterGrid)=NaN;
%     plotModelData({tempLat,tempLon,d},'usa','states',true);
%    
    for year = 1:size(tempData,3)
        for month = 1:size(tempData,4)
            for day = 1:size(tempData,5)
                t = tempData(:,:,year,month,day);
                t(logical(mask)) = NaN;
                tempData(:,:,year,month,day) = t;
            end
        end
    end
end


stateIds = {};
stateLats = [];
stateLons = [];

fid = fopen('2019-electricity/us-state-coords.csv');
line = fgetl(fid);
line = fgetl(fid);
while ischar(line)
    C = strsplit(line,',');
    line = fgetl(fid);
    
    if strcmp(C{1}, 'AK') || strcmp(C{1}, 'HI')
        continue;
    end
    stateIds{end+1} = C{1};
    stateLats(end+1) = str2num(C{2});
    stateLons(end+1) = str2num(C{3});
end
fclose(fid);

stateGridPoints = {};
for s = 1:length(stateIds)
    stateGridPoints{s} = [];
end

% for each grid box, find closest state
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

            for s = 1:length(stateIds)
                latState = stateLats(s);
                lonState = stateLons(s);
                if lonState < 0
                    lonState = lonState+360;
                end
                
                d = distance(lat1, lon1, latState, lonState);
                if dMax == -1
                    dMax = d;
                    dInd = s;
                elseif d < dMax
                    dMax = d;
                    dInd = s;
                end
            end

            stateGridPoints{dInd} = [stateGridPoints{dInd}; [xlat, ylon]];
        end
    end
end
    
stateTxTimeSeries = [];

for s = 1:length(stateIds)    
    
    % if no state identified, then find closest grid box for the state
    if length(stateGridPoints{s}) == 0
        [latInd, lonInd] = latLonIndex(temp, [stateLats(s), stateLons(s)]);
        
        if isnan(tempData(latInd, lonInd, 1, 1, 1))
            dMax = -1;
            dIndX = -1;
            dIndY = -1;
            for xlat = max(latInd-1, 1):latInd+1
                for ylon = max(lonInd-1, 1):lonInd+1
                    if ~isnan(tempData(xlat, ylon, 1, 1, 1))
                        d = distance(stateLats(s), stateLons(s), tempLats(xlat, ylon), tempLons(xlat, ylon));
                        if dIndX == -1
                            dMax = d;
                            dIndX = xlat;
                            dIndY = ylon;
                        elseif d < dMax
                            dMax = d;
                            dIndX = xlat;
                            dIndY = ylon;
                        end
                    end
                end
            end
        else
            xlist = latInd;
            ylist = lonInd;
        end
    else
        xlist = stateGridPoints{s}(:,1);
        ylist = stateGridPoints{s}(:,2);
    end
    
    curDate = datenum(year1, 1, 1, 1, 0, 0);
    
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
    
    if s == 1
        stateTxTimeSeries(1, :) = txYears;
        stateTxTimeSeries(2, :) = txMonths;
        stateTxTimeSeries(3, :) = txDays;
    end
    stateTxTimeSeries(end+1,:) = tx;
end

T = table(stateTxTimeSeries, 'RowNames', {'year', 'month', 'day', stateIds{:}});
 
% Write the table to a CSV file
writetable(T, ['2019-electricity/subgrid-tx-era-' num2str(year1) '-' num2str(year2) '-test.csv'], 'WriteRowNames', true);

