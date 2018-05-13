base = 'cmip5';

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-historical-1981-2005-t90-p10.mat']);
hotDryHistorical = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp85-2056-2080.mat']);
hotDryFutureNorm = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp85-2056-2080-t90-p10-tnone-pfull.mat']);
hotDryFutureTnonePfull = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp85-2056-2080-t90-p10-tnone-pmean-monthly.mat']);
hotDryFutureTnonePmean = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp85-2056-2080-t90-p10-tmean-pnone-monthly.mat']);
hotDryFutureTmeanPnone = hotDryFuture;

load(['2017-nile-climate\output\hotDryFuture-annual-' base '-rcp85-2056-2080-t90-p10-tfull-pnone.mat']);
hotDryFutureTfullPnone = hotDryFuture;

drawScatter = true;
drawMap = false;
north = true;
annual = true;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'hadgem2-es', 'inmcm4', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

seasons = [[12 1 2];
           [3 4 5];
           [6 7 8];
           [9 10 11]];
seasonNames = {'DJF', 'MAM', 'JJA', 'SON'};

load lat;
load lon;

regionBounds = [[2 32]; [25, 44]];
[latInds, lonInds] = latLonIndexRange({lat,lon,[]}, regionBounds(1,:), regionBounds(2,:));

regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsNorth = [[13 32]; [29, 34]];

[latIndsNorth, lonIndsNorth] = latLonIndexRange({lat,lon,[]}, regionBoundsNorth(1,:), regionBoundsNorth(2,:));
[latIndsSouth, lonIndsSouth] = latLonIndexRange({lat,lon,[]}, regionBoundsSouth(1,:), regionBoundsSouth(2,:));
latIndsNorth = latIndsNorth - latInds(1) + 1;
lonIndsNorth = lonIndsNorth - lonInds(1) + 1;
latIndsSouth = latIndsSouth - latInds(1) + 1;
lonIndsSouth = lonIndsSouth - lonInds(1) + 1;

if drawScatter
    
    if north
        curLatInds = latIndsNorth;
        curLonInds = lonIndsNorth;
    else
        curLatInds = latIndsSouth;
        curLonInds = lonIndsSouth;
    end
    
    hdHist = hotDryHistorical;
    hdHist = hdHist(curLatInds, curLonInds, :);
    hdHist = squeeze(nanmean(nanmean(hdHist,2),1));
    
    hdFuture = hotDryFutureNorm;
    hdFuture = hdFuture(curLatInds, curLonInds, :);
    hdFuture = squeeze(nanmean(nanmean(hdFuture,2),1));

    hdFutureTnPf = hotDryFutureTnonePfull;
    hdFutureTnPf = hdFutureTnPf(curLatInds, curLonInds, :);
    hdFutureTnPf = squeeze(nanmean(nanmean(hdFutureTnPf,2),1));

    hdFutureTnPm = hotDryFutureTnonePmean;
    hdFutureTnPm = hdFutureTnPm(curLatInds, curLonInds, :);
    hdFutureTnPm = squeeze(nanmean(nanmean(hdFutureTnPm,2),1));

    hdFutureTfPn = hotDryFutureTfullPnone;
    hdFutureTfPn = hdFutureTfPn(curLatInds, curLonInds, :);
    hdFutureTfPn = squeeze(nanmean(nanmean(hdFutureTfPn,2),1));
    
    hdFutureTmPn = hotDryFutureTmeanPnone;
    hdFutureTmPn = hdFutureTmPn(curLatInds, curLonInds, :);
    hdFutureTmPn = squeeze(nanmean(nanmean(hdFutureTmPn,2),1));

    totalShift = (hdFuture-hdHist).*100;
    pTfPn = (hdFutureTfPn-hdHist).*100;
    pTnPm = (hdFutureTnPm-hdHist).*100;
    pTnPf = (hdFutureTnPf-hdHist).*100;
    pTPI = totalShift - pTfPn - pTnPf;
    
    figure('Color', [1,1,1]);
    hold on;
    box on;
    grid on;
    axis square;
    
    b = boxplot([totalShift, pTfPn pTnPm pTnPf pTPI], ...
                 'colors', 'rbbbb', 'positions', [1 2 3 4 5]);
    plot([0 8], [0 0], '--k');
    ylim([-10 30]);
    xlim([.5 5.5]);
    for bind = 1:size(b, 2)
        if bind == 5
            set(b(:,bind), {'LineWidth', 'Color'}, {2, [110, 191, 66]./255.0})
            lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
            set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
        elseif bind == 3 || bind == 4
            set(b(:,bind), {'LineWidth', 'Color'}, {2, [85/255.0, 158/255.0, 237/255.0]})
            lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
            set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
        elseif bind == 2
            set(b(:, bind), {'LineWidth', 'Color'}, {2, [239, 168, 55]./255.0})
            lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
            set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
        elseif bind == 1
            set(b(:, bind), {'LineWidth', 'Color'}, {2, [247, 92, 81]./255.0})
            lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
            set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2); 
        end
    end

    ylabel('Change (percentage points)');
    set(gca,'TickLabelInterpreter', 'tex');    
    set(gca, 'XTick', [1 2 3 4 5], 'XTickLabels', {'Total', 'T_{full}', 'P_{mean}', 'P_{full}', 'P-T_{int}'});
    set(gca, 'YTick', -10:10:30);
    set(gca, 'FontSize', 36);
    %title([seasonNames{s}]);
    set(gcf, 'Position', get(0,'Screensize'));

    if north
        export_fig(['hot-dry-contrib-north.eps']);
    else
        export_fig(['hot-dry-contrib-south.eps']);
    end
    close all;
end
