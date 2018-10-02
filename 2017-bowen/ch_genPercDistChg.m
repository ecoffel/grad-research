models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

load waterGrid.mat;
waterGrid = logical(waterGrid);

plotDistChg = true;
      
threshChgTw = [];
threshChgTx = [];
threshChgEf = [];

for m = 1:length(models)
    tind = 1;
    for t = 5:10:95
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTxTw(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-wb-davies-jones-full-tasmax-' models{m} '-rcp85-2061-2085.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTwTx(:, :, tind, m) = chgData;
        
        tind = tind+1;
    end
    
    load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-percentile-' num2str(t) '-wb-davies-jones-full-tasmax-' models{m} '-historical-1981-2005.mat']);
    threshPercTwTxHist(:, :, :, m) = baseData;
    
    load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-percentile-' num2str(t) '-wb-davies-jones-full-tasmax-' models{m} '-rcp85-2061-2085.mat']);
    threshPercTwTxFut(:, :, :, m) = futureData;
    
    load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-percentile-' num2str(t) '-tasmax-wb-davies-jones-full-' models{m} '-historical-1981-2005.mat']);
    threshPercTxTwHist(:, :, :, m) = baseData;
    
    load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-percentile-' num2str(t) '-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085.mat']);
    threshPercTxTwFut(:, :, :, m) = futureData;
end

colorWb = [68, 166, 226]./255.0;
colorTxx = [216, 66, 19]./255.0;

twtx = squeeze(nanmean(nanmean(threshPercTwTxFut,2),1))-squeeze(nanmean(nanmean(threshPercTwTxHist,2),1));
txtw = squeeze(nanmean(nanmean(threshPercTxTwFut,2),1))-squeeze(nanmean(nanmean(threshPercTxTwHist,2),1));

figure('Color', [1,1,1]);
hold on;
axis square;
grid on;
box on;

for t = 1:size(twtx, 1)
    t = text(nanmedian(twtx(t,:),2)*10, nanmedian(txtw(t,:),2)*10, num2str(t*10-5), 'HorizontalAlignment', 'center', 'Color', 'k');
    t.FontSize = 26;
end

ylim([-2 2])
xlim([-2 2])
plot([-2 2], [0 0], '--k', 'linewidth', 2);
plot([0 0], [-2 2], '--k', 'linewidth', 2);

xlabel('Tx percentile change');
ylabel('T_W percentile change');
set(gca, 'fontsize', 36, 'xtick', -2:2, 'ytick', -2:2);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['tw-perc-tx-perc.eps']);
close all;

if plotDistChg
    figure('Color', [1,1,1]);
    hold on;
    axis square;
    grid on;
    box on;

    trange = 5:10:95;
    medchg = squeeze(nanmean(nanmean(nanmean(threshChgTxTw(:,:,5:6,:),3),2),1));
    for t = 1:length(trange)
        cury = nanmedian(squeeze(nanmean(nanmean(threshChgTxTw(:,:,t,:), 2), 1))-medchg);
        curyrange = squeeze(nanmean(nanmean(threshChgTxTw(:,:,t,:), 2), 1))-medchg;
        er = errorbar(trange(t), cury, cury-min(curyrange), max(curyrange)-cury);
        plot(trange(t), cury, 'ok', 'linewidth', 2, 'markersize', 15, 'markerfacecolor', colorWb);
        set(er, 'color', colorWb, 'linewidth', 2);
    end
    plot([0 100], [0 0], '--k', 'linewidth', 2);
    xlim([0 100]);
    set(gca, 'fontsize', 36);
    xlabel('Warm season Tx percentile');
    set(gca, 'XTick', 5:10:95);
    ylabel(['T_W amplification (' char(176) 'C)']);
    
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['tw-chg-tx-perc.eps']);
    close all;
    
    
    figure('Color', [1,1,1]);
    hold on;
    axis square;
    grid on;
    box on;

    trange = 5:10:95;
    medchg = squeeze(nanmean(nanmean(nanmean(threshChgTwTx(:,:,5:6,:),3),2),1));
    for t = 1:length(trange)
        cury = nanmedian(squeeze(nanmean(nanmean(threshChgTwTx(:,:,t,:), 2), 1))-medchg);
        curyrange = squeeze(nanmean(nanmean(threshChgTwTx(:,:,t,:), 2), 1))-medchg;
        er = errorbar(trange(t), cury, cury-min(curyrange), max(curyrange)-cury);
        plot(trange(t), cury, 'ok', 'linewidth', 2, 'markersize', 15, 'markerfacecolor', colorTxx);
        set(er, 'color', colorTxx, 'linewidth', 2);
    end
    
    plot([0 100], [0 0], '--k', 'linewidth', 2);
    xlim([0 100]);
    set(gca, 'fontsize', 36);
    xlabel('Warm season T_W percentile');
    set(gca, 'XTick', 5:10:95);
    ylabel(['Tx amplification (' char(176) 'C)']);
    
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['tx-chg-tw-perc.eps']);
    close all;
    
    
    
    
    
    figure('Color', [1,1,1]);
    hold on;
    axis square;
    grid on;
    box on;

    trange = 5:10:95;
    medchg = squeeze(nanmean(nanmean(nanmean(threshChgTwTx(:,:,5:6,:)))));
    for t = 1:length(trange)
        cury = nanmedian(squeeze(nanmean(nanmean(threshChgTwTx(:,:,t,:),2),1))-medchg);
        curyrange = squeeze(nanmean(nanmean(threshChgTwTx(:,:,t,:),2),1))-medchg;
        er = errorbar(trange(t), cury, cury-min(curyrange), max(curyrange)-cury);
        plot(trange(t), cury, 'ok', 'linewidth', 2, 'markersize', 15, 'markerfacecolor', colorTxx);
        set(er, 'color', colorTxx, 'linewidth', 2);
    end
    
    plot([0 100], [0 0], '--k', 'linewidth', 2);
    xlim([0 100]);
    set(gca, 'fontsize', 36);
    xlabel('Warm season T_W percentile');
    set(gca, 'XTick', 5:10:95);
    ylabel(['Tx amplification (' char(176) 'C)']);
    
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['tx-chg-tw-perc.eps']);
    close all;
end


