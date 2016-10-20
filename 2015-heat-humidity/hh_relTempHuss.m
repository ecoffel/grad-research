testPeriod = 'past';

models = {'access1-0', 'access1-3', 'bnu-esm', 'bcc-csm1-1-m', ...
          'canesm2', 'cnrm-cm5', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};

% models = {'access1-0', 'access1-3'};

%models = {''};

dataset = 'cmip5';

tempVar = 'tasmax';
hussVar = 'huss';
wbVar = 'wb';

rcp = 'historical';

% whether to find the annual extreme wet bulb day or the top N
annualExtreme = false;
topN = 100;

% the temperature reference area
region = 'india';
plotRegion = 'world';
fileformat = 'png';

baseDir = 'e:/data/';
ensemble = 'r1i1p1';
modelDir = 'cmip5/output';

timePeriod = [];
if strcmp(testPeriod, 'past')
    timePeriod = 1985:2004;
elseif strcmp(testPeriod, 'future')
    timePeriod = 2060:2080;
end

baseRegrid = true;
testRegrid = true;

% should we look at anomalies of temperature and wet bulb
minusMean = true;
% relative to the mean of the SST on the same day as the extreme
sameDayMean = true;

sameDayStr = 'day-mean';
if ~sameDayMean
    sameDayStr = 'year-mean';
end

if strcmp(dataset, 'ncep')
    models = {'ncep'};
end

if strcmp(region, 'us-ne')
    % right around NYC
    latBounds = [34 36];
    lonBounds = [-82 -80] + 360;
elseif strcmp(region, 'india')
    latBounds = [23 25];
    lonBounds = [80 82];   
elseif strcmp(region, 'west-africa')
    latBounds = [6 8];
    lonBounds = [-3 -1] + 360;   
elseif strcmp(region, 'china')
    latBounds = [26 28];
    lonBounds = [116 118];   
end

if annualExtreme
    tempDispStr = 'ann-max';
else
    tempDispStr = 'top-max';
end

yearStep = 1; % the number of years loaded at a time for memory  reasons

outputTemp = {};
outputHuss = {};
outputWb = {};

lat = [];
lon = [];

for d = 1:length(models)
    
    tempTargetFileStr = '';
    tempTargetPlotStr = '';

    if length(models) > 2
        modelStr = 'cmip5';
    else
        modelStr = models{d};
    end

    % indicies of higheset wet bulb temperatures (either 1 per year or top
    % N)
    wbInd = [];
    
    tempData = [];
    hussData = [];
    wbData = [];
    
    outputTemp{d} = [];
    outputHuss{d} = [];
    outputWb{d} = [];
    
    ['loading ' models{d} '...']
    for y = timePeriod(1):yearStep:timePeriod(end)
        ['year ' num2str(y)]

        if strcmp(dataset, 'ncep')
            tempStr = [baseDir 'ncep-reanalysis/output/' tempVar '/regrid/world'];
            hussStr = [baseDir 'ncep-reanalysis/output/' hussVar '/regrid/world'];
            wbStr = [baseDir 'ncep-reanalysis/output/' wbVar '/regrid/world'];
        else
            tempStr = [baseDir modelDir '/' models{d} '/' ensemble '/' rcp '/' tempVar '/regrid/world'];
            hussStr = [baseDir modelDir '/' models{d} '/' ensemble '/' rcp '/' hussVar '/regrid/world'];
            wbStr = [baseDir modelDir '/' models{d} '/' ensemble '/' rcp '/' wbVar '/regrid/world'];
        end
        
        dailyTemp = loadDailyData(tempStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
        if nanmean(nanmean(nanmean(nanmean(nanmean(dailyTemp{3}, 5), 4), 3), 2), 1) > 100
            dailyTemp{3} = dailyTemp{3} - 273.15;
        end
        
        [latIndexRange, lonIndexRange] = latLonIndexRange(dailyTemp, latBounds, lonBounds);
        
        if length(lat) == 0 | length(lon) == 0
            lat = dailyTemp{1};
            lon = dailyTemp{2};
        end
        
        curDailyTempData = dailyTemp{3}(latIndexRange, lonIndexRange, :, :, :);
        clear dailyTemp;

        dailyHuss = loadDailyData(hussStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
        curDailyHussData = dailyHuss{3}(latIndexRange, lonIndexRange, :, :, :);
        clear dailyHuss;
        
        dailyWb = loadDailyData(wbStr, 'yearStart', y, 'yearEnd', y+(yearStep-1));
        curDailyWbData = dailyWb{3}(latIndexRange, lonIndexRange, :, :, :);
        clear dailyWb;
        
        
        % reshape temperature into 3-dimension
        curDailyTempData = squeeze(reshape(curDailyTempData, ...
                                   [size(curDailyTempData, 1), ...
                                    size(curDailyTempData, 2), ...
                                    size(curDailyTempData, 3)*size(curDailyTempData,4)*size(curDailyTempData,5)]));
        % average over temperature area to make 1-dimension
        curDailyTempData = squeeze(nanmean(nanmean(curDailyTempData, 2), 1));
        
        % specific humidity
        curDailyHussData = squeeze(reshape(curDailyHussData, ...
                                   [size(curDailyHussData, 1), ...
                                    size(curDailyHussData, 2), ...
                                    size(curDailyHussData, 3)*size(curDailyHussData,4)*size(curDailyHussData,5)]));
        curDailyHussData = squeeze(nanmean(nanmean(curDailyHussData, 2), 1));
        
        % wet bulb
        curDailyWbData = squeeze(reshape(curDailyWbData, ...
                                   [size(curDailyWbData, 1), ...
                                    size(curDailyWbData, 2), ...
                                    size(curDailyWbData, 3)*size(curDailyWbData,4)*size(curDailyWbData,5)]));
        curDailyWbData = squeeze(nanmean(nanmean(curDailyWbData, 2), 1));
                
        indNan = find(isnan(curDailyTempData) | isnan(curDailyHussData) | isnan(curDailyWbData));
        
        curDailyWbData(indNan) = [];
        curDailyTempData(indNan) = [];
        curDailyHussData(indNan) = [];
        
        if annualExtreme
            % find index of once-per-year highest wet bulb temperature
            % otherwise we will find the top N events later
            wbInd = find(curDailyWbData == nanmax(curDailyWbData));
            
            outputTemp{d} = curDailyTempData(wbInd);
            outputHuss{d} = curDailyHussData(wbInd);
            outputWb{d} = curDailyWbData(wbInd);
        end
        
        wbData = [wbData; curDailyWbData];
        hussData = [hussData; curDailyHussData];
        tempData = [tempData; curDailyTempData];
        
        clear curDailyWbData curDailyHussData curDailyTempData;
       
    end
    
    outputTestData{d} = [];

    if ~annualExtreme
        % find top N events in wb data
        [wbSort, wbSortInd] = sort(wbData, 'descend');
        
        hussData = hussData(wbSortInd);
        tempData = tempData(wbSortInd);
        
        outputTemp{d} = tempData(1:topN);
        outputHuss{d} = hussData(1:topN);
        outputWb{d} = wbData(1:topN);
    end

end

figure('Color', [1,1,1]);
ind = 1;
for i = 1:5
    for j = 1:4
        if ind > 17 
            break;
        end
            
        subplot(5, 4, ind);
        hold on;
        plot(outputHuss{ind}, outputTemp{ind}, '.k');
        maxWb = round(nanmean(outputWb{ind}));
        title([models{ind} ' - ' num2str(maxWb)]);
        xlim([0.015 0.025]);
        ylim([30 50]);
        ind = ind + 1;
    end
end

