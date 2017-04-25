% For each grid cell, find the mean Bowen ratio at each 1-deg daily maximum temperature
% increment

season = 'all';
basePeriod = 'past';

dataset = 'cmip5';
bowenVar = 'bowen';
tempVar = 'tasmax';

models = {'access1-0', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'cmcc-cm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'gfdl-cm3', 'gfdl-esm2g', 'gfdl-esm2m', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3'};

rcp = 'historical';
ensemble = 'r1i1p1';

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1981:2004;
futurePeriodYears = 2060:2080;

if strcmp(rcp, 'historical')
    timePeriod = basePeriodYears;
elseif strcmp(rcp, 'rcp45') || strcmp(rcp, 'rcp85')
    timePeriod = futurePeriodYears;
end

baseDir = 'e:/data';
yearStep = 1;

load lat;
load lon;

% monthly mean bowen ratios
% dimensions: (model, x, y, month)
monthlyMeans = zeros(length(models), size(lat, 1), size(lat, 2), 12);
monthlyMeans(monthlyMeans == 0) = NaN;

['loading base: ' dataset]
for m = 1:length(models)
    curModel = models{m};

    ['loading base model ' curModel '...']

    for y = basePeriodYears(1):yearStep:basePeriodYears(end)
        ['year ' num2str(y) '...']

        baseDailyBowen = loadDailyData([baseDir '/' dataset '/output/' curModel '/' ensemble '/' rcp '/' bowenVar '/regrid/' region], 'yearStart', y, 'yearEnd', (y+yearStep)-1);
        
        % remove lat/lon data (we loaded this earlier)
        baseDailyBowen = baseDailyBowen{3};
        
        % set overly large ratios to NaN
        baseDailyBowen(baseDailyBowen > 100) = NaN;
        baseDailyBowen(baseDailyBowen < 0.01) = NaN;
        
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
                        if monthlyMeans(m, xlat, ylon, month) == NaN
                            % if nan, set it to current month's mean
                            % directly
                            monthlyMeans(m, xlat, ylon, month) = squeeze(nanmean(baseDailyBowen(xlat, ylon, year, month, :)));
                        else
                            % otherwise, take mean of current monthly mean
                            % and existing mean
                            monthlyMeans(m, xlat, ylon, month) = nanmean([monthlyMeans(m, xlat, ylon, month), squeeze(nanmean(baseDailyBowen(xlat, ylon, year, month, :)))]);
                        end
                    end
                end
            end
        end        
        clear baseDailyBowen;
    end
    
    save(['2017-concurrent-heat/bowen/monthly-mean-' rcp '-' curModel '.mat'], 'monthlyMeans');
end



