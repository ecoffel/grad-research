plotCorrBox = true;
plotCorrMap = false;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

tempCmip5 = {};
prCmip5 = {};
for model = 1:length(models)
    %load(['2017-nile-climate/output/temp-seasonal-cmip5-historical-1980-2004-' models{model} '.mat']);
    %load(['2017-nile-climate/output/pr-seasonal-cmip5-historical-1980-2004-' models{model} '.mat']);
    
    load(['2017-nile-climate/output/temp-seasonal-cmip5-rcp85-2056-2080-' models{model} '.mat']);
    load(['2017-nile-climate/output/pr-seasonal-cmip5-rcp85-2056-2080-' models{model} '.mat']);
    for s = 1:length(prSeasonal)
        prCmip5{s}(:, :, :, model) = prSeasonal{s};
        tempCmip5{s}(:, :, :, model) = tempSeasonal{s};
    end
end
       
load 2017-nile-climate/output/temp-seasonal-era-interim.mat;
load 2017-nile-climate/output/pr-seasonal-era-interim.mat;

tempEra = tempSeasonal;
prEra = prSeasonal;

load 2017-nile-climate/output/temp-seasonal-ncep-reanalysis.mat;
load 2017-nile-climate/output/pr-seasonal-ncep-reanalysis.mat;

tempNcep = tempSeasonal;
prNcep = prSeasonal;

load 2017-nile-climate/output/temp-seasonal-gldas.mat;
load 2017-nile-climate/output/pr-seasonal-gldas.mat;

tempGldas = tempSeasonal;
prGldas = prSeasonal;

load('lat-gldas');
load('lon-gldas');
latGldas = lat;
lonGldas = lon;

load 2017-nile-climate/output/pr-seasonal-chirps.mat;
prChirps = prSeasonal;

if ~exist('gpcp', 'var')
    fprintf('loading GPCP...\n');
    prGpcp = loadMonthlyData('E:\data\gpcp\output\precip\monthly\1979-2017', 'precip', 'startYear', 1981, 'endYear', 2016);
end

load lat;
load lon;

load lat-cpc;
load lon-cpc;

% find bounds of whole region and north/south subregions
regionBounds = [[2 32]; [25, 44]];
regionBoundsNorth = [[13 32]; [29, 34]];
regionBoundsSouth = [[2 13]; [25, 42]];

[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

latGpcp = prGpcp{1};
lonGpcp = prGpcp{2};
[latIndsGpcp, lonIndsGpcp] = latLonIndexRange({latGpcp,lonGpcp,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsNorthGpcp, lonIndsNorthGpcp] = latLonIndexRange({latGpcp,lonGpcp,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouthGpcp, lonIndsSouthGpcp] = latLonIndexRange({latGpcp,lonGpcp,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

[latIndsGldas, lonIndsGldas] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsNorthGldas, lonIndsNorthGldas] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouthGldas, lonIndsSouthGldas] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

[latIndsCpc, lonIndsCpc] = latLonIndexRange({latCpc,lonCpc,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsNorthCpc, lonIndsNorthCpc] = latLonIndexRange({latCpc,lonCpc,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouthCpc, lonIndsSouthCpc] = latLonIndexRange({latCpc,lonCpc,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndsNorthRelCpc = latIndsNorthCpc-latIndsCpc(1)+1;
latIndsSouthRelCpc = latIndsSouthCpc-latIndsCpc(1)+1;
lonIndsNorthRelCpc = lonIndsNorthCpc-lonIndsCpc(1)+1;
lonIndsSouthRelCpc = lonIndsSouthCpc-lonIndsCpc(1)+1;

load 2017-nile-climate\hottest-season-ncep.mat;
hottestNorth = mode(reshape(hottestSeason(latIndsNorth, lonIndsNorth), [numel(hottestSeason(latIndsNorth, lonIndsNorth)), 1]));
hottestSouth = mode(reshape(hottestSeason(latIndsSouth, lonIndsSouth), [numel(hottestSeason(latIndsSouth, lonIndsSouth)), 1]));

% find relative indicies of north/south
latIndsSouth = latIndsSouth-latInds(1)+1;
latIndsNorth = latIndsNorth-latInds(1)+1;
lonIndsSouth = lonIndsSouth-lonInds(1)+1;
lonIndsNorth = lonIndsNorth-lonInds(1)+1;

latIndsSouthGldas = latIndsSouthGldas-latInds(1)+1;
latIndsNorthGldas = latIndsNorthGldas-latInds(1)+1;
lonIndsSouthGldas = lonIndsSouthGldas-lonInds(1)+1;
lonIndsNorthGldas = lonIndsNorthGldas-lonInds(1)+1;

if ~exist('cpc', 'var')   
    tempCpc = [];
    for year = 1981:2016
        fprintf('cpc year %d...\n', year);
        load(['C:\git-ecoffel\grad-research\2017-nile-climate\output\temp-monthly-cpc-' num2str(year) '.mat']);
        cpcTemp{3} = cpcTemp{3};
%         cpcRegrid = [];
%         for m = 1:12
%              tmpcpc = regridGriddata({latCpc(latIndsCpc,lonIndsCpc), lonCpc(latIndsCpc,lonIndsCpc), cpcTemp{3}(:,:,m)}, ...
%                                               {latGpcp(latIndsGpcp, lonIndsGpcp), lonGpcp(latIndsGpcp, lonIndsGpcp), []}, false);
%              cpcRegrid(:,:,m) = tmpcpc{3};
%         end

        if length(tempCpc) == 0
            tempCpc = cpcTemp{3};
        else
            tempCpc = cat(4, tempCpc, cpcTemp{3});
        end

        clear cpcTemp;
    end
    tempCpc = permute(tempCpc, [1 2 4 3]);
end


seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

tempPrCorrNcep = [];
tempPrCorrEra = [];
tempPrCorrGldas = [];
tempPrCorrCpc = [];
tempPrCorrCmip5 = [];

tempPrSouthCorrNcep = [];
tempPrNorthCorrNcep = [];
tempPrSouthCorrEra = [];
tempPrNorthCorrEra = [];
tempPrSouthCorrGldas = [];
tempPrNorthCorrGldas = [];
tempPrSouthCorrCpc = [];
tempPrNorthCorrCpc = [];
tempPrNorthCorrCmip5 = [];
tempPrSouthCorrCmip5 = [];
for s = 1:size(seasons, 1)
    
    % process GLDAS (on a different grid so needs its own xlat/ylon loop)
    for xlat = 1:size(tempGldas{s}, 1)
        for ylon = 1:size(tempGldas{s}, 2)
            % for GLDAS
            temp = squeeze(tempGldas{s}(xlat, ylon, :));
            pr = squeeze(prGldas{s}(xlat, ylon, :));
            nn = find(~isnan(temp) & ~isnan(pr));
            if length(nn) > .5*length(temp)
                tempPrCorrGldas(xlat, ylon, s) = corr(temp(nn), pr(nn));
            else
                tempPrCorrGldas(xlat, ylon, s) = NaN;
            end
        end
    end
    
    % calculate grid-box specific corr over region
    for xlat = 1:size(tempEra{1}, 1)
        for ylon = 1:size(tempEra{1}, 2)
            
            % get seasonal temp time series
            temp = squeeze(tempNcep{s}(xlat, ylon, :));
            % and precip
            pr = squeeze(prNcep{s}(xlat, ylon, :));
            % remove nans
            nn = find(~isnan(temp) & ~isnan(pr));
            % and compute correlation
            tempPrCorrNcep(xlat, ylon, s) = corr(temp(nn), pr(nn));
            
            % for ERA
            temp = squeeze(tempEra{s}(xlat, ylon, :));
            pr = squeeze(prEra{s}(xlat, ylon, :));
            nn = find(~isnan(temp) & ~isnan(pr));
            tempPrCorrEra(xlat, ylon, s) = corr(temp(nn), pr(nn));
            
            % loop over all models and do the same
            for model = 1:length(models)
                temp = squeeze(tempCmip5{s}(xlat, ylon, :, model));
                pr = squeeze(prCmip5{s}(xlat, ylon, :, model));
                nn = find(~isnan(temp) & ~isnan(pr));
                tempPrCorrCmip5(xlat, ylon, s, model) = corr(temp(nn), pr(nn));
            end
        end
    end
    
    % calculate mean correlation for north/south regions
    % NCEP
    tempSouth = squeeze(nanmean(nanmean(tempNcep{s}(latIndsSouth, lonIndsSouth, :), 2), 1));
    prSouth = squeeze(nanmean(nanmean(prNcep{s}(latIndsSouth, lonIndsSouth, :), 2), 1));
    tempPrSouthCorrNcep(s) = corr(detrend(tempSouth), detrend(prSouth));

    tempNorth = squeeze(nanmean(nanmean(tempNcep{s}(latIndsNorth, lonIndsNorth, :), 2), 1));
    prNorth = squeeze(nanmean(nanmean(prNcep{s}(latIndsNorth, lonIndsNorth, :), 2), 1));
    tempPrNorthCorrNcep(s) = corr(detrend(tempNorth), detrend(prNorth));

    % ERA
    tempSouthEra = squeeze(nanmean(nanmean(tempEra{s}(latIndsSouth, lonIndsSouth, :), 2), 1));
    prSouth = squeeze(nanmean(nanmean(prEra{s}(latIndsSouth, lonIndsSouth, :), 2), 1));
    tempPrSouthCorrEra(s) = corr(detrend(tempSouthEra), detrend(prSouth));

    tempNorthEra = squeeze(nanmean(nanmean(tempEra{s}(latIndsNorth, lonIndsNorth, :), 2), 1));
    prNorth = squeeze(nanmean(nanmean(prEra{s}(latIndsNorth, lonIndsNorth, :), 2), 1));
    tempPrNorthCorrEra(s) = corr(detrend(tempNorthEra), detrend(prNorth));
    
    % GLDAS
    tempSouth = squeeze(nanmean(nanmean(tempGldas{s}(latIndsSouthGldas, lonIndsSouthGldas, :), 2), 1));
    prSouth = squeeze(nanmean(nanmean(prGldas{s}(latIndsSouthGldas, lonIndsSouthGldas, :), 2), 1));
    tempPrSouthCorrGldas(s) = corr(detrend(tempSouth), detrend(prSouth));

    tempNorth = squeeze(nanmean(nanmean(tempGldas{s}(latIndsNorthGldas, lonIndsNorthGldas, :), 2), 1));
    prNorth = squeeze(nanmean(nanmean(prGldas{s}(latIndsNorthGldas, lonIndsNorthGldas, :), 2), 1));
    tempPrNorthCorrGldas(s) = corr(detrend(tempNorth), detrend(prNorth));
    
    % CPC - GPCP
    prSouth = squeeze(nanmean(nanmean(nanmean(prGpcp{3}(latIndsSouthGpcp, lonIndsSouthGpcp, :, seasons(s,:)), 4), 2), 1));
    tempSouth = squeeze(nanmean(nanmean(nanmean(tempCpc(latIndsSouthRelCpc, lonIndsSouthRelCpc, :, seasons(s,:)), 4), 2), 1));
    tempPrSouthCorrCpc(s) = corr(detrend(tempSouth), detrend(prSouth));

    prNorth = squeeze(nanmean(nanmean(nanmean(prGpcp{3}(latIndsNorthGpcp, lonIndsNorthGpcp, :, seasons(s,:)), 4), 2), 1));
    tempNorth = squeeze(nanmean(nanmean(nanmean(tempCpc(latIndsNorthRelCpc, lonIndsNorthRelCpc, :, seasons(s,:)), 4), 2), 1));
    tempPrNorthCorrCpc(s) = corr(detrend(tempNorth), detrend(prNorth));
    
    % and for models
    for model = 1:length(models)
        tempSouth = squeeze(nanmean(nanmean(tempCmip5{s}(latIndsSouth, lonIndsSouth, :, model), 2), 1));
        prSouth = squeeze(nanmean(nanmean(prCmip5{s}(latIndsSouth, lonIndsSouth, :, model), 2), 1));
        tempPrSouthCorrCmip5(s, model) = corr(detrend(tempSouth), detrend(prSouth));

        tempNorth = squeeze(nanmean(nanmean(tempCmip5{s}(latIndsNorth, lonIndsNorth, :, model), 2), 1));
        prNorth = squeeze(nanmean(nanmean(prCmip5{s}(latIndsNorth, lonIndsNorth, :, model), 2), 1));
        tempPrNorthCorrCmip5(s, model) = corr(detrend(tempNorth), detrend(prNorth));
    end

end

if plotCorrMap
    [regionInds, regions, regionNames] = ni_getRegions();
    curInds = regionInds('nile');
    latInds = curInds{1};
    lonInds = curInds{2};
    
    seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};
    
    for s = 1:4
        result = {lat(latInds,lonInds), lon(latInds,lonInds), nanmedian(tempPrCorrCmip5(:,:,s,:), 4)}; 

        saveData = struct('data', {result}, ...
                          'plotRegion', 'nile', ...
                          'plotRange', [-1 1], ...
                          'cbXTicks', -1:.5:1, ...
                          'plotTitle', [''], ...
                          'fileTitle', ['temp-pr-corr-cmip5-rcp85-' seasonNames{s} '.eps'], ...
                          'plotXUnits', ['Correlation'], ...
                          'blockWater', true, ...
                          'colormap', brewermap([], 'RdBu'), ...
                          'plotCountries', true, ...
                          'boxCoords', {[[13 32], [29, 34];
                                         [2 13], [25 42]]});
        plotFromDataFile(saveData);
    end
end

if plotCorrBox
    figure('Color', [1,1,1]);
    colors = get(gca, 'colororder');
    hold on;
    axis square;
    box on;
    grid on;
    
    b = boxplot(tempPrNorthCorrCmip5');
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
    
    plot(tempPrNorthCorrNcep, 'o', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    plot(tempPrNorthCorrEra, 'x', 'Color', 'k','MarkerSize', 30, 'LineWidth', 2);
    plot(tempPrNorthCorrGldas, 'd', 'Color', 'k','MarkerSize', 30, 'LineWidth', 2);
    plot(tempPrNorthCorrCpc, 's', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    %plot(tempPrNorthCorrChirpsEra, 's', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    plot([0 5], [0 0], 'k--');
    set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});

    % set hottest season xtick label red
    ax = gca;
    ax.TickLabelInterpreter = 'tex';
    ax.XTickLabels{hottestNorth} = ['\color{red} ' ax.XTickLabels{hottestNorth}];

    leg = legend(' NCEP II', ' ERA-Interim', ' GLDAS', ' CPC-GPCP');
    set(leg, 'location', 'northwest');
    ylim([-1 1]);
    xlim([.5 4.5]);
    ylabel('Correlation');
    set(gca, 'FontSize', 40);
    %title('North');
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig pr-temp-corr-north.eps;
    close all;

    figure('Color',[1,1,1]);
    hold on;
    axis square;
    box on;
    grid on;
    b = boxplot(tempPrSouthCorrCmip5');
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 

    plot(tempPrSouthCorrNcep, 'o', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    plot(tempPrSouthCorrEra, 'x', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    plot(tempPrSouthCorrGldas, 'd', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    plot(tempPrSouthCorrCpc, 's', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    plot([0 5], [0 0], 'k--');
    set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});

    % set hottest season xtick label red
    ax = gca;
    ax.TickLabelInterpreter = 'tex';
    ax.XTickLabels{hottestSouth} = ['\color{red} ' ax.XTickLabels{hottestSouth}];

    leg = legend(' NCEP II', ' ERA-Interim', ' GLDAS', ' CPC-GPCP');
    set(leg, 'location', 'northwest');
    ylim([-1 1]);
    xlim([.5 4.5]);
    ylabel('Correlation');
    set(gca, 'FontSize', 40);
    %title('South');
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig pr-temp-corr-south.eps;
    close all;
end


% plot PR/heat time series in the hottest season for each region from ERA
tempSouth = squeeze(nansum(nansum(nansum(heatProbEra(latIndsSouth, lonIndsSouth, :, seasons(hottestSouth,:)), 4), 2), 1));
prSouth = squeeze(nanmean(nanmean(tempEra{hottestSouth}(latIndsSouth, lonIndsSouth, :), 2), 1));
fPrSouth = fit((1:length(prSouth))', prSouth, 'poly1');
fHeatSouth = fit((1:length(tempSouth))', tempSouth, 'poly1');

tempNorth = squeeze(nansum(nansum(nansum(heatProbEra(latIndsNorth, lonIndsNorth, :, seasons(hottestNorth,:)), 4), 2), 1));
prNorth = squeeze(nanmean(nanmean(tempEra{hottestNorth}(latIndsNorth, lonIndsNorth, :), 2), 1));
fPrNorth = fit((1:length(prNorth))', prNorth, 'poly1');
fHeatNorth = fit((1:length(tempNorth))', tempNorth, 'poly1');

f = figure('Color', [1,1,1]);

set(gcf, 'defaultAxesColorOrder', [[0.8500 0.3250 0.0980];
                                   [0 0.4470 0.7410]]);

hold on;
box on;
grid on;
axis square;
yyaxis left;
plot(tempNorth, 'LineWidth', 2);
if Mann_Kendall(tempNorth, 0.05)
    plot(1:length(tempNorth), fHeatNorth(1:length(tempNorth)), '--');
end
ylim([0 150]);
ylabel('# heat waves');

yyaxis right;
plot(prNorth, 'LineWidth', 2);
if Mann_Kendall(prNorth, 0.05)
    plot(1:length(prNorth), fPrNorth(1:length(prNorth)), '--');
end
ylim([0 5]);
ylabel('Precipitation (mm/day)');

set(gca, 'FontSize', 40);
set(gca, 'XTick', 5:10:length(tempSouth), 'XTickLabels', 1985:10:2016);
title('North: JJA');

export_fig temp-pr-timeseries-north.eps;

figure('Color', [1,1,1]);
set(gcf, 'defaultAxesColorOrder', [[0.8500 0.3250 0.0980];
                                   [0 0.4470 0.7410]]);
                    
hold on;
box on;
grid on;
axis square;

yyaxis left;
plot(tempSouth, 'LineWidth', 2);
if Mann_Kendall(tempSouth, 0.05)
    plot(1:length(tempSouth), fHeatSouth(1:length(tempSouth)), '--');
end
ylim([0 150]);
ylabel('# heat waves');

yyaxis right;
plot(prSouth, 'LineWidth', 2);
if Mann_Kendall(prSouth, 0.05)
    plot(1:length(prSouth), fPrSouth(1:length(prSouth)), '--');
end
ylim([0 5]);
ylabel('Precipitation (mm/day)');

set(gca, 'FontSize', 40);
set(gca, 'XTick', 5:10:length(tempSouth), 'XTickLabels', 1985:10:2016);
title('South: MAM');

export_fig temp-pr-timeseries-south.eps;

