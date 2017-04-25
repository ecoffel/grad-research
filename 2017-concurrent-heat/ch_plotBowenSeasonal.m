% generate changes at a temperature percentile, annual-max, or daily-max
% across models and decades.

season = 'all';
basePeriod = 'past';

% add in base models and add to the base loading loop

baseDataset = 'cmip5';
baseVar = 'bowen';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3'};

baseRcps = {'historical'};
baseEnsemble = 'r1i1p1';

futureRcps = {'rcp85'};
futureEnsemble = 'r1i1p1';

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2004;

futurePeriods = [2060:2080];

baseDir = 'e:/data';
yearStep = 1;

if strcmp(season, 'summer')
    months = [6 7 8];
elseif strcmp(season, 'winter')
    months = [12 1 2];
elseif strcmp(season, 'all')
    months = 1:12;
end

load lat;
load lon;

numDays = 372;

load waterGrid;
waterGrid = logical(waterGrid);

% temperature data (thresh, ann-max, or daily-max)
baseData = [];

['loading base: ' baseDataset]
for m = 1:length(baseModels)
    curModel = baseModels{m};

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

        % if we are not using a seasonal metric
        if ~strcmp(changeMetric, 'seasonal-monthly-max') && ~strcmp(changeMetric, 'seasonal-monthly-mean-max')
            % reshape to be 3D (x, y, day)
            baseDaily = reshape(baseDaily, [size(baseDaily, 1), size(baseDaily, 2), ...
                                                 size(baseDaily, 3)*size(baseDaily, 4)*size(baseDaily, 5)]);
            
        end

        % set water grid cells to NaN
        % include loops for month and day (5D) in case we are using
        % seasonal change metric
        for i = 1:size(baseDaily, 3)
            for j = 1:size(baseDaily, 4)
                for k = 1:size(baseDaily, 5)
                    curGrid = baseDaily(:, :, i, j, k);
                    curGrid(waterGrid) = NaN;
                    baseDaily(:, :, i, j, k) = curGrid;
                end
            end
        end
        
        clear baseDaily baseDaily3d;
    end
end


% ------------ load future data -------------    

for f = 1:size(futurePeriods, 1)
    
    futureData = [];
    chgData = [];
    
    futurePeriodYears = futurePeriods(f, :);

    ['loading future: ' futureDataset]
    for m = 1:length(futureModels)
        curModel = futureModels{m};

        ['loading future model ' curModel '...']

        for y = futurePeriodYears(1):yearStep:futurePeriodYears(end)
            ['year ' num2str(y) '...']

            futureDaily = loadDailyData([baseDir '/' futureDataset '/output/' curModel '/' futureEnsemble '/' futureRcps{1} '/' futureVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            futureDaily = futureDaily{3};
            
            % set water grid cells to NaN
            % include loops for month and day (5D) in case we are using
            % seasonal change metric
            for i = 1:size(futureDaily, 3)
                for j = 1:size(futureDaily, 4)
                    for k = 1:size(futureDaily, 5)
                        curGrid = futureDaily(:, :, i, j, k);
                        curGrid(waterGrid) = NaN;
                        futureDaily(:, :, i, j, k) = curGrid;
                    end
                end
            end
            
            clear futureDaily futureDaily3d;
        end
    end

end
