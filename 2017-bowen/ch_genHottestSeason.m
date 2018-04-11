txxrel = true;
onlyRegularTxx = false;

dataset = 'cmip5';
models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

hottestSeason = [];
hottestSeasonLength = [];
txxMonths = [];

if ~exist('tasmax')
    if strcmp(dataset, 'cmip5')
        for m = 1:length(models)
            fprintf('loading %s...\n', models{m});
            %tasmax = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/historical/tasmax/regrid/world'], 'startYear', 1980, 'endYear', 2004);
            tasmax = loadDailyData(['e:/data/cmip5/output/' models{m} '/r1i1p1/rcp85/tasmax/regrid/world'], 'startYear', 2060, 'endYear', 2079);
            
            tasmax = tasmax{3};
            if nanmean(nanmean(nanmean(nanmean(nanmean(tasmax))))) > 100
                tasmax = tasmax - 273.15;
            end
            

            for xlat = 1:size(tasmax, 1)
                for ylon = 1:size(tasmax, 2)

                    if txxrel
                        months = zeros([size(tasmax, 3), 1]);
                        months(months == 0) = NaN;

                        for year = 1:size(tasmax, 3)
                            t = squeeze(reshape(permute(squeeze(tasmax(xlat, ylon, year, :, :)), [2 1]), [numel(tasmax(xlat, ylon, year, :, :)), 1]));

                            ind = find(t == nanmax(t));
                            if length(ind) > 0
                                monthdays = length(t) / 12;
                                months(year) = ceil(ind(1)/monthdays);
                            end
                        end

                        txxMonths(xlat, ylon, m, :) = months;
                        
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
        end
    else
        %tasmax = loadDailyData('e:/data/era-interim/output/mx2t/regrid/world', 'yearStart', 1980, 'yearEnd', 2015);
        tasmax = loadDailyData('e:/data/ncep-reanalysis/output/tmax/regrid/world', 'startYear', 1980, 'endYear', 2015);
        tasmax{3} = tasmax{3} - 273.15;

        if txxrel
            tasmax = tasmax{3};
        else
            tasmax = dailyToMonthly(tasmax);
            tasmax = tasmax{3};
        end
    end
end

load lat;
load lon;

plotModelData({lat,lon,nanmedian(hottestSeasonLength, 3)},'world','caxis',[1 12])

if txxrel
    save(['2017-bowen/txx-months-future-' dataset '.mat'], 'txxMonths');
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

