txxrel = true;
onlyRegularTxx = false;

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
% models = {''};
hottestSeason = [];
hottestSeasonLength = [];

var = 'tasmax';
timePeriod = 'historical';

lat = [];
lon = [];

if ~exist('tasmax')
        for m = 1:length(models)
            fprintf('loading %s...\n', models{m});
            
            if strcmp(dataset, 'cmip5')
                if strcmp(timePeriod, 'historical')
                    tasmax = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/' var '/'], 'startYear', 1981, 'endYear', 2005);
                    lat = tasmax{1};
                    lon = tasmax{2};
                    timePeriodStr = '1981-2005';
                elseif strcmp(timePeriod, 'future')
                    tasmax = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/rcp85/' var '/regrid/world'], 'startYear', 2061, 'endYear', 2085);
                    timePeriodStr = '2061-2085';
                end
            elseif strcmp(dataset, 'era')
                tasmax = loadDailyData(['e:/data/era-interim/output/wb-davies-jones-full/regrid/world'], 'startYear', 1981, 'endYear', 2016);
                timePeriodStr = '1981-2016';
            end
            
            tasmax = tasmax{3};
            if nanmean(nanmean(nanmean(nanmean(nanmean(tasmax))))) > 100
                tasmax = tasmax - 273.15;
            end
            
            txxMonths = [];
            txxDays = [];
            

            for xlat = 1:size(tasmax, 1)
                for ylon = 1:size(tasmax, 2)

                    if txxrel
                        months = zeros([size(tasmax, 3), 1]);
                        months(months == 0) = NaN;
                        
                        days = zeros([size(tasmax, 3), 1]);
                        days(days == 0) = NaN;

                        for year = 1:size(tasmax, 3)
                            t = squeeze(reshape(permute(squeeze(tasmax(xlat, ylon, year, :, :)), [2 1]), [numel(tasmax(xlat, ylon, year, :, :)), 1]));

                            ind = find(t == nanmax(t));
                            if length(ind) > 0
                                monthdays = length(t) / 12;
                                months(year) = ceil(ind(1)/monthdays);
                                days(year) = ind(1);
                            end
                        end

                        txxMonths(xlat, ylon, :) = months;
                        txxDays(xlat, ylon, :) = days;
                        
                        if length(months) > 0
                            uMonths = unique(months);
                            hottestSeasonLength(xlat, ylon, m) = length(uMonths);
                        else
                            hottestSeasonLength(xlat, ylon, m) = NaN;
                        end

                        % 3 or less months that have txx in them
                        %if length(uMonths) > 0 && length(uMonths) <= 4
                        if length(months) > 0
                            hottestSeason(xlat, ylon, m) = mode(months);
                        else
                            hottestSeason(xlat, ylon, m) = NaN;
                        end
                        %else
                        %    hottestSeason(xlat, ylon, m) = NaN;
                        %end
                        
                    else

                    sind = -1;
                    stemp = -1;

                        for s = 1:size(seasons, 1)
                            t = squeeze(nanmean(nanmean(tasmax(xlat, ylon, :, seasons(s,:)), 4), 3));
                            if sind == -1 || t > stemp
                                sind = s;
                                stemp = t;
                            end
                        end

                        hottestSeason(xlat, ylon, m) = sind;
                    end
                end
            end
            
            if strcmp(dataset, 'cmip5')
                if strcmp(var, 'wb-davies-jones-full')
                    save(['2017-bowen/txx-timing/' var '-months-' models{m} '-' timePeriod '-' dataset '-' timePeriodStr '.mat'], 'txxMonths');
                    save(['2017-bowen/txx-timing/' var '-days-' models{m} '-' timePeriod '-' dataset '-' timePeriodStr '.mat'], 'txxDays');
                else
                    save(['2017-bowen/txx-timing/txx-months-' models{m} '-' timePeriod '-' dataset '-' timePeriodStr '.mat'], 'txxMonths');
                    save(['2017-bowen/txx-timing/txx-days-' models{m} '-' timePeriod '-' dataset '-' timePeriodStr '.mat'], 'txxDays');
                end
            elseif strcmp(dataset, 'era')
                save(['2017-bowen/txx-timing/wb-davies-jones-full-months-era-' timePeriodStr '.mat'], 'txxMonths');
                save(['2017-bowen/txx-timing/wb-davies-jones-full-days-era-' timePeriodStr '.mat'], 'txxDays');
            end
            
        end
end

load lat;
load lon;

result = {lat, lon, hottestSeasonNoRegrid};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [1, 13], ...
                  'cbXTicks', 1:12, ...
                  'plotTitle', [], ...
                  'fileTitle', ['hottest-season-no-regrid.eps'], ...
                  'plotXUnits', ['Month'], ...
                  'blockWater', true, ...
                  'colormap', circshift(brewermap(12,'Spectral'),6,1));
plotFromDataFile(saveData);

if txxrel
    if onlyRegularTxx
        save(['2017-bowen/hottest-season-txx-rel-' dataset '.mat'], 'hottestSeason');
        save(['2017-bowen/hottest-season-length-txx-rel-' dataset '.mat'], 'hottestSeasonLength');
    else
        save(['2017-bowen/hottest-season-txx-rel-' dataset '-all-txx.mat'], 'hottestSeason');
        save(['2017-bowen/hottest-season-length-txx-rel-' dataset '-all-txx.mat'], 'hottestSeasonLength');
    end
else
    save('2017-bowen/hottest-season-era.mat', 'hottestSeason');
end

