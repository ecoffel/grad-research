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
for model = 1:length(models)
    load(['2017-nile-climate/output/temp-seasonal-cmip5-historical-1980-2004-' models{model} '.mat']);
    for s = 1:length(tempSeasonal)
        tempCmip5{s}(:, :, :, model) = tempSeasonal{s};
    end
end

if ~exist('era', 'var')
    fprintf('loading ERA...\n');
    era = loadDailyData('E:\data\era-interim\output\mx2t\regrid\world', 'startYear', 1980, 'endYear', 2016);
    era{3} = era{3} - 273.15;
    era = dailyToMonthly(era);
end

if ~exist('ncep', 'var')
    fprintf('loading NCEP...\n');
    ncep = loadDailyData('E:\data\ncep-reanalysis\output\tmax\regrid\world', 'startYear', 1980, 'endYear', 2016);
    ncep{3} = ncep{3} - 273.15;
    ncep = dailyToMonthly(ncep);
end

if ~exist('gldas', 'var')
    fprintf('loading GLDAS...\n');
    gldas = loadMonthlyData('E:\data\gldas-noah-v2\output\Tair_f_inst', 'Tair_f_inst', 'startYear', 1980, 'endYear', 2010);
    gldas{3} = gldas{3} - 273.15;
end

if ~exist('cpc', 'var')
    load lat-cpc;
    load lon-cpc;
    cpc = [];
    for year = 1981:2016
        fprintf('cpc year %d...\n', year);
        load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\temp-monthly-cpc-' num2str(year) '.mat']);
        cpcTemp{3} = cpcTemp{3};

        if length(cpc) == 0
            cpc = cpcTemp{3};
        else
            cpc = cat(4, cpc, cpcTemp{3});
        end

        clear cpcTemp;
    end
    % avg over years
    cpc = nanmean(cpc, 4);
end

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

latGldas = gldas{1};
lonGldas = gldas{2};
[latIndsNorthGldas, lonIndsNorthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouthGldas, lonIndsSouthGldas] = latLonIndexRange({latGldas,lonGldas,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

[latIndsCpc, lonIndsCpc] = latLonIndexRange({latCpc,lonCpc,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsNorthCpc, lonIndsNorthCpc] = latLonIndexRange({latCpc,lonCpc,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouthCpc, lonIndsSouthCpc] = latLonIndexRange({latCpc,lonCpc,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndsNorthRelCpc = latIndsNorthCpc-latIndsCpc(1)+1;
latIndsSouthRelCpc = latIndsSouthCpc-latIndsCpc(1)+1;
lonIndsNorthRelCpc = lonIndsNorthCpc-lonIndsCpc(1)+1;
lonIndsSouthRelCpc = lonIndsSouthCpc-lonIndsCpc(1)+1;


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
    curLatIndsGldas = latIndsNorthGldas;
    curLonIndsGldas = lonIndsNorthGldas;

    curLatIndsCpc = latIndsNorthRelCpc;
    curLonIndsCpc = lonIndsNorthRelCpc;

    curLatInds = latIndsNorth;
    curLonInds = lonIndsNorth;

    curLatIndsRel = latIndsNorthRel;
    curLonIndsRel = lonIndsNorthRel;
else
    curLatIndsGldas = latIndsSouthGldas;
    curLonIndsGldas = lonIndsSouthGldas;

    curLatIndsCpc = latIndsSouthRelCpc;
    curLonIndsCpc = lonIndsSouthRelCpc;

    curLatInds = latIndsSouth;
    curLonInds = lonIndsSouth;

    curLatIndsRel = latIndsSouthRel;
    curLonIndsRel = lonIndsSouthRel;
end

for season = 1:size(seasons, 1)
    
    
    regionalTEra = squeeze(nanmean(nanmean(nanmean(nanmean(era{3}(curLatInds, curLonInds, :, seasons(season, :)), 4), 3), 2), 1));
    regionalTNcep = squeeze(nanmean(nanmean(nanmean(nanmean(ncep{3}(curLatInds, curLonInds, :, seasons(season, :)), 4), 3), 2), 1));
    regionalTGldas = squeeze(nanmean(nanmean(nanmean(nanmean(gldas{3}(curLatIndsGldas, curLonIndsGldas, :, seasons(season, :)), 4), 3), 2), 1));
    regionalTCpc = squeeze(nanmean(nanmean(nanmean(cpc(curLatIndsCpc, curLonIndsCpc, seasons(season, :)), 3), 2), 1));

    regionalTCMIP5 = squeeze(nanmean(nanmean(nanmean(tempCmip5{season}(curLatIndsRel, curLonIndsRel, :, :), 3), 2), 1));
    
    b = boxplot(regionalTCMIP5, 'positions', [season]);
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
    
    p1 = plot(season, regionalTNcep, 'o', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    p2 = plot(season, regionalTEra, 'x', 'Color', 'k','MarkerSize', 30, 'LineWidth', 2);
    p3 = plot(season, regionalTGldas, 'd', 'Color', 'k','MarkerSize', 30, 'LineWidth', 2);
    p4 = plot(season, regionalTCpc, '+', 'Color', 'k','MarkerSize', 30, 'LineWidth', 2);
    
end
leg = legend([p1, p2, p3, p4], ' NCEP II', ' ERA-Interim', ' GLDAS', ' CPC');
xlim([0 5]);
ylim([15 45]);
set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});
ylabel([char(176) 'C']);
set(gca, 'FontSize', 40);
set(gcf, 'Position', get(0,'Screensize'));



