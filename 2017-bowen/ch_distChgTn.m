models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', 'canesm2', ...
              'ccsm4', 'cesm1-bgc', 'cesm1-cam5', 'cmcc-cm', 'cmcc-cms', 'cmcc-cesm', 'cnrm-cm5', 'csiro-mk3-6-0', ...
              'fgoals-g2', 'gfdl-esm2g', 'gfdl-esm2m', 'hadgem2-cc', ...
              'inmcm4', 'ipsl-cm5a-mr', 'miroc5', 'miroc-esm', ...
              'mpi-esm-mr', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

load waterGrid.mat;
waterGrid = logical(waterGrid);

plotDistChg = true;

plotSpatialChg = false;

chgTn = [];

for m = 1:length(models)
      
    tind = 1;
    for t = [0 5:10:95 100]
        load(['E:\data\projects\snow\chgData-cmip5-percentile-chg-' num2str(t) '-tasmin-' models{m} '-rcp85-2061-2085.mat']);
        chgData(waterGrid) = NaN;
        chgTn(:, :, tind, m) = chgData;
        
        
        tind = tind+1;
    end
end

colorWb = [68, 166, 226]./255.0;
colorTxx = [216, 66, 19]./255.0;

meanChg = nanmean(nanmean(nanmean(nanmean(chgTn,2),1),3), 4);

 fig = figure('Color', [1,1,1]);
    hold on;
    axis square;
    grid on;
    box on;

    
    % yyaxis left;
    trange = [0 5:10:95 100];
    for t = 1:length(trange)
        cury = nanmedian(squeeze(nanmean(nanmean(chgTn(:,:,t,:),2),1)), 1);
        curyrange = squeeze(nanmean(nanmean(chgTn(:,:,t,:),2),1));
        er = errorbar(trange(t), cury, std(curyrange)/2, std(curyrange)/2);
        plot(trange(t), cury, 'ok', 'linewidth', 2, 'markersize', 15, 'markerfacecolor', colorTxx);
        set(er, 'color', colorTxx, 'linewidth', 2);
    end
    
    plot([0 100], [meanChg meanChg], '--', 'linewidth', 2', 'color', colorTxx);
    
    xlim([-5 105]);
    set(gca, 'fontsize', 36);
    xlabel('Cold season Tn percentile');
    set(gca, 'XTick', 5:10:95);
    ylabel(['Change (' char(176) 'C)']);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['tn-dist-chg.eps']);
    close all;



