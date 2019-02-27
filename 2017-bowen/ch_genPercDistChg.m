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
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085-each-year.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTxTw(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-wb-davies-jones-full-tasmax-' models{m} '-rcp85-2061-2085-each-year.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTwTx(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-huss-' models{m} '-rcp85-2061-2085-each-year.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTxHuss(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-wb-davies-jones-full-huss-' models{m} '-rcp85-2061-2085-each-year.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTwHuss(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-ef-' models{m} '-rcp85-2061-2085-each-year.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        chgData(chgData > 1 | chgData < 0) = NaN;
        threshChgTxEf(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-wb-davies-jones-full-ef-' models{m} '-rcp85-2061-2085-each-year.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        chgData(chgData > 1 | chgData < 0) = NaN;
        threshChgTwEf(:, :, tind, m) = chgData;
        
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

% twtx = squeeze(nanmean(nanmean(threshPercTwTxFut,2),1))-squeeze(nanmean(nanmean(threshPercTwTxHist,2),1));
% txtw = squeeze(nanmean(nanmean(threshPercTxTwFut,2),1))-squeeze(nanmean(nanmean(threshPercTxTwHist,2),1));
% 
% figure('Color', [1,1,1]);
% hold on;
% axis square;
% grid on;
% box on;
% 
% for t = 1:size(twtx, 1)
%     t = text(nanmedian(twtx(t,:),2)*10, nanmedian(txtw(t,:),2)*10, num2str(t*10-5), 'HorizontalAlignment', 'center', 'Color', 'k');
%     t.FontSize = 26;
% end
% 
% ylim([-2 2])
% xlim([-2 2])
% plot([-2 2], [0 0], '--k', 'linewidth', 2);
% plot([0 0], [-2 2], '--k', 'linewidth', 2);
% 
% xlabel('Tx percentile change');
% ylabel('T_W percentile change');
% set(gca, 'fontsize', 36, 'xtick', -2:2, 'ytick', -2:2);
% set(gcf, 'Position', get(0,'Screensize'));
% export_fig(['tw-perc-tx-perc.eps']);
% close all;



if plotDistChg
    
    thresh1 = threshChgTxHuss .* 1000;
    thresh2 = threshChgTxTw;
    
    figure('Color', [1,1,1]);
    hold on;
    pbaspect([2 1 1]);
    grid on;
    box on;

    plot([0 100], [0 0], '--k', 'linewidth', 2);
    trange = 5:10:95;
    medchg = squeeze(nanmean(nanmean(nanmean(thresh1(:,:,5:6,:),3),2),1));
    
    mrange = squeeze(nanmean(nanmean(thresh1, 2), 1))'-medchg;
    mrange = sort(mrange, 1);
    
    b = boxplot(mrange(round(.1*length(models)):round(.9*length(models)), :), 'Positions', trange);
    set(b, {'LineWidth', 'Color'}, {2, colorTxx})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 3);
    
    xlim([0 100]);
    ylim([-.8 .7]);
    set(gca, 'fontsize', 36);
    xlabel('Warm season Tx percentile');
    set(gca, 'XTick', 5:10:95, 'XTickLabels', 5:10:95);
    set(gca, 'YTick', -.8:.2:.7);
    ylabel(['Specific hum. amplification (g/kg)']);
    
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['huss-chg-tx-perc.eps']);
    close all;
    
    
    figure('Color', [1,1,1]);
    hold on;
    pbaspect([2 1 1]);
    grid on;
    box on;

    plot([0 100], [0 0], '--k', 'linewidth', 2);
    trange = 5:10:95;
    medchg = squeeze(nanmean(nanmean(nanmean(thresh2(:,:,5:6,:),3),2),1));

    mrange = squeeze(nanmean(nanmean(thresh2, 2), 1))'-medchg;
    mrange = sort(mrange, 1);
    
    b = boxplot(mrange(round(.1*length(models)):round(.9*length(models)), :), 'Positions', trange);
    set(b, {'LineWidth', 'Color'}, {2, colorWb})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 3);
    
    xlim([0 100]);
    ylim([-.7 .5]);
    set(gca, 'fontsize', 36);
    xlabel('Warm season Tx percentile');
    set(gca, 'XTick', 5:10:95, 'XTickLabels', 5:10:95);
    ylabel(['T_W amplification (' char(176) 'C)']);
    
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['tw-chg-tx-perc.eps']);
    close all;
    
    
    
    
    
    
    
    % -----------------------------------------------------------------
    
    
    
    thresh1 = threshChgTxHuss .* 1000;
    thresh2 = threshChgTwHuss .* 1000;
    
    
    
    figure('Color', [1,1,1]);
    hold on;
    pbaspect([2 1 1]);
    grid on;
    box on;

    plot([0 100], [0 0], '--k', 'linewidth', 2);
    trange = 5:10:95;
    medchg = squeeze(nanmean(nanmean(nanmean(thresh1(:,:,5:6,:),3),2),1));
    
    mrange = squeeze(nanmean(nanmean(thresh1, 2), 1))'-medchg;
    mrange = sort(mrange, 1);
    
    b = boxplot(mrange(round(.1*length(models)):round(.9*length(models)), :), 'Positions', trange);
    set(b, {'LineWidth', 'Color'}, {2, colorTxx})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 3);
    
    xlim([0 100]);
    ylim([-.8 1]);
    set(gca, 'fontsize', 36);
    xlabel('Warm season Tx percentile');
    set(gca, 'XTick', 5:10:95, 'XTickLabels', 5:10:95);
    set(gca, 'YTick', -.8:.2:1);
    ylabel(['Specific humidity change (g/kg)']);
    
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['huss-chg-tx-perc.eps']);
    close all;
    
    
    figure('Color', [1,1,1]);
    hold on;
    pbaspect([2 1 1]);
    grid on;
    box on;

    plot([0 100], [0 0], '--k', 'linewidth', 2);
    trange = 5:10:95;
    medchg = squeeze(nanmean(nanmean(nanmean(thresh2(:,:,5:6,:),3),2),1));

    mrange = squeeze(nanmean(nanmean(thresh2, 2), 1))'-medchg;
    mrange = sort(mrange, 1);
    
    b = boxplot(mrange(round(.1*length(models)):round(.9*length(models)), :), 'Positions', trange);
    set(b, {'LineWidth', 'Color'}, {2, colorWb})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 3);
    
    xlim([0 100]);
    ylim([-.8 1]);
    set(gca, 'fontsize', 36);
    xlabel('Warm season T_W percentile');
    set(gca, 'XTick', 5:10:95, 'XTickLabels', 5:10:95);
    set(gca, 'YTick', -.8:.2:1);
    ylabel(['Specific humidity change (g/kg)']);
    
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['huss-chg-tw-perc.eps']);
    close all;
    
end


