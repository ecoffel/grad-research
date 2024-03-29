season = 'all';

dataset = 'cmip5';
var = 'tasmax';

isMonthly = false;

skipExisting = true;

if strcmp(dataset, 'cmip5')
%     if strcmp(var, 'mrsos')
%         models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%                   'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%                   'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%                   'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
%                   'mri-cgcm3', 'noresm1-m'};
%     elseif strcmp(var, 'clt') | strcmp(var, 'rsds') | strcmp(var, 'rsus')
%         models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%                   'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%                   'fgoals-g2', 'hadgem2-cc', ...
%                   'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
%                   'mri-cgcm3', 'noresm1-m'};
%     else
        models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
%     end

    rcp = 'rcp85';
    ensemble = 'r1i1p1';
elseif strcmp(dataset, 'ncep-reanalysis')
    models = {''};
    rcp = 'historical';
    ensemble = '';
elseif strcmp(dataset, 'era-interim')
    models = {''};
    rcp = 'historical';
    ensemble = '';
end

% mean for each year/month or for each month averaged over all years
avgOverYears = true;
avgOverYearsStr = '-all-years';
if avgOverYears
    avgOverYearsStr = '';
end

baseRegrid = true;
futureRegrid = true;

region = 'world';
basePeriodYears = 1985:2004;
futurePeriodYears = 2060:2079;

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
load waterGrid;
waterGrid = logical(waterGrid);

['loading base: ' dataset]
for m = 1:length(models)
    curModel = models{m};
    
    if skipExisting && exist([outputDir '/monthly-mean-' var '-' dataset '-' rcp '-' curModel avgOverYearsStr '.mat'], 'file')
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
            if isMonthly
                baseDaily = loadMonthlyData([baseDir '/' dataset '/output/' curModel '/mon/' ensemble '/' rcp '/' var '/regrid/' region], var, 'startYear', y, 'endYear', (y+yearStep)-1);
            else
                baseDaily = loadDailyData([baseDir '/' dataset '/output/' curModel '/' ensemble '/' rcp '/' var '/regrid/' region], 'startYear', y, 'endYear', (y+yearStep)-1);
            end
        elseif strcmp(dataset, 'ncep-reanalysis')
            baseDaily = loadDailyData([baseDir '/' dataset '/output/'  var '/regrid/' region], 'startYear', y, 'endYear', (y+yearStep)-1);
        elseif strcmp(dataset, 'era-interim')
            baseDaily = loadDailyData([baseDir '/' dataset '/output/'  var '/regrid/' region], 'startYear', y, 'endYear', (y+yearStep)-1);
        end
        
        % remove lat/lon data (we loaded this earlier)
        baseDaily = baseDaily{3};
        
        if strcmp(var, 'bowen')
            % set overly large ratios to NaN
            baseDaily(baseDaily > 100) = NaN;
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
                
                if waterGrid(xlat, ylon)
                    continue
                end
                
                % loop over years
                for year = 1:size(baseDaily, 3)

                    % and over months
                    for month = 1:size(baseDaily, 4)

                        if avgOverYears
                            % calculate mean for this month6                                
                            if isnan(monthlyMeans(xlat, ylon, month))
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
    
	save([outputDir '/monthly-mean-' var '-' dataset '-' rcp '-' curModel avgOverYearsStr '.mat'], 'monthlyMeans');

end



