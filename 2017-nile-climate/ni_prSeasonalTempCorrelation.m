plotCorr = true;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

tempCmip5 = {};
prCmip5 = {};
for model = 1:length(models)
    load(['2017-nile-climate/output/temp-cmip5-historical-' models{model} '.mat']);
    load(['2017-nile-climate/output/pr-cmip5-historical-' models{model} '.mat']);
    for s = 1:length(prSeasonal)
        prCmip5{s}(:, :, :, model) = prSeasonal{s};
        tempCmip5{s}(:, :, :, model) = TSeasonal{s};
    end
end
       
load 2017-nile-climate/output/temp-era-interim.mat;
load 2017-nile-climate/output/pr-era-interim.mat;

tempEra = TSeasonal;
prEra = pr;

load 2017-nile-climate/output/temp-ncep-reanalysis.mat;
load 2017-nile-climate/output/pr-ncep-reanalysis.mat;

tempNcep = TSeasonal;
prNcep = pr;

% load 2017-nile-climate/output/temp-gldas.mat;
% load 2017-nile-climate/output/pr-gldas.mat;

% tempGldas = TSeasonal;
% prGldas = prSeasonal;
% 
% load('lat-gldas');
% load('lon-gldas');
% latGldas = lat;
% lonGldas = lon;

load lat;
load lon;

% find bounds of whole region and north/south subregions
regionBounds = [[2 32]; [25, 44]];
regionBoundsNorth = [[13 32]; [29, 34]];
regionBoundsSouth = [[2 13]; [25, 42]];

[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

% [latIndsGldas, lonIndsGldas] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));
% [latIndsNorthGldas, lonIndsNorthGldas] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
% [latIndsSouthGldas, lonIndsSouthGldas] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));

load 2017-nile-climate\hottest-season-ncep.mat;
hottestNorth = mode(reshape(hottestSeason(latIndsNorth, lonIndsNorth), [numel(hottestSeason(latIndsNorth, lonIndsNorth)), 1]));
hottestSouth = mode(reshape(hottestSeason(latIndsSouth, lonIndsSouth), [numel(hottestSeason(latIndsSouth, lonIndsSouth)), 1]));

% find relative indicies of north/south
latIndsSouth = latIndsSouth-latInds(1)+1;
latIndsNorth = latIndsNorth-latInds(1)+1;
lonIndsSouth = lonIndsSouth-lonInds(1)+1;
lonIndsNorth = lonIndsNorth-lonInds(1)+1;

% latIndsSouthGldas = latIndsSouthGldas-latInds(1)+1;
% latIndsNorthGldas = latIndsNorthGldas-latInds(1)+1;
% lonIndsSouthGldas = lonIndsSouthGldas-lonInds(1)+1;
% lonIndsNorthGldas = lonIndsNorthGldas-lonInds(1)+1;

seasons = [[12 1 2]; 
           [3 4 5];
           [6 7 8];
           [9 10 11]];

tempPrCorrNcep = [];
tempPrCorrEra = [];
% tempPrCorrGldas = [];
tempPrCorrCmip5 = [];

tempPrSouthCorrNcep = [];
tempPrNorthCorrNcep = [];
tempPrSouthCorrEra = [];
tempPrNorthCorrEra = [];
% tempPrSouthCorrGldas = [];
% tempPrNorthCorrGldas = [];
tempPrNorthCorrCmip5 = [];
tempPrSouthCorrCmip5 = [];
for s = 1:size(seasons, 1)
    
    % process GLDAS (on a different grid so needs its own xlat/ylon loop)
%     for xlat = 1:size(tempGldas{s}, 1)
%         for ylon = 1:size(tempGldas{s}, 2)
%             % for GLDAS
%             temp = squeeze(tempGldas{s}(xlat, ylon, :));
%             pr = squeeze(prGldas{s}(xlat, ylon, :));
%             nn = find(~isnan(temp) & ~isnan(pr));
%             if length(nn) > .5*length(temp)
%                 tempPrCorrGldas(xlat, ylon, s) = corr(temp(nn), pr(nn));
%             else
%                 tempPrCorrGldas(xlat, ylon, s) = NaN;
%             end
%         end
%     end
    
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
    tempSouth = squeeze(nanmean(nanmean(tempEra{s}(latIndsSouth, lonIndsSouth, :), 2), 1));
    prSouth = squeeze(nanmean(nanmean(prEra{s}(latIndsSouth, lonIndsSouth, :), 2), 1));
    tempPrSouthCorrEra(s) = corr(detrend(tempSouth), detrend(prSouth));

    tempNorth = squeeze(nanmean(nanmean(tempEra{s}(latIndsNorth, lonIndsNorth, :), 2), 1));
    prNorth = squeeze(nanmean(nanmean(prEra{s}(latIndsNorth, lonIndsNorth, :), 2), 1));
    tempPrNorthCorrEra(s) = corr(detrend(tempNorth), detrend(prNorth));
    
    % GLDAS
%     tempSouth = squeeze(nanmean(nanmean(tempGldas{s}(latIndsSouthGldas, lonIndsSouthGldas, :), 2), 1));
%     prSouth = squeeze(nanmean(nanmean(prGldas{s}(latIndsSouthGldas, lonIndsSouthGldas, :), 2), 1));
%     tempPrSouthCorrGldas(s) = corr(detrend(tempSouth), detrend(prSouth));
% 
%     tempNorth = squeeze(nanmean(nanmean(tempGldas{s}(latIndsNorthGldas, lonIndsNorthGldas, :), 2), 1));
%     prNorth = squeeze(nanmean(nanmean(prGldas{s}(latIndsNorthGldas, lonIndsNorthGldas, :), 2), 1));
%     tempPrNorthCorrGldas(s) = corr(detrend(tempNorth), detrend(prNorth));
    
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

if plotCorr
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
    %plot(tempPrNorthCorrGldas, 'd', 'Color', 'k','MarkerSize', 30, 'LineWidth', 2);
    plot([0 5], [0 0], 'k--');
    set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});

    % set hottest season xtick label red
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
    export_fig pr-temp-corr-north.eps;

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
    %plot(tempPrSouthCorrGldas, 'd', 'Color', 'k', 'MarkerSize', 30, 'LineWidth', 2);
    plot([0 5], [0 0], 'k--');
    set(gca, 'XTick', 1:4, 'XTickLabels', {'DJF', 'MAM', 'JJA', 'SON'});

    % set hottest season xtick label red
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

    export_fig pr-temp-corr-south.eps;
end

% 
% % plot PR/heat time series in the hottest season for each region from ERA
% tempSouth = squeeze(nansum(nansum(nansum(heatProbEra(latIndsSouth, lonIndsSouth, :, seasons(hottestSouth,:)), 4), 2), 1));
% prSouth = squeeze(nanmean(nanmean(tempEra{hottestSouth}(latIndsSouth, lonIndsSouth, :), 2), 1));
% fPrSouth = fit((1:length(prSouth))', prSouth, 'poly1');
% fHeatSouth = fit((1:length(tempSouth))', tempSouth, 'poly1');
% 
% tempNorth = squeeze(nansum(nansum(nansum(heatProbEra(latIndsNorth, lonIndsNorth, :, seasons(hottestNorth,:)), 4), 2), 1));
% prNorth = squeeze(nanmean(nanmean(tempEra{hottestNorth}(latIndsNorth, lonIndsNorth, :), 2), 1));
% fPrNorth = fit((1:length(prNorth))', prNorth, 'poly1');
% fHeatNorth = fit((1:length(tempNorth))', tempNorth, 'poly1');
% 
% f = figure('Color', [1,1,1]);
% 
% set(gcf, 'defaultAxesColorOrder', [[0.8500 0.3250 0.0980];
%                                    [0 0.4470 0.7410]]);
% 
% hold on;
% box on;
% grid on;
% axis square;
% yyaxis left;
% plot(tempNorth, 'LineWidth', 2);
% if Mann_Kendall(tempNorth, 0.05)
%     plot(1:length(tempNorth), fHeatNorth(1:length(tempNorth)), '--');
% end
% ylim([0 150]);
% ylabel('# heat waves');
% 
% yyaxis right;
% plot(prNorth, 'LineWidth', 2);
% if Mann_Kendall(prNorth, 0.05)
%     plot(1:length(prNorth), fPrNorth(1:length(prNorth)), '--');
% end
% ylim([0 5]);
% ylabel('Precipitation (mm/day)');
% 
% set(gca, 'FontSize', 40);
% set(gca, 'XTick', 5:10:length(tempSouth), 'XTickLabels', 1985:10:2016);
% title('North: JJA');
% 
% export_fig temp-pr-timeseries-north.eps;
% 
% figure('Color', [1,1,1]);
% set(gcf, 'defaultAxesColorOrder', [[0.8500 0.3250 0.0980];
%                                    [0 0.4470 0.7410]]);
%                     
% hold on;
% box on;
% grid on;
% axis square;
% 
% yyaxis left;
% plot(tempSouth, 'LineWidth', 2);
% if Mann_Kendall(tempSouth, 0.05)
%     plot(1:length(tempSouth), fHeatSouth(1:length(tempSouth)), '--');
% end
% ylim([0 150]);
% ylabel('# heat waves');
% 
% yyaxis right;
% plot(prSouth, 'LineWidth', 2);
% if Mann_Kendall(prSouth, 0.05)
%     plot(1:length(prSouth), fPrSouth(1:length(prSouth)), '--');
% end
% ylim([0 5]);
% ylabel('Precipitation (mm/day)');
% 
% set(gca, 'FontSize', 40);
% set(gca, 'XTick', 5:10:length(tempSouth), 'XTickLabels', 1985:10:2016);
% title('South: MAM');
% 
% export_fig temp-pr-timeseries-south.eps;
% 
