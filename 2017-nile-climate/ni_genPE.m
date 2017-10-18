% generate changes at a temperature percentile, annual-max, or daily-max
% across models and decades.

basePeriod = 'past';

% add in base models and add to the base loading loop

dataset = 'cmip5';

prVar = 'pr';
lhtflVar = 'hfls';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'ec-earth', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'ipsl-cm5b-lr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
models = {'access1-0'};

baseRcps = {'historical'};
baseEnsemble = 'r1i1p1';

futureDataset = '';

% futureModels = {'access1-0'};
futureRcps = {'rcp85'};
futureEnsemble = 'r1i1p1';

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2004;

futurePeriods = [2060:2080];

baseDir = 'e:/data';
yearStep = 1;

load lat;
load lon;

% what change to look at:
changeMetric = 'monthly-mean';

numDays = 372;

load waterGrid;
waterGrid = logical(waterGrid);

% temperature data (thresh, ann-max, or daily-max)
basePE = [];

['loading base: ' dataset]
for m = 1:length(models)
    curModel = models{m};

    ['loading base model ' curModel '...']

    for y = basePeriodYears(1):yearStep:basePeriodYears(end)
        ['year ' num2str(y) '...']

        if strcmp(dataset, 'cmip5')
            basePr = loadDailyData([baseDir '/' dataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' prVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            % convert to mm/day
            basePr{3} = basePr{3} .* 3600 .* 24;
            
            baseLhtfl = loadDailyData([baseDir '/' dataset '/output/' curModel '/' baseEnsemble '/' baseRcps{1} '/' lhtflVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            % convert to mm/day (from W/m2)
            baseLhtfl{3} = baseLhtfl{3} / 2.45e6 .* 3600 .* 24;
        elseif strcmp(dataset, 'ncep-reanalysis')
            basePr = loadDailyData([baseDir '/ncep-reanalysis/output/prate/regrid/world'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            % convert to mm/day
            basePr{3} = basePr{3} .* 3600 .* 24;
            
            baseLhtfl = loadDailyData([baseDir '/ncep-reanalysis/output/lhtfl/regrid/world'], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            % convert to mm/day (from W/m2)
            baseLhtfl{3} = baseLhtfl{3} / 2.45e6 .* 3600 .* 24;
        end
        
        % remove lat/lon data (we loaded this earlier)
        basePr = basePr{3};
        baseLhtfl = baseLhtfl{3};
        
        % calculate precip - evapotranspiration
        PE = basePr - baseLhtfl;
        
        % set water grid cells to NaN
        % include loops for month and day (5D) in case we are using
        % seasonal change metric
        for i = 1:size(PE, 3)
            for j = 1:size(PE, 4)
                for k = 1:size(PE, 5)
                    curGrid = PE(:, :, i, j, k);
                    curGrid(waterGrid) = NaN;
                    PE(:, :, i, j, k) = curGrid;
                end
            end
        end
        
            
        if strcmp(changeMetric, 'monthly-mean')
            % calculate the seasonal mean for each month
            
            % loop over months
            for month = 1:size(PE, 4)
                basePE(:, :, m, y-basePeriodYears(1)+1, month) = nanmean(squeeze(PE(:, :, 1, month, :)), 3);
            end
        end

        clear basePr baseLhtfl;
    end
end


if strcmp(changeMetric, 'monthly-mean')
    % if computing seasonal metrics, average over all the annual
    % maximum or mean daily maximum, take the mean across all years
    % (baseData now 4D: (x, y, model, month))
    basePE = squeeze(nanmean(basePE, 4));
end

if strcmp(dataset, 'ncep-reanalysis')
    PE = basePE;
    save(['2017-nile-climate/data/pe/chgData-ncep-reanalysis-' changeMetric '-historical.mat'], 'PE');
    return;
end

% ------------ load future data -------------    

for f = 1:size(futurePeriods, 1)
    
    futurePeriodYears = futurePeriods(f, :);

    ['loading future: ' futureDataset]
    for m = 1:length(models)
        curModel = models{m};
        
        PE = [];

        ['loading future model ' curModel '...']

        for y = futurePeriodYears(1):yearStep:futurePeriodYears(end)
            ['year ' num2str(y) '...']
            
            futurePr = loadDailyData([baseDir '/' futureDataset '/output/' curModel '/' futureEnsemble '/' futureRcps{1} '/' prVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            % convert to mm/day
            futurePr{3} = basePr{3} .* 3600 .* 24;
            
            futureLhtfl = loadDailyData([baseDir '/' futureDataset '/output/' curModel '/' futureEnsemble '/' futureRcps{1} '/' lhtflVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
            % convert to mm/day (from W/m2)
            futureLhtfl{3} = futureLhtfl{3} / 2.45e6 .* 3600 .* 24;

            % calculate future precip-evapotranspiration
            futurePE = futurePr{3}-futureLhtfl{3};

            % set water grid cells to NaN
            % include loops for month and day (5D) in case we are using
            % seasonal change metric
            for i = 1:size(futurePE, 3)
                for j = 1:size(futurePE, 4)
                    for k = 1:size(futurePE, 5)
                        curGrid = futurePE(:, :, i, j, k);
                        curGrid(waterGrid) = NaN;
                        futurePE(:, :, i, j, k) = curGrid;
                    end
                end
            end

            if strcmp(changeMetric, 'monthly-mean')
                % calculate the monthly-mean change

                % loop over months
                for month = 1:size(futurePE, 4)
                    PE(:, :, y-futurePeriodYears(1)+1, month) = nanmean(squeeze(futurePE(:, :, 1, month, :)), 3);
                end
            end
        end

        chgPE = PE-basePE;
        save(['2017-nile-climate/data/pe/chgData-cmip5-' changeMetric '-' curModel '-' futureRcps{1} '-' num2str(futurePeriodYears(1)) '-' num2str(futurePeriodYears(end)) '.mat'], 'chgPE');

    end
end
