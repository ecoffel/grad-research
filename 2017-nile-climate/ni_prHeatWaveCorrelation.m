plotCorr = false;
plotHeatWaves = true;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

heatProbCmip5 = [];
prCmip5 = {};
for model = 1:length(models)
    load(['2017-nile-climate/output/nile-heat-waves-90-5day-' models{model} '-annual.mat']);
    heatProbCmip5(:, :, :, :, model) = heatProb;
    
    load(['2017-nile-climate/output/pr-cmip5-historical-' models{model} '.mat']);
    for s = 1:length(prSeasonal)
        prCmip5{s}(:, :, :, model) = prSeasonal{s};
    end
end
       
load 2017-nile-climate/output/nile-heat-waves-90-5day-era-annual.mat;
load 2017-nile-climate/output/pr-era-interim.mat;

prEra = pr;

load 2017-nile-climate/output/nile-heat-waves-90-5day-ncep-annual.mat;
load 2017-nile-climate/output/pr-ncep-reanalysis.mat;

prNcep = pr;

load lat;
load lon;

%find bounds of whole region and north/south subregions
regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsNorth = [[13 32]; [29, 34]];
[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

load 2017-nile-climate\hottest-season-ncep.mat;
hottestNorth = mode(reshape(hottestSeason(latIndsNorth, lonIndsNorth), [numel(hottestSeason(latIndsNorth, lonIndsNorth)), 1]));
hottestSouth = mode(reshape(hottestSeason(latIndsSouth, lonIndsSouth), [numel(hottestSeason(latIndsSouth, lonIndsSouth)), 1]));

%find relative indicies of north/south
latIndsSouth = latIndsSouth-latInds(1)+1;
latIndsNorth = latIndsNorth-latInds(1)+1;
lonIndsSouth = lonIndsSouth-lonInds(1)+1;
lonIndsNorth = lonIndsNorth-lonInds(1)+1;

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

heatCorrNcep = [];
heatCorrEra = [];
heatCorrCmip5 = [];

heatSouthCorrNcep = [];
heatNorthCorrNcep = [];
heatSouthCorrEra = [];
heatNorthCorrEra = [];
heatNorthCorrCmip5 = [];
heatSouthCorrCmip5 = [];
for s = 1:size(seasons, 1)
    
    %calculate grid-box specific corr over region
    for xlat = 1:size(prEra{1}, 1)
        for ylon = 1:size(prEra{1}, 2)
            
            %get heat time series
            heat = squeeze(nansum(heatProbNcep(xlat, ylon, :, seasons(s,:)), 4));
            %and precip
            pr = squeeze(prNcep{s}(xlat, ylon, :));
            %remove nans
            nn = find(~isnan(heat) & ~isnan(pr));
            %and compute correlation
            heatCorrNcep(xlat, ylon, s) = corr(heat(nn), pr(nn));
            
            heat = squeeze(nansum(heatProbEra(xlat, ylon, :, seasons(s,:)), 4));
            pr = squeeze(prEra{s}(xlat, ylon, :));
            nn = find(~isnan(heat) & ~isnan(pr));
            heatCorrEra(xlat, ylon, s) = corr(heat(nn), pr(nn));
            
            %loop over all models and do the same
            for model = 1:length(models)
                heat = squeeze(nansum(heatProbCmip5(xlat, ylon, :, seasons(s,:), model), 4));
                pr = squeeze(prCmip5{s}(xlat, ylon, :, model));
                nn = find(~isnan(heat) & ~isnan(pr));
                heatCorrCmip5(xlat, ylon, s, model) = corr(heat(nn), pr(nn));
            end
        end
    end
    
%     calculate mean correlation for north/south regions
%     NCEP
    heatSouthEra = squeeze(nansum(nansum(nansum(heatProbNcep(latIndsSouth, lonIndsSouth, :, seasons(s,:)), 4), 2), 1));
    prSouth = squeeze(nanmean(nanmean(prNcep{s}(latIndsSouth, lonIndsSouth, :), 2), 1));
    heatSouthCorrNcep(s) = corr(detrend(heatSouthEra), detrend(prSouth));

    heatNorthEra = squeeze(nansum(nansum(nansum(heatProbNcep(latIndsNorth, lonIndsNorth, :, seasons(s,:)), 4), 2), 1));
    prNorth = squeeze(nanmean(nanmean(prNcep{s}(latIndsNorth, lonIndsNorth, :), 2), 1));
    heatNorthCorrNcep(s) = corr(detrend(heatNorthEra), detrend(prNorth));

%     ERA
    heatSouthEra = squeeze(nansum(nansum(nansum(heatProbEra(latIndsSouth, lonIndsSouth, :, seasons(s,:)), 4), 2), 1));
    prSouth = squeeze(nanmean(nanmean(prEra{s}(latIndsSouth, lonIndsSouth, :), 2), 1));
    heatSouthCorrEra(s) = corr(detrend(heatSouthEra), detrend(prSouth));

    heatNorthEra = squeeze(nansum(nansum(nansum(heatProbEra(latIndsNorth, lonIndsNorth, :, seasons(s,:)), 4), 2), 1));
    prNorth = squeeze(nanmean(nanmean(prNcep{s}(latIndsNorth, lonIndsNorth, :), 2), 1));
    heatNorthCorrEra(s) = corr(detrend(heatNorthEra), detrend(prNorth));
    
%     and for models
    for model = 1:length(models)
        heatSouthEra = squeeze(nansum(nansum(nansum(heatProbCmip5(latIndsSouth, lonIndsSouth, :, seasons(s,:), model), 4), 2), 1));
        prSouth = squeeze(nanmean(nanmean(prCmip5{s}(latIndsSouth, lonIndsSouth, :, model), 2), 1));
        heatSouthCorrCmip5(s, model) = corr(detrend(heatSouthEra), detrend(prSouth));

        heatNorthEra = squeeze(nansum(nansum(nansum(heatProbCmip5(latIndsNorth, lonIndsNorth, :, seasons(s,:), model), 4), 2), 1));
        prNorth = squeeze(nanmean(nanmean(prCmip5{s}(latIndsNorth, lonIndsNorth, :, model), 2), 1));
        heatNorthCorrCmip5(s, model) = corr(detrend(heatNorthEra), detrend(prNorth));
    end

end

if plotCorr
    figure('Color', [1,1,1]);
    colors = get(gca, 'colororder');
    hold on;
    axis square;
    box on;
    grid on;
    
    b = boxplot(heatNorthCorrCmip5');
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 
    
    plot(heatNorthCorrNcep, 'o', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    plot(heatNorthCorrEra, 'x', 'Color', 'k','MarkerSize', 30, 'LineWidth', 2);
    plot([0 5], [0 0], 'k--');
    set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});

    %set hottest season xtick label red
    ax = gca;
    ax.TickLabelInterpreter = 'tex';
    ax.XTickLabels{hottestNorth} = ['\color{red} ' ax.XTickLabels{hottestNorth}];

    leg = legend(' NCEP II', ' ERA-Interim');
    set(leg, 'location', 'northwest');
    ylim([-1 1]);
    xlim([.5 4.5]);
    ylabel('Correlation');
    set(gca, 'FontSize', 40);
    title('North');
    export_fig pr-heat-corr-north.eps;

    figure('Color',[1,1,1]);
    hold on;
    axis square;
    box on;
    grid on;
    b = boxplot(heatSouthCorrCmip5');
    set(b, {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2); 

    plot(heatSouthCorrNcep, 'o', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    plot(heatSouthCorrEra, 'x', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    plot([0 5], [0 0], 'k--');
    set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});

    %set hottest season xtick label red
    ax = gca;
    ax.TickLabelInterpreter = 'tex';
    ax.XTickLabels{hottestSouth} = ['\color{red} ' ax.XTickLabels{hottestSouth}];

    leg = legend(' NCEP II', ' ERA-Interim');
    set(leg, 'location', 'northwest');
    ylim([-1 1]);
    xlim([.5 4.5]);
    ylabel('Correlation');
    set(gca, 'FontSize', 40);
    title('South');

    export_fig pr-heat-corr-south.eps;
end

if plotHeatWaves
    %plot PR/heat time series in the hottest season for each region from ERA
    heatSouthEra = squeeze(nansum(nansum(nansum(heatProbEra(latIndsSouth, lonIndsSouth, :, seasons(hottestSouth,:)), 4), 2), 1));
    fHeatSouthEra = fit((1:length(heatSouthEra))', heatSouthEra, 'poly1');
    
    heatSouthNcep = squeeze(nansum(nansum(nansum(heatProbNcep(latIndsSouth, lonIndsSouth, :, seasons(hottestSouth,:)), 4), 2), 1));
    fHeatSouthNcep = fit((1:length(heatSouthNcep))', heatSouthNcep, 'poly1');
    
    heatNorthEra = squeeze(nansum(nansum(nansum(heatProbEra(latIndsNorth, lonIndsNorth, :, seasons(hottestNorth,:)), 4), 2), 1));
    fHeatNorthEra = fit((1:length(heatNorthEra))', heatNorthEra, 'poly1');
    
    heatNorthNcep = squeeze(nansum(nansum(nansum(heatProbNcep(latIndsNorth, lonIndsNorth, :, seasons(hottestNorth,:)), 4), 2), 1));
    fHeatNorthNcep = fit((1:length(heatNorthNcep))', heatNorthNcep, 'poly1');

    colors = get(gca, 'colororder');
    
    f = figure('Color', [1,1,1]);

    set(gcf, 'defaultAxesColorOrder', [[0.8500 0.3250 0.0980];
                                       [0 0.4470 0.7410]]);

    hold on;
    box on;
    grid on;
    axis square;
    p1 = plot(heatNorthEra, 'LineWidth', 2, 'Color', colors(2,:));
    if Mann_Kendall(heatNorthEra, 0.05)
        plot(1:length(heatNorthEra), fHeatNorthEra(1:length(heatNorthEra)), '--', 'Color', colors(2,:));
    end
    
    p2 = plot(heatNorthNcep, 'LineWidth', 2, 'Color', colors(3,:));
    if Mann_Kendall(heatNorthNcep, 0.05)
        plot(1:length(heatNorthNcep), fHeatNorthEra(1:length(heatNorthNcep)), '--', 'Color', colors(3,:));
    end
    ylim([0 150]);
    ylabel('JJA # Heat waves');

    set(gca, 'FontSize', 40);
    set(gca, 'XTick', 5:10:length(heatSouthEra), 'XTickLabels', 1985:10:2016);
    title('North: JJA');
    legend([p1 p2], 'ERA-Interim', 'NCEP II', 'location', 'northwest');
    export_fig heat-wave-timeseries-north.eps;
    close all;
    
    figure('Color', [1,1,1]);
    set(gcf, 'defaultAxesColorOrder', [[0.8500 0.3250 0.0980];
                                       [0 0.4470 0.7410]]);
    hold on;
    box on;
    grid on;
    axis square;

    p1 = plot(heatSouthEra, 'LineWidth', 2, 'Color', colors(2,:));
    if Mann_Kendall(heatSouthEra, 0.05)
        plot(1:length(heatSouthEra), fHeatSouthEra(1:length(heatSouthEra)), '--', 'Color', colors(2,:));
    end
    
    p2 = plot(heatNorthNcep, 'LineWidth', 2, 'Color', colors(3,:));
    if Mann_Kendall(heatNorthNcep, 0.05)
        plot(1:length(heatNorthNcep), fHeatNorthEra(1:length(heatNorthNcep)), '--', 'Color', colors(3,:));
    end
    
    ylim([0 150]);
    ylabel('MAM # Heat waves');

    set(gca, 'FontSize', 40);
    set(gca, 'XTick', 5:10:length(heatSouthEra), 'XTickLabels', 1985:10:2016);
    title('South: MAM');
    legend([p1 p2], 'ERA-Interim', 'NCEP II', 'location', 'northwest');
    export_fig heat-wave-timeseries-south.eps;
    close all;
end
