year1 = 2004;
year2 = 2018;

if ~exist('cpcTemp')
    cpcTemp = loadDailyData('E:\data\cpc-temp\output\tmax', 'startYear', year1, 'endYear', year2);
    if nanmean(nanmean(nanmean(nanmean(nanmean(cpcTemp{3}))))) > 100
        cpcTemp{3} = cpcTemp{3} - 273.15;
    end
    
    cpcLat = cpcTemp{1};
    cpcLon = cpcTemp{2};
    cpcData = cpcTemp{3};
    mask = zeros(size(cpcTemp{1}));
    mask(1:230, :) = 1;
    mask(278:360, :) = 1;
    mask(:, 1:471) = 1;
    mask(:, 586:720) = 1;
    mask(230:242, 485:510) = 1;
    mask(230:238, 510:517) = 1;
    mask(230:235, 517:520) = 1;
    mask(273:278, 543:579) = 1;
    mask(270:275, 555:577) = 1;
    mask(265:275, 557:561) = 1;

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
    xlist = stateGridPoints{s}(:,1);
    ylist = stateGridPoints{s}(:,2);
    
    curDate = datenum(year1, 1, 1, 1, 0, 0);
    
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
    
    if s == 1
        stateTxTimeSeries(1, :) = txYears;
        stateTxTimeSeries(2, :) = txMonths;
        stateTxTimeSeries(3, :) = txDays;
    end
    stateTxTimeSeries(end+1,:) = tx;
end

T = table(stateTxTimeSeries, 'RowNames', {'year', 'month', 'day', stateIds{:}});
 
% Write the table to a CSV file
writetable(T, ['2019-electricity/subgrid-tx-cpc-' num2str(year1) '-' num2str(year2) '-test.csv'], 'WriteRowNames', true);

