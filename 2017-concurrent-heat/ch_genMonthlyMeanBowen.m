% For each grid cell, find the mean Bowen ratio at each 1-deg daily maximum temperature
% increment

season = 'all';

dataset = 'ncep-reanalysis';
bowenVar = 'bowen';
tempVar = 'tasmax';

if strcmp(dataset, 'cmip5')
    models = {'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
                  'cmcc-cm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
                  'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', ...
                  'hadgem2-es', 'inmcm4', 'miroc-esm', ...
                  'mpi-esm-mr', 'mri-cgcm3'};

    rcp = 'rcp85';
    ensemble = 'r1i1p1';
elseif strcmp(dataset, 'ncep-reanalysis')
    models = {''};
    rcp = '';
    ensemble = '';
end

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2004;
futurePeriodYears = 2070:2080;

if strcmp(rcp, 'historical') || strcmp(dataset, 'ncep-reanalysis')
    timePeriod = basePeriodYears;
elseif strcmp(rcp, 'rcp45') || strcmp(rcp, 'rcp85')
    timePeriod = futurePeriodYears;
end

baseDir = 'f:/data';
yearStep = 1;

load lat;
load lon;

['loading base: ' dataset]
for m = 1:length(models)
    curModel = models{m};
    
    if exist(['2017-concurrent-heat/bowen/monthly-mean-' rcp '-' curModel '.mat'], 'file')
        ['skipping ' curModel ', ' rcp '...']
        continue;
    end
    
    % monthly mean bowen ratios
    % dimensions: (model, x, y, month)
    monthlyMeans = zeros(size(lat, 1), size(lat, 2), 12);
    monthlyMeans(monthlyMeans == 0) = NaN;

    ['loading base model ' curModel '...']

    for y = timePeriod(1):yearStep:timePeriod(end)
        ['year ' num2str(y) '...']

        baseDailyBowen = loadDailyData([baseDir '/' dataset '/output/' curModel '/' ensemble '/' rcp '/' bowenVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        
        % remove lat/lon data (we loaded this earlier)
        baseDailyBowen = baseDailyBowen{3};
        
        % set overly large ratios to NaN
        baseDailyBowen(baseDailyBowen > 100) = NaN;
        baseDailyBowen(baseDailyBowen < 0) = NaN;
        
        % map temps onto bowen ratios
        % loop over lat
        for xlat = 1:size(baseDailyBowen, 1)
            
            % loop over lon
            for ylon = 1:size(baseDailyBowen, 2)
                
                % loop over years
                for year = 1:size(baseDailyBowen, 3)
                    
                    % and over months
                    for month = 1:size(baseDailyBowen, 4)
                        
                        % calculate mean for this month
                        if monthlyMeans(xlat, ylon, month) == NaN
                            % if nan, set it to current month's mean
                            % directly
                            monthlyMeans(xlat, ylon, month) = squeeze(nanmean(baseDailyBowen(xlat, ylon, year, month, :)));
                        else
                            % otherwise, take mean of current monthly mean
                            % and existing mean
                            monthlyMeans(xlat, ylon, month) = nanmean([monthlyMeans(xlat, ylon, month), squeeze(nanmean(baseDailyBowen(xlat, ylon, year, month, :)))]);
                        end
                    end
                end
            end
        end        
        clear baseDailyBowen;
    end
    
    save(['2017-concurrent-heat/bowen/monthly-mean-' dataset '-' rcp '-' curModel '.mat'], 'monthlyMeans');
end



