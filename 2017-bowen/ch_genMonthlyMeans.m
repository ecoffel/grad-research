% For each grid cell, find the mean Bowen ratio at each 1-deg daily maximum temperature
% increment

season = 'all';

dataset = 'era-interim';
var = 'bowen';

if strcmp(dataset, 'cmip5')
    models = {'access1-0', 'access1-3', 'bnu-esm', 'canesm2', ...
                      'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                      'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
                      'hadgem2-es', 'ipsl-cm5a-mr', 'miroc-esm', ...
                      'mpi-esm-mr', 'mri-cgcm3'};

    rcp = 'historical';
    ensemble = 'r1i1p1';
elseif strcmp(dataset, 'ncep-reanalysis')
    models = {'ncep-reanalysis'};
    rcp = 'historical';
    ensemble = '';
elseif strcmp(dataset, 'era-interim')
    models = {'era-interim'};
    rcp = 'historical';
    ensemble = '';
end

% mean for each year/month or for each month averaged over all years
avgOverYears = false;
avgOverYearsStr = '-all-years-';
if avgOverYears
    avgOverYearsStr = '';
end

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2004;
futurePeriodYears = 2070:2080;

if strcmp(rcp, 'historical') || strcmp(dataset, 'ncep-reanalysis') || strcmp(dataset, 'era-interim')
    timePeriod = basePeriodYears;
elseif strcmp(rcp, 'rcp45') || strcmp(rcp, 'rcp85')
    timePeriod = futurePeriodYears;
end

baseDir = 'e:/data';
outputDir = 'e:/data/projects/bowen/temp-chg-data';
yearStep = 1;

load lat;
load lon;

['loading base: ' dataset]
for m = 1:length(models)
    curModel = models{m};
    
    if exist([outputDir '/monthly-mean-' rcp '-' curModel '.mat'], 'file')
        ['skipping ' curModel ', ' rcp '...']
        continue;
    end
    
    % monthly mean bowen ratios
    % dimensions: (model, x, y, month)
    if avgOverYears
        monthlyMeans = zeros(size(lat, 1), size(lat, 2), 12);
    else
        monthlyMeans = zeros(size(lat, 1), size(lat, 2), length(timePeriod), 12);
    end
    monthlyMeans(monthlyMeans == 0) = NaN;

    ['loading base model ' curModel '...']

    for y = timePeriod(1):yearStep:timePeriod(end)
        ['year ' num2str(y) '...']

        
        if strcmp(dataset, 'cmip5')
            baseDaily = loadDailyData([baseDir '/' dataset '/output/' curModel '/' ensemble '/' rcp '/' var '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        elseif strcmp(dataset, 'ncep-reanalysis')
            baseDaily = loadDailyData([baseDir '/' dataset '/output/'  var '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        elseif strcmp(dataset, 'era-interim')
            baseDaily = loadDailyData([baseDir '/' dataset '/output/'  var '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        end
        
        % remove lat/lon data (we loaded this earlier)
        baseDaily = baseDaily{3};
        
        if strcmp(var, 'bowen')
            % set overly large ratios to NaN
            baseDaily(baseDaily > 100) = NaN;
            baseDaily(baseDaily < 0) = NaN;
        elseif strcmp(var, 'tasmax')
            if baseDaily(1,1,1,1,1) > 100
                baseDaily = baseDaily - 273.15;
            end
        end
        
        % map temps onto bowen ratios
        % loop over lat
        for xlat = 1:size(baseDaily, 1)
            
            % loop over lon
            for ylon = 1:size(baseDaily, 2)
                
                
                    % loop over years
                    for year = 1:size(baseDaily, 3)

                        % and over months
                        for month = 1:size(baseDaily, 4)

                            if avgOverYears
                                % calculate mean for this month
                                if monthlyMeans(xlat, ylon, month) == NaN
                                    % if nan, set it to current month's mean
                                    % directly
                                    monthlyMeans(xlat, ylon, month) = squeeze(nanmean(baseDaily(xlat, ylon, year, month, :)));
                                else
                                    % otherwise, take mean of current monthly mean
                                    % and existing mean
                                    monthlyMeans(xlat, ylon, month) = nanmean([monthlyMeans(xlat, ylon, month), squeeze(nanmean(baseDaily(xlat, ylon, year, month, :)))]);
                                end
                            else
                                % store the mean for this month & year
                                monthlyMeans(xlat, ylon, y-timePeriod(1)+1, month) = squeeze(nanmean(baseDaily(xlat, ylon, year, month, :)));
                            end
                        end
                    end
            end
        end        
        clear baseDailyBowen;
    end
    
    if strcmp(dataset, 'cmip5')
        save([outputDir '/monthly-mean-' var '-' dataset '-' rcp '-' curModel avgOverYearsStr '.mat'], 'monthlyMeans');
    else
        save([outputDir '/monthly-mean-' var '-' dataset '-' rcp avgOverYearsStr '.mat'], 'monthlyMeans');
    end
end



