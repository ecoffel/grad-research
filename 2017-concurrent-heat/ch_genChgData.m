% generate changes at a temperature percentile, annual-max, or daily-max
% across models and decades.

season = 'all';
basePeriod = 'past';

% add in base models and add to the base loading loop

baseDataset = 'cmip5';


models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
% models = {'access1-0','access1-3'};
baseRcps = {'historical'};
baseEnsemble = 'r1i1p1';

futureDataset = 'cmip5';


% futureModels = {'access1-0'};
futureRcps = {'rcp85'};
futureEnsemble = 'r1i1p1';

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2004;

futurePeriods = [2060:2080];

% futurePeriods = [2070:2080];

baseDir = 'f:/data';
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

% what change to look at:
% ann-max = annual max temperature
% ann-min = annual min temperature
% daily-max = mean daily max temperature
% daily-min = mean daily min temperature
% seasonal-monthly-max = monthly maximum temperature
% seasonal-monthly-min = monthly minimum temperature
% seasonal-monthly-mean-max = mean daily maximum temperature for each month
% seasonal-monthly-mean-min = mean daily minimum temperature for each month
% thresh = changes above temperature thresholds specified in thresh
changeMetric = 'seasonal-monthly-mean-min';


if length(findstr(changeMetric, 'min')) > 0
    baseVar = 'tasmin';
    futureVar = 'tasmin';
else
    baseVar = 'tasmax';
    futureVar = 'tasmax';
end

% if changeMetric == 'thresh', look at change above these base period temperature percentiles
thresh = [1 10:10:90 99];

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

        % if we are not using a seasonal metric
        if ~strcmp(changeMetric, 'seasonal-monthly-max') && ~strcmp(changeMetric, 'seasonal-monthly-mean-max') && ...
           ~strcmp(changeMetric, 'seasonal-monthly-min') && ~strcmp(changeMetric, 'seasonal-monthly-mean-min')
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
        

        if strcmp(changeMetric, 'thresh')
            % calculate base period thresholds

            % loop over all thresholds
            for t = 1:length(thresh)
                % over x coords
                for xlat = 1:size(baseDaily, 1)
                    % over y coords
                    for ylon = 1:size(baseDaily, 2)

                        % skip if NaN (water)
                        if isnan(baseDaily(xlat, ylon, 1))
                            continue;
                        end

                        % calculate threshold at current (x,y) and
                        % percentile 
                        baseData(xlat, ylon, m, y-basePeriodYears(1)+1, t) = prctile(squeeze(baseDaily(xlat, ylon, :)), thresh(t));
                    end
                end
            end
            
        elseif strcmp(changeMetric, 'seasonal-monthly-max')
            % calculate the seasonal maximum for each month
            
            % loop over months
            for month = 1:size(baseDaily, 4)
                baseData(:, :, m, y-basePeriodYears(1)+1, month) = nanmax(squeeze(baseDaily(:, :, 1, month, :)), [], 3);
            end
        elseif strcmp(changeMetric, 'seasonal-monthly-min')
            % calculate the seasonal minimum for each month
            
            % loop over months
            for month = 1:size(baseDaily, 4)
                baseData(:, :, m, y-basePeriodYears(1)+1, month) = nanmin(squeeze(baseDaily(:, :, 1, month, :)), [], 3);
            end
            
        elseif strcmp(changeMetric, 'seasonal-monthly-mean-max') 
            % calculate the seasonal mean daily maximum for each month
            
            % loop over months
            for month = 1:size(baseDaily, 4)
                baseData(:, :, m, y-basePeriodYears(1)+1, month) = nanmean(squeeze(baseDaily(:, :, 1, month, :)), 3);
            end
        elseif strcmp(changeMetric, 'seasonal-monthly-mean-min') 
            % calculate the seasonal mean daily minimum for each month
            
            % loop over months
            for month = 1:size(baseDaily, 4)
                baseData(:, :, m, y-basePeriodYears(1)+1, month) = nanmean(squeeze(baseDaily(:, :, 1, month, :)), 3);
            end
                
        elseif strcmp(changeMetric, 'ann-max')

            % store annual max temperature at each gridbox for this year
            baseData(:, :, m, y-basePeriodYears(1)+1) = nanmax(squeeze(baseDaily), [], 3);
            
        elseif strcmp(changeMetric, 'ann-min')

            % store annual min temperature at each gridbox for this year
            baseData(:, :, m, y-basePeriodYears(1)+1) = nanmin(squeeze(baseDaily), [], 3);

        elseif strcmp(changeMetric, 'daily-max') || strcmp(changeMetric, 'daily-min')

            % store mean daily max temperature at each gridbox for this year
            baseData(:, :, m, y-basePeriodYears(1)+1) = nanmean(squeeze(baseDaily), 3);

        end
        

        clear baseDaily baseDaily3d;
    end
end


if strcmp(changeMetric, 'ann-max') || strcmp(changeMetric, 'daily-max') || ...
   strcmp(changeMetric, 'ann-min') || strcmp(changeMetric, 'daily-min')
    % if computing annual maximum or mean daily maximum, take the mean across all base period
    % years (baseData now 3D: (x, y, model))
    baseData = nanmean(baseData, 4);
elseif strcmp(changeMetric, 'seasonal-monthly-max') || strcmp(changeMetric, 'seasonal-monthly-mean-max') || ...
       strcmp(changeMetric, 'seasonal-monthly-min') || strcmp(changeMetric, 'seasonal-monthly-mean-min')
    % if computing seasonal metrics, average over all the annual
    % maximum or mean daily maximum, take the mean across all years
    % (baseData now 4D: (x, y, model, month))
    baseData = squeeze(nanmean(baseData, 4));
end

% ------------ load future data -------------    

for f = 1:size(futurePeriods, 1)
    
    futurePeriodYears = futurePeriods(f, :);

    ['loading future: ' futureDataset]
    for m = 1:length(models)
        curModel = models{m};
        
        futureData = [];
        chgData = [];

        ['loading future model ' curModel '...']

        for y = futurePeriodYears(1):yearStep:futurePeriodYears(end)
            ['year ' num2str(y) '...']

            futureDaily = loadDailyData([baseDir '/' futureDataset '/output/' curModel '/' futureEnsemble '/' futureRcps{1} '/' futureVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            futureDaily = futureDaily{3};
            
            % convert any kelvin values to C
            if futureDaily(1,1,1,1,1) > 100
                futureDaily = futureDaily - 273.15;
            end

            % if we are not using a seasonal metric
            if ~strcmp(changeMetric, 'seasonal-monthly-max') && ~strcmp(changeMetric, 'seasonal-monthly-mean-max') && ...
               ~strcmp(changeMetric, 'seasonal-monthly-min') && ~strcmp(changeMetric, 'seasonal-monthly-mean-min')
                % reshape to 3D (x, y, day)
                futureDaily = reshape(futureDaily, [size(futureDaily, 1), size(futureDaily, 2), ...
                                                         size(futureDaily, 3)*size(futureDaily, 4)*size(futureDaily, 5)]);
            end

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

            if strcmp(changeMetric, 'thresh')
                % loop over thresholds
                for t = 1:length(thresh)
                    % latitude
                    for xlat = 1:size(futureDaily, 1)
                        % longitude
                        for ylon = 1:size(futureDaily, 2)

                            if isnan(futureDaily(xlat, ylon, 1))
                                continue;
                            end

                            % compute percentile threshold for this grid cell
                            % and year
                            futureData(xlat, ylon, y-futurePeriodYears(1)+1, t) = prctile(squeeze(futureDaily(xlat, ylon, :)), thresh(t));
                        end
                    end
                end
            elseif strcmp(changeMetric, 'seasonal-monthly-max')
                % calculate the seasonal maximum for each month

                % loop over months
                for month = 1:size(futureDaily, 4)
                    futureData(:, :, y-futurePeriodYears(1)+1, month) = nanmax(squeeze(futureDaily(:, :, 1, month, :)), [], 3);
                end
            elseif strcmp(changeMetric, 'seasonal-monthly-min')
                % calculate the seasonal minimum for each month

                % loop over months
                for month = 1:size(futureDaily, 4)
                    futureData(:, :, y-futurePeriodYears(1)+1, month) = nanmin(squeeze(futureDaily(:, :, 1, month, :)), [], 3);
                end
            
            elseif strcmp(changeMetric, 'seasonal-monthly-mean-max') 
                % calculate the seasonal mean daily maximum for each month

                % loop over months
                for month = 1:size(futureDaily, 4)
                    futureData(:, :, y-futurePeriodYears(1)+1, month) = nanmean(squeeze(futureDaily(:, :, 1, month, :)), 3);
                end
            elseif strcmp(changeMetric, 'seasonal-monthly-mean-min') 
                % calculate the seasonal mean daily minimum for each month

                % loop over months
                for month = 1:size(futureDaily, 4)
                    futureData(:, :, y-futurePeriodYears(1)+1, month) = nanmean(squeeze(futureDaily(:, :, 1, month, :)), 3);
                end

            elseif strcmp(changeMetric, 'ann-max')

                % store annual max temperature at each gridbox for this year
                futureData(:, :, y-futurePeriodYears(1)+1) = nanmax(squeeze(futureDaily), [], 3);

            elseif strcmp(changeMetric, 'ann-min')

                % store annual max temperature at each gridbox for this year
                futureData(:, :, y-futurePeriodYears(1)+1) = nanmin(squeeze(futureDaily), [], 3);

            elseif strcmp(changeMetric, 'daily-max') || strcmp(changeMetric, 'daily-min')

                % store annual max temperature at each gridbox for this year
                futureData(:, :, y-futurePeriodYears(1)+1) = nanmean(squeeze(futureDaily), 3);

            end

            clear futureDaily futureDaily3d;
        end
        
        if strcmp(changeMetric, 'ann-max') || strcmp(changeMetric, 'daily-max') || ...
           strcmp(changeMetric, 'ann-min') || strcmp(changeMetric, 'daily-min')
            % if computing annual maximum or mean daily maximum, take the mean across all
            % years (futureData now 3D: (x, y))
            futureData = nanmean(futureData, 3);
            
            % calculate change for the current base period model:
            chgData = futureData - baseData(:, :, m);

        elseif strcmp(changeMetric, 'seasonal-monthly-max') || strcmp(changeMetric, 'seasonal-monthly-mean-max') || ...
               strcmp(changeMetric, 'seasonal-monthly-min') || strcmp(changeMetric, 'seasonal-monthly-mean-min')
            % if computing seasonal metrics, average over all the annual
            % maximum or mean daily maximum, take the mean across all years
            % (futureData now 4D: (x, y, year, month))
            futureData = squeeze(nanmean(futureData, 3));
            
            % calculate change for the current base period model, average over base models:
            chgData = futureData - squeeze(baseData(:, :, m, :));
        end

        save(['2017-concurrent-heat/tasmax/chgData-cmip5-' changeMetric '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '.mat'], 'chgData');

    end
end
