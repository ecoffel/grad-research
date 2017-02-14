% generate changes at a temperature percentile, annual-max, or daily-max
% across models and decades.

season = 'all';
basePeriod = 'past';

% add in base models and add to the base loading loop

baseDataset = 'cmip5';
baseVar = 'tasmax';

% baseModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%               'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
baseModels = {'access1-0'};
baseRcps = {'historical'};
baseEnsemble = 'r1i1p1';

futureDataset = 'cmip5';
futureVar = 'tasmax';

% futureModels = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%               'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
futureModels = {'access1-0'};
futureRcps = {'rcp85'};
futureEnsemble = 'r1i1p1';

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2004;

futurePeriods = [2020:2030; ...
                 2030:2040; ...
                 2040:2050; ...
                 2050:2060; ...
                 2060:2070; ...
                 2070:2080];

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

% what change to look at:
% ann-max = annual max temperature
% daily-max = mean daily max temperature
% thresh = changes above temperature thresholds specified in thresh
changeMetric = 'ann-max';

% if changeMetric == 'thresh', look at change above these base period temperature percentiles
thresh = [1 10:10:90 99];

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

        % if any kelvin values, convert to C
        if baseDaily{3}(1,1,1,1,1) > 100
            baseDaily{3} = baseDaily{3} - 273.15;
        end

        % reshape to be 3D (x, y, day)
        baseDaily3d = reshape(baseDaily{3}, [size(baseDaily{3}, 1), size(baseDaily{3}, 2), ...
                                             size(baseDaily{3}, 3)*size(baseDaily{3}, 4)*size(baseDaily{3}, 5)]);

        % set water grid cells to NaN
        for d = 1:size(baseDaily3d, 3)
            curGrid = baseDaily3d(:, :, d);
            curGrid(waterGrid) = NaN;
            baseDaily3d(:, :, d) = curGrid;
        end

        if strcmp(changeMetric, 'thresh')
            % calculate base period thresholds

            % loop over all thresholds
            for t = 1:length(thresh)
                % over x coords
                for xlat = 1:size(baseDaily3d, 1)
                    % over y coords
                    for ylon = 1:size(baseDaily3d, 2)

                        % skip if NaN (water)
                        if isnan(baseDaily3d(xlat, ylon, 1))
                            continue;
                        end

                        % calculate threshold at current (x,y) and
                        % percentile 
                        baseData(xlat, ylon, m, y-basePeriodYears(1)+1, t) = prctile(squeeze(baseDaily3d(xlat, ylon, :)), thresh(t));
                    end
                end
            end
        elseif strcmp(changeMetric, 'ann-max')

            % store annual max temperature at each gridbox for this year
            baseData(:, :, m, y-basePeriodYears(1)+1) = nanmax(squeeze(baseDaily3d), [], 3);

        elseif strcmp(changeMetric, 'daily-max')

            % store mean daily max temperature at each gridbox for this year
            baseData(:, :, m, y-basePeriodYears(1)+1) = nanmean(squeeze(baseDaily3d), 3);

        end

        clear baseDaily baseDaily3d;
    end
end


if strcmp(changeMetric, 'ann-max') || strcmp(changeMetric, 'daily-max')
    % if computing annual maximum or mean daily maximum, take the mean across all base period
    % years (baseData now 3D: (x, y, model))
    baseData = nanmean(baseData, 4);
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

            % convert any kelvin values to C
            if futureDaily{3}(1,1,1,1,1) > 100
                futureDaily{3} = futureDaily{3} - 273.15;
            end

            % reshape to 3D (x, y, day)
            futureDaily3d = reshape(futureDaily{3}, [size(futureDaily{3}, 1), size(futureDaily{3}, 2), ...
                                                     size(futureDaily{3}, 3)*size(futureDaily{3}, 4)*size(futureDaily{3}, 5)]);


            % set water grid cells to NaN
            for d = 1:size(futureDaily3d, 3)
                curGrid = futureDaily3d(:, :, d);
                curGrid(waterGrid) = NaN;
                futureDaily3d(:, :, d) = curGrid;
            end

            if strcmp(changeMetric, 'thresh')
                % loop over thresholds
                for t = 1:length(thresh)
                    % latitude
                    for xlat = 1:size(futureDaily3d, 1)
                        % longitude
                        for ylon = 1:size(futureDaily3d, 2)

                            if isnan(futureDaily3d(xlat, ylon, 1))
                                continue;
                            end

                            % compute percentile threshold for this grid cell
                            % and year
                            futureData(xlat, ylon, m, y-futurePeriodYears(1)+1, t) = prctile(squeeze(futureDaily3d(xlat, ylon, :)), thresh(t));
                        end
                    end
                end

            elseif strcmp(changeMetric, 'ann-max')

                % store annual max temperature at each gridbox for this year
                futureData(:, :, m, y-futurePeriodYears(1)+1) = nanmax(squeeze(futureDaily3d), [], 3);

            elseif strcmp(changeMetric, 'daily-max')

                % store annual max temperature at each gridbox for this year
                futureData(:, :, m, y-futurePeriodYears(1)+1) = nanmean(squeeze(futureDaily3d), 3);

            end

            clear futureDaily futureDaily3d;
        end
    end

    if strcmp(changeMetric, 'ann-max') || strcmp(changeMetric, 'daily-max')
        % if computing annual maximum or mean daily maximum, take the mean across all base period
        % years (futureData now 3D: (x, y, model))
        futureData = nanmean(futureData, 4);
    end

    % now baseData and futureData should have the same dimensions, so calculate
    % change:
    chgData = futureData - baseData;

    save(['chgData-cmip5-' changeMetric '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '.mat'], 'chgData');
end
