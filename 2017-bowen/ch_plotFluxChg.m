
baseDir = 'e:/data';
var = 'pr';                  
warmSeason = false;
useTxxMonths = false;
warmSeasonAnom = false;

% models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
%               'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
%               'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
%               'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
%               'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

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

region =  1;


regionNames = {'World', ...
                'Eastern U.S.', ...
                'Southeast U.S.', ...
                'Central Europe', ...
                'Mediterranean', ...
                'Northern SA', ...
                'Amazon', ...
                'Central Africa', ...
                'North Africa', ...
                'China'};
regionAb = {'world', ...
            'us-east', ...
            'us-se', ...
            'europe', ...
            'med', ...
            'sa-n', ...
            'amazon', ...
            'africa-cent', ...
            'n-africa', ...
            'china'};
            
regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[35 50], [-10+360 45]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 7], [-75, -62]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]; ...              % north africa
           [[22 40], [105 122]]];               % china
       
regionLatLonInd = {};

% loop over all regions to find lat/lon indicies
for i = 1:size(regions, 1)
    [latIndexRange, lonIndexRange] = latLonIndexRange({lat, lon, []}, regions(i, 1:2), regions(i, 3:4));
    regionLatLonInd{i} = {latIndexRange, lonIndexRange};
end

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];

% load hottest seasons for each grid cell
load('2017-bowen/hottest-season-txx-rel-cmip5-all-txx.mat');
load('2017-bowen/txx-months-historical-cmip5-1981-2005.mat');

curLat = regionLatLonInd{region}{1};
curLon = regionLatLonInd{region}{2};

% historical and future monthly precip, mm/day
% dims: (x, y, model)
regionalFluxHistorical = zeros(length(curLat), length(curLon), length(models), 12);
regionalFluxHistorical(regionalFluxHistorical == 0) = NaN;
regionalFluxFuture = zeros(length(curLat), length(curLon), length(models), 12);
regionalFluxFuture(regionalFluxFuture == 0) = NaN;

for model = 1:length(models)
    fprintf('loading %s historical...\n', models{model});
    flux = loadMonthlyData([baseDir '/cmip5/output/' models{model} '/mon/r1i1p1/historical/' var '/regrid/world'], var, 'startYear', 1981, 'endYear', 2005);
    flux{3} = squeeze(nanmean(flux{3}, 3));

    % remove water tiles
    for month = 1:size(flux{3}, 4)
        curGrid = flux{3}(:, :, month);
        curGrid(waterGrid) = NaN;
        flux{3}(:, :, month) = curGrid;
    end

    % loop over all grid cells and select hottest season flux
    for xlat = 1:length(curLat)
        for ylon = 1:length(curLon)
            if waterGrid(curLat(xlat), curLon(ylon))
                continue;
            end

            regionalFluxHistorical(curLat(xlat), curLon(ylon), model, :) = flux{3}(curLat(xlat), curLon(ylon), :);
        end
    end

    clear flux;

    fprintf('loading %s future...\n', models{model});
    flux = loadMonthlyData([baseDir '/cmip5/output/' models{model} '/mon/r1i1p1/rcp85/' var '/regrid/world'], var, 'startYear', 2060, 'endYear', 2079);
    flux{3} = squeeze(nanmean(flux{3}, 3));

    % remove water tiles
    for month = 1:size(flux{3}, 4)
        curGrid = flux{3}(:, :, month);
        curGrid(waterGrid) = NaN;
        flux{3}(:, :, month) = curGrid;
    end

    % loop over all grid cells and select hottest season flux
    for xlat = 1:length(curLat)
        for ylon = 1:length(curLon)
            if waterGrid(curLat(xlat), curLon(ylon))
                continue;
            end

                regionalFluxFuture(curLat(xlat), curLon(ylon), model, :) = flux{3}(curLat(xlat), curLon(ylon), :);

        end
    end
end

% calculate soil change for each model
chgAbs = [];
chgPer = [];


for model = 1:size(regionalFluxHistorical, 3)
    tmpHistorical = regionalFluxHistorical;
    tmpFuture = regionalFluxFuture;

    % change in all seasons
    chgPer(:, :, model, :) = squeeze((tmpFuture(:,:,model,:)-tmpHistorical(:,:,model,:)) ./ tmpHistorical(:,:,model,:));
    % in w/m2
    chgAbs(:, :, model, :) = squeeze(tmpFuture(:,:,model,:)-tmpHistorical(:,:,model,:));

end

plotChg = zeros(size(lat,1), size(lat,2), size(chgAbs, 3));
plotChg(plotChg == 0) = NaN;

% find statistical significance of change over selected months across models
sigChg = zeros(size(lat,1), size(lat, 2));
for xlat = 1:size(chgAbs, 1)
    for ylon = 1:size(chgAbs, 2)

        months = 1:12;

        if warmSeason 
            months = [squeeze(hottestSeason(xlat, ylon, :)-1) squeeze(hottestSeason(xlat, ylon, :)) squeeze(hottestSeason(xlat, ylon, :)+1)];
            months(months == 0) = 12;
            months(months == 13) = 1;

            months(isnan(months(:,1)),1) = mode(months(:,1));
            months(isnan(months(:,2)),2) = mode(months(:,2));
            months(isnan(months(:,3)),3) = mode(months(:,3));
        elseif useTxxMonths
            months = squeeze(txxMonths(xlat, ylon, :, :));
        end

        % select only non-nan items
        curChg = squeeze(nanmean(chgAbs(xlat, ylon, :, months), 4));
        ind = find(~isnan(curChg) & ~isinf(curChg));
        curChg = curChg(ind);

        % at least 10 non-nan models
        if length(curChg) == length(models)
            med = nanmedian(curChg);
            plotChg(xlat, ylon, :) = curChg;

            % where < 75% models agree on sign
            sigChg(xlat, ylon) = length(find(sign(curChg) == sign(med))) < round(.75*length(models));
        end
    end
end

plotChg(isinf(plotChg)) = NaN;
% median over models
chgPer = chgPer .* 100;
plotChg = plotChg .* 100;

eval([var 'Chg = chgPer;']);
save(['e:/data/projects/bowen/derived-chg/' var 'Chg-all-txx.mat'], [var 'Chg']);
eval([var 'Chg = chgAbs;']);
save(['e:/data/projects/bowen/derived-chg/' var 'Chg-absolute-all-txx.mat'], [var 'Chg']);
