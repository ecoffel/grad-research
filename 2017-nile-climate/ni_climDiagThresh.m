% number of days above 95th percentile
% change in total precip
% change in consecutive dry days
% consecutive years with extreme heat or drought


basePeriod = 'past';
baseDataset = 'cmip5';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
%models = {'access1-0','access1-3'};
baseRcps = {'historical'};
baseEnsemble = 'r1i1p1';

futureDataset = 'cmip5';

% futureModels = {'access1-0'};
futureRcp = 'rcp85';
futureEnsemble = 'r1i1p1';

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2004;

futurePeriods = [2060:2080];

load lat;
load lon;

% percent (1) or absolute (2)
threshType = 1;
thresh = 99;

regionNames = {'Nile Basin'};
regionAb = {'nile'}; 
regions = [[[-5 30], [23 39]]];                 % nile basin

regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

baseDir = 'e:/data';
yearStep = 1;

load lat;
load lon;

baseVar = 'tasmax';
futureVar = 'tasmax';

numDays = 372;

load waterGrid;
waterGrid = logical(waterGrid);

% temperature data (thresh, ann-max, or daily-max)
baseData = [];

['loading base: ' baseDataset]
for m = 1:length(models)
    curModel = models{m};

    ['loading base model ' curModel '...']

    for y = basePeriodYears(1):yearStep:basePeriodYears(end)
        ['year ' num2str(y) '...']

        baseDaily = loadDailyData([baseDir '/' baseDataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' baseVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        
        % remove lat/lon data (we loaded this earlier)
        baseDaily = baseDaily{3};
        
        % if any kelvin values, convert to C
        if baseDaily(1,1,1,1,1) > 100
            baseDaily = baseDaily - 273.15;
        end

        baseData(:, :, y-basePeriodYears(1)+1, :, :, m) = baseDaily(regionLatLonInd{1}{1}, regionLatLonInd{1}{2});
    end
end

% threshold values in base period
baseThresh = [];
% number of annual exceedences in base period
baseExceedences = [];

for m = 1:length(models)
    for xlat = 1:size(baseData, 1)
        for ylon = 1:size(baseData, 2)

            % percent
            if threshType == 1
                % calculate threshold across all data
                curBase = reshape(baseData(xlat, ylon, :, :, :, m), [size(baseData, 3)*size(baseData, 4)*size(baseData, 5), 1]);
                baseThresh(xlat, ylon, m) = prctile(curBase, thresh);
            elseif threshType == 2
                % an absolute threshold
                baseThresh(xlat, ylon, m) = thresh;
            end

            for year = 1:size(baseData, 3)
                curBase = reshape(baseData(xlat, ylon, year, :, :, m), [numel(baseData(xlat, ylon, year, :, :, m)), 1]);
                baseExceedences(xlat, ylon, year, m) = length(find(curBase > baseThresh(xlat, ylon, m)));
            end

        end
    end
end

% ------------ load future data -------------    

futureExceedences = [];

for f = 1:size(futurePeriods, 1)
    
    futurePeriodYears = futurePeriods(f, :);

    ['loading future: ' futureDataset]
    for m = 1:length(models)
        curModel = models{m};
        
        ['loading future model ' curModel '...']

        for y = futurePeriodYears(1):yearStep:futurePeriodYears(end)
            ['year ' num2str(y) '...']

            futureDaily = loadDailyData([baseDir '/' futureDataset '/output/' curModel '/' futureEnsemble '/' futureRcp '/' futureVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            futureDaily = futureDaily{3};
            
            % convert any kelvin values to C
            if futureDaily(1,1,1,1,1) > 100
                futureDaily = futureDaily - 273.15;
            end
            
            futureDaily = futureDaily(regionLatLonInd{1}{1}, regionLatLonInd{1}{2}, :, :, :);
            
            for xlat = 1:size(futureDaily, 1)
                for ylon = 1:size(futureDaily, 2)
                    curFut = reshape(futureDaily(xlat, ylon, :, :, :), [numel(futureDaily(xlat, ylon, :, :, :)), 1]);
                    futureExceedences(xlat, ylon, y-futurePeriodYears(1)+1, m) = length(find(curFut > baseThresh(xlat, ylon, m)));
                end
            end
        end
    end
end

% build final result to save
climDiagThresh = {baseThresh, baseExceedences, futureExceedences};

threshStr = 'percent';
if threshType == 2
    threshStr = 'absolute';
end
save(['clim-diag-exceedence-' threshStr '-' num2str(thresh) '-' futureRcp '.mat'], 'climDiagThresh');
