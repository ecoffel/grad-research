
dataset = 'cmip5';
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};
          
% for wb
% models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
%           'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-cm3', 'gfdl-esm2g', ...
%           'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
%           'ipsl-cm5b-lr', 'miroc5', 'mri-cgcm3', 'noresm1-m'};

% for era
%models = {''};

var = 'tasmin';
timePeriod = 'future';


if ~exist('tasmin')
        for m = 1:length(models)
            fprintf('loading %s...\n', models{m});
            
            if strcmp(dataset, 'cmip5')
                if strcmp(timePeriod, 'historical')
                    tasmin = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/' var '/regrid/world'], 'startYear', 1981, 'endYear', 2005);
                    timePeriodStr = '1981-2005';
                elseif strcmp(timePeriod, 'future')
                    tasmin = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/rcp85/' var '/regrid/world'], 'startYear', 2061, 'endYear', 2085);
                    timePeriodStr = '2061-2085';
                end
            elseif strcmp(dataset, 'era')
                tasmin = loadDailyData(['e:/data/era-interim/output/mn2t/regrid/world'], 'startYear', 1981, 'endYear', 2016);
                timePeriodStr = '1981-2016';
            end
            
            tasmin = tasmin{3};
            if nanmean(nanmean(nanmean(nanmean(nanmean(tasmin))))) > 100
                tasmin = tasmin - 273.15;
            end
            
            tnnMonths = [];
            tnnDays = [];
            

            for xlat = 1:size(tasmin, 1)
                for ylon = 1:size(tasmin, 2)

                    months = zeros([size(tasmin, 3), 1]);
                    months(months == 0) = NaN;

                    days = zeros([size(tasmin, 3), 1]);
                    days(days == 0) = NaN;

                    for year = 1:size(tasmin, 3)
                        t = squeeze(reshape(permute(squeeze(tasmin(xlat, ylon, year, :, :)), [2 1]), [numel(tasmin(xlat, ylon, year, :, :)), 1]));

                        ind = find(t == nanmin(t));
                        if length(ind) > 0
                            monthdays = length(t) / 12;
                            months(year) = ceil(ind(1)/monthdays);
                            days(year) = ind(1);
                        end
                    end

                    tnnMonths(xlat, ylon, :) = months;
                    tnnDays(xlat, ylon, :) = days;

                    if length(months) > 0
                        uMonths = unique(months);
                    end                        
                end
            end
            
            if strcmp(dataset, 'cmip5')
                if strcmp(var, 'wb-davies-jones-full')
                    save(['2017-bowen/txx-timing/' var '-months-' models{m} '-' timePeriod '-' dataset '-' timePeriodStr '.mat'], 'txxMonths');
                    save(['2017-bowen/txx-timing/' var '-days-' models{m} '-' timePeriod '-' dataset '-' timePeriodStr '.mat'], 'txxDays');
                else
                    save(['e:/data/projects/snow/tnn-timing/tnn-months-' models{m} '-' timePeriod '-' dataset '-' timePeriodStr '.mat'], 'tnnMonths');
                    save(['e:/data/projects/snow/tnn-timing/tnn-days-' models{m} '-' timePeriod '-' dataset '-' timePeriodStr '.mat'], 'tnnDays');
                end
            elseif strcmp(dataset, 'era')
                save(['2017-bowen/txx-timing/wb-davies-jones-full-months-era-' timePeriodStr '.mat'], 'txxMonths');
                save(['2017-bowen/txx-timing/wb-davies-jones-full-days-era-' timePeriodStr '.mat'], 'txxDays');
            end
            
        end
end


