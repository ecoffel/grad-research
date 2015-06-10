baseDir = 'e:/';
findMax = true;
months = [12 1 2];

yearStart = 1981;
yearEnd = 2012;

yearStep = 1; % the number of years loaded at a time for memory

vars = {'narr/output/tasmax', 'narr/output/snod'};

fileformat = 'pdf';
fileTitle = ['tempSnow.' fileformat];

dataSnow = [];    
dataTasmax = [];

latRange = [40 46];
lonRange = [281 287];

lat = [];
lon = [];

for v = 1:length(vars)
    curModelDir = [baseDir 'data/' vars{v}];
    
    ['loading ' curModelDir]
    for y = yearStart:yearStep:yearEnd
        ['year ' num2str(y)]
        daily = loadDailyData(curModelDir, 'yearStart', y, 'yearEnd', y+(yearStep-1));
        
        if length(lat) == 0
            lat = daily{1};
            lon = daily{2};
        end
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(daily, latRange, lonRange);
        
        curData = daily{3};
        i = 1;
        if length(findstr(vars{v}, 'tasmax')) > 0
            for m = 1:size(curData,4)
                for d = 1:size(curData,5)
                    dataTasmax(:,:,y-yearStart+1,i,v) = curData(latIndexRange,lonIndexRange,1,m,d);
                    i = i+1;
                end
            end
        elseif length(findstr(vars{v}, 'snod')) > 0
            for m = 1:size(curData,4)
                for d = 1:size(curData,5)
                    dataSnow(:,:,y-yearStart+1,i,v) = curData(latIndexRange,lonIndexRange,1,m,d);
                    i = i+1;
                end
            end
        end
        
        clear daily curData;
    end
end

snowMean = squeeze(nanmean(nanmean(dataSnow, 2), 1));
tempMean = squeeze(nanmean(nanmean(dataTemp, 2), 1));












