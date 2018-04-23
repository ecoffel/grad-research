regionBounds = [[2 32]; [25, 44]];
regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

north = false;
          
tempCmip5 = {};
prCmip5 = {};
for model = 1:length(models)
    load(['2017-nile-climate/output/temp-seasonal-cmip5-historical-1980-2004-' models{model} '.mat']);
    load(['2017-nile-climate/output/pr-seasonal-cmip5-historical-1980-2004-' models{model} '.mat']);
    for s = 1:length(prSeasonal)
        prCmip5{s}(:, :, :, model) = prSeasonal{s};
        tempCmip5{s}(:, :, :, model) = tempSeasonal{s};
    end
end

if ~exist('gpcp', 'var')
    fprintf('loading GPCP...\n');
    gpcp = loadMonthlyData('E:\data\gpcp\output\precip\monthly\1979-2017', 'precip', 'startYear', 1981, 'endYear', 2016);
end

if ~exist('era', 'var')
    fprintf('loading ERA...\n');
    era = loadDailyData('E:\data\era-interim\output\tp\regrid\world', 'startYear', 1981, 'endYear', 2016);
    era{3} = era{3} .* 1000;
    era = dailyToMonthly(era);
end

if ~exist('ncep', 'var')
    fprintf('loading NCEP...\n');
    ncep = loadDailyData('E:\data\ncep-reanalysis\output\prate\regrid\world', 'startYear', 1981, 'endYear', 2016);
    ncep{3} = ncep{3} .* 3600 .* 24;
    ncep = dailyToMonthly(ncep);
end

if ~exist('gldas', 'var')
    fprintf('loading GLDAS...\n');
    gldas = loadMonthlyData('E:\data\gldas-noah-v2\output\Rainf_f_tavg', 'Rainf_f_tavg', 'startYear', 1981, 'endYear', 2010);
    gldas{3} = gldas{3} .* 3600 .* 24;
end

if ~exist('chirps', 'var')
    fprintf('loading CHIRPS...\n');
    chirps = [];
    
    % load pre-processed chirps with nile region selected
    for year = 1981:1:2016
        fprintf('chirps year %d...\n', year);
        load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\pr-monthly-chirps-' num2str(year) '.mat']);
        chirpsPr{3} = chirpsPr{3};
        
        if length(chirps) == 0
            chirps = chirpsPr{3};
        else
            chirps = cat(4, chirps, chirpsPr{3});
        end
        
        clear chirpsPr;
    end
    % flip to (x, y, year, month)
    chirps = permute(chirps, [1 2 4 3]);
    % add initial year to align time series
%     chirps = padarray(chirps,[0 0 1 0],'pre');
%     % remove zeros
%     chirps(chirps == 0) = NaN;
end


latGpcp = gpcp{1};
lonGpcp = gpcp{2};
[latIndsNorthGpcp, lonIndsNorthGpcp] = latLonIndexRange({latGpcp,lonGpcp,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouthGpcp, lonIndsSouthGpcp] = latLonIndexRange({latGpcp,lonGpcp,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

latGldas = gldas{1};
lonGldas = gldas{2};
[latIndsNorthGldas, lonIndsNorthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouthGldas, lonIndsSouthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

% load global chirps lat/lon grids
load lat-chirps;
load lon-chirps;

[latIndChirps, lonIndChirps] = latLonIndexRange({latChirps, lonChirps, []}, regionBounds(1,:), regionBounds(2,:));
[latIndChirpsNorth, lonIndChirpsNorth] = latLonIndexRange({latChirps, lonChirps, []}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndChirpsSouth, lonIndChirpsSouth] = latLonIndexRange({latChirps, lonChirps, []}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndChirpsNorth = latIndChirpsNorth - latIndChirps(1) + 1;
lonIndChirpsNorth = lonIndChirpsNorth - lonIndChirps(1) + 1;
latIndChirpsSouth = latIndChirpsSouth - latIndChirps(1) + 1;
lonIndChirpsSouth = lonIndChirpsSouth - lonIndChirps(1) + 1;

lat = ncep{1};
lon = ncep{2};
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndsNorthRel = latIndsNorth-latInds(1)+1;
latIndsSouthRel = latIndsSouth-latInds(1)+1;
lonIndsNorthRel = lonIndsNorth-lonInds(1)+1;
lonIndsSouthRel = lonIndsSouth-lonInds(1)+1;


seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

figure('Color', [1,1,1]);
hold on;
axis square;
box on;
grid on;
    
if north
    curLatIndsGpcp = latIndsNorthGpcp;
    curLonIndsGpcp = lonIndsNorthGpcp;

    curLatIndsGldas = latIndsNorthGldas;
    curLonIndsGldas = lonIndsNorthGldas;

    curLatIndsChirps = latIndChirpsNorth;
    curLonIndsChirps = lonIndChirpsNorth;

    curLatInds = latIndsNorth;
    curLonInds = lonIndsNorth;
else
    curLatIndsGpcp = latIndsSouthGpcp;
    curLonIndsGpcp = lonIndsSouthGpcp;

    curLatIndsGldas = latIndsSouthGldas;
    curLonIndsGldas = lonIndsSouthGldas;

    curLatIndsChirps = latIndChirpsSouth;
    curLonIndsChirps = lonIndChirpsSouth;

    curLatInds = latIndsSouth;
    curLonInds = lonIndsSouth;
end

for season = 1:size(seasons, 1)
    
    regionalPGpcp = squeeze(nanmean(nanmean(nanmean(nanmean(gpcp{3}(curLatIndsGpcp, curLonIndsGpcp, :, seasons(season, :)), 4), 3), 2), 1));
    regionalPEra = squeeze(nanmean(nanmean(nanmean(nanmean(era{3}(curLatInds, curLonInds, :, seasons(season, :)), 4), 3), 2), 1));
    regionalPNcep = squeeze(nanmean(nanmean(nanmean(nanmean(ncep{3}(curLatInds, curLonInds, :, seasons(season, :)), 4), 3), 2), 1));
    regionalPGldas = squeeze(nanmean(nanmean(nanmean(nanmean(gldas{3}(curLatIndsGldas, curLonIndsGldas, :, seasons(season, :)), 4), 3), 2), 1));
    regionalPChirps = squeeze(nanmean(nanmean(nanmean(nanmean(chirps(curLatIndsChirps, curLonIndsChirps, :, seasons(season, :)), 4), 3), 2), 1));
    
    regionalPCMIP5 = squeeze(nanmean(nanmean(nanmean(prCmip5{season}(latIndsSouthRel, lonIndsSouthRel, :, :), 3), 2), 1));
    
    b = boxplot(regionalPCMIP5, 'positions', [season]);
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
    
    p1 = plot(season, regionalPNcep, 'o', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    p2 = plot(season, regionalPEra, 'x', 'Color', 'k','MarkerSize', 30, 'LineWidth', 2);
    p3 = plot(season, regionalPGldas, 'd', 'Color', 'k','MarkerSize', 30, 'LineWidth', 2);
    p4 = plot(season, regionalPChirps, 's', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    p5 = plot(season, regionalPGpcp, '*', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    
end
leg = legend([p1, p2, p3, p4, p5], ' NCEP II', ' ERA-Interim', ' GLDAS', ' CHIRPS-v2', ' GPCP');
xlim([0 5]);
if north
    ylim([0 2]);
else
    ylim([0 10]);
end
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});
ylabel('mm/day');
set(gca, 'FontSize', 40);
set(gcf, 'Position', get(0,'Screensize'));



