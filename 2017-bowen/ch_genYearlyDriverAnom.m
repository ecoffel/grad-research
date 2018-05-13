
baseDir = 'e:/data';
var = 'netRad';

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

timePeriodHistorical = 1981:2005;
timePeriodFuture = 2061:2085;

load lat;
load lon;

load waterGrid;
waterGrid = logical(waterGrid);

% load hottest seasons for each grid cell
load('2017-bowen/hottest-season-txx-rel-cmip5-all-txx.mat');
load('2017-bowen/txx-months-historical-cmip5-1981-2005.mat');
txxMonthsHist = txxMonths;
load('2017-bowen/txx-months-future-cmip5-2061-2085.mat');
txxMonthsFut = txxMonths;

% historical and future monthly precip, mm/day
% dims: (x, y, model)
regionalFluxHistoricalWarm = zeros(size(lat,1), size(lon,2), 25);
regionalFluxHistoricalWarm(regionalFluxHistoricalWarm==0) = NaN;
regionalFluxHistoricalTxx = zeros(size(lat,1), size(lon,2), 25);
regionalFluxHistoricalTxx(regionalFluxHistoricalTxx==0) = NaN;

regionalFluxFutureWarm = zeros(size(lat,1), size(lon,2), 25);
regionalFluxFutureWarm(regionalFluxFutureWarm==0) = NaN;
regionalFluxFutureTxx = zeros(size(lat,1), size(lon,2), 25);
regionalFluxFutureTxx(regionalFluxFutureTxx==0) = NaN;


for model = 1:length(models)
    
    if exist(['e:/data/projects/bowen/' var '-chg-data/' var '-warm-anom-historical-1981-2005-' models{model} '.mat'])
      %  continue;
    end
    
    fprintf('loading %s historical...\n', models{model});
    flux = loadMonthlyData([baseDir '/cmip5/output/' models{model} '/mon/r1i1p1/historical/' var '/regrid/world'], var, 'startYear', timePeriodHistorical(1), 'endYear', timePeriodHistorical(end));

    % remove water tiles
    for year = 1:size(flux{3}, 3)
        for month = 1:size(flux{3}, 4)
            curGrid = flux{3}(:, :, year, month);
            curGrid(waterGrid) = NaN;
            flux{3}(:, :, year, month) = curGrid;
        end
    end

    % loop over all grid cells and select hottest season flux
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lon, 2)
            if waterGrid(xlat, ylon)
                continue;
            end

            warmMonths = [squeeze(hottestSeason(xlat, ylon, model)-1) squeeze(hottestSeason(xlat, ylon, model)) squeeze(hottestSeason(xlat, ylon, model)+1)];
            warmMonths(warmMonths == 0) = 12;
            warmMonths(warmMonths == 13) = 1;

            curTxxMonths = squeeze(txxMonthsHist(xlat, ylon, model, :));
            for year = 1:size(flux{3},3)
                regionalFluxHistoricalWarm(xlat, ylon, year) = (nanmean(flux{3}(xlat, ylon, year, warmMonths), 4) - nanmean(flux{3}(xlat, ylon, year, :), 4)) ./ nanmean(flux{3}(xlat, ylon, year, :), 4);
                regionalFluxHistoricalTxx(xlat, ylon, year) = (squeeze(flux{3}(xlat, ylon, year, curTxxMonths(year))) - nanmean(flux{3}(xlat, ylon, year, warmMonths), 4)) ./ nanmean(flux{3}(xlat, ylon, year, warmMonths), 4);
            end
        end
    end

    fprintf('loading %s future...\n', models{model});
    flux = loadMonthlyData([baseDir '/cmip5/output/' models{model} '/mon/r1i1p1/rcp85/' var '/regrid/world'], var, 'startYear', timePeriodFuture(1), 'endYear', timePeriodFuture(end));

    % remove water tiles
    for year = 1:size(flux{3}, 3)
        for month = 1:size(flux{3}, 4)
            curGrid = flux{3}(:, :, year, month);
            curGrid(waterGrid) = NaN;
            flux{3}(:, :, year, month) = curGrid;
        end
    end

    % loop over all grid cells and select hottest season flux
    for xlat = 1:size(lat, 1)
        for ylon = 1:size(lon, 2)
            if waterGrid(xlat, ylon)
                continue;
            end

            warmMonths = [squeeze(hottestSeason(xlat, ylon, model)-1) squeeze(hottestSeason(xlat, ylon, model)) squeeze(hottestSeason(xlat, ylon, model)+1)];
            warmMonths(warmMonths == 0) = 12;
            warmMonths(warmMonths == 13) = 1;

            curTxxMonths = squeeze(txxMonthsFut(xlat, ylon, model, :));
            for year = 1:size(flux{3},3)
                regionalFluxFutureWarm(xlat, ylon, year) = (nanmean(flux{3}(xlat, ylon, year, warmMonths), 4) - nanmean(flux{3}(xlat, ylon, year, :), 4)) ./ nanmean(flux{3}(xlat, ylon, year, :), 4);
                regionalFluxFutureTxx(xlat, ylon, year) = (squeeze(flux{3}(xlat, ylon, year, curTxxMonths(year))) - nanmean(flux{3}(xlat, ylon, year, warmMonths), 4)) ./ nanmean(flux{3}(xlat, ylon, year, warmMonths), 4);
            end
        end
    end
    
    save(['e:/data/projects/bowen/' var '-chg-data/' var '-warm-anom-historical-1981-2005-' models{model} '.mat'], 'regionalFluxHistoricalWarm');
    save(['e:/data/projects/bowen/' var '-chg-data/' var '-txx-warm-anom-historical-1981-2005-' models{model} '.mat'], 'regionalFluxHistoricalTxx');
    
    save(['e:/data/projects/bowen/' var '-chg-data/' var '-txx-anom-future-2061-2085-' models{model} '.mat'], 'regionalFluxFutureTxx');
    save(['e:/data/projects/bowen/' var '-chg-data/' var '-warm-anom-future-2061-2085-' models{model} '.mat'], 'regionalFluxFutureTxx');

end

