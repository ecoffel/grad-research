models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

load waterGrid.mat;
waterGrid = logical(waterGrid);

plotDistChg = true;

plotSpatialChg = false;

chgTw = [];
chgTx = [];
threshChgTw = [];
threshChgTw50 = [];
threshChgTx = [];
threshChgTx50 = [];
threshChgEf = [];
humid = [];
groups = [];

for m = 1:length(models)
    
    load(['e:/data/projects/bowen/derived-chg/var-stats/efGroup-' models{m} '.mat']);
    groups(:,:,m) = efGroup;
    
    load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-warm-season-tx-wb-davies-jones-full-' models{m} '-rcp85-2061-2085.mat']);
    chgData(waterGrid) = NaN;
    chgData(1:15,:) = NaN;
    chgData(75:90,:) = NaN;
    chgTw(:, :, m) = chgData;
    
    load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-warm-season-tx-tasmax-' models{m} '-rcp85-2061-2085.mat']);
    chgData(waterGrid) = NaN;
    chgData(1:15,:) = NaN;
    chgData(75:90,:) = NaN;
    chgTx(:, :, m) = chgData;
    
    tind = 1;
    for t = [5:10:95 100]
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-wb-davies-jones-full-' models{m} '-rcp85-2061-2085-each-year.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTw(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-' models{m} '-rcp85-2061-2085-each-year.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTx(:, :, tind, m) = chgData;
        
        tind = tind+1;
    end
    
end

colorWb = [68, 166, 226]./255.0;
colorTxx = [216, 66, 19]./255.0;

if plotSpatialChg
    
    twGroupChg = [];
    txGroupChg = [];
    
    for m = 1:length(models)
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-warm-season-tx-wb-davies-jones-full-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        chgData =  reshape(chgData, [numel(chgData),1]);
        
        load(['E:\data\projects\bowen\derived-chg\var-stats\twGroup-' models{m} '.mat']);
        efGroup = twGroup;
        efGroup(waterGrid) = NaN;
        efGroup(1:15,:) = NaN;
        efGroup(75:90,:) = NaN;
        efGroup =  reshape(efGroup, [numel(efGroup),1]);
        
        for t = 1:10
            twGroupChg(t, m) = nanmean(chgData(find(efGroup == t)));
        end
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-warm-season-tx-tasmax-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        chgData =  reshape(chgData, [numel(chgData),1]);
        
        for t = 1:10
            txGroupChg(t, m) = nanmean(chgData(find(efGroup == t)));
        end
        
    end
    
    figure('Color', [1,1,1]);
    hold on;
    axis square;
    grid on;
    box on;

    % yyaxis left;
    trange = 5:10:95;
    for t = 1:length(trange)
        cury = squeeze(nanmedian(twGroupChg(t,:),2));
        curyrange = squeeze(twGroupChg(t,:));
        er = errorbar(trange(t), cury, std(curyrange)/2, std(curyrange)/2);
        plot(trange(t), cury, 'ok', 'linewidth', 2, 'markersize', 15, 'markerfacecolor', colorWb);
        set(er, 'color', colorWb, 'linewidth', 2);

        cury = squeeze(nanmedian(txGroupChg(t,:),2));
        curyrange = squeeze(txGroupChg(t,:));
        er = errorbar(trange(t), cury, std(curyrange)/2, std(curyrange)/2);
        plot(trange(t), cury, 'ok', 'linewidth', 2, 'markersize', 15, 'markerfacecolor', colorTxx);
        set(er, 'color', colorTxx, 'linewidth', 2);
    end
    % yyaxis right;
    % plot(0:5:100, squeeze(nanmean(nanmean(nanmedian(threshChgEf,4),2),1)), 'ok', 'linewidth', 3);
    % ylim([-.05 .05]);
    ylim([2 6.5])
    xlim([-5 105]);
    set(gca, 'fontsize', 36);
    xlabel('Global spatial percentile');
    set(gca, 'XTick', 5:10:95);
    ylabel(['Change (' char(176) 'C)']);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['txx-wb-spatial-dist-chg.eps']);
    close all;
    
end

if plotDistChg
    trange = [5:10:95 100];
    
    
    fig = figure('Color', [1,1,1]);
    hold on;
    pbaspect([2,1,1]);
    grid on;
    box on;

    %chgTxRange = sort(squeeze(nanmean(nanmean(chgTx,2),1)),1);
%     yval = nanmedian(chgTxRange);
%     yrange = [chgTxRange(round(.9*length(models)))-yval;
%               yval-chgTxRange(round(.1*length(models)))];
    
    
%     yerr = [];
%     yerr(1,1,:)=yrange;
%     yerr(1,2,:)=yrange;
%     
%     s = mseb([0 101.25], [yval yval], [yerr], [], 1);
%     set(s.mainLine, 'Color', colorTxx, 'LineWidth', 2);
%     set(s.patch, 'FaceColor', colorTxx);
%     set(s.edge, 'Color', 'w');
    
    mrange = squeeze(nanmean(nanmean(threshChgTx, 2), 1))';
    mrange = sort(mrange, 1);
    
    yval = sort(squeeze(nanmean(nanmean(nanmean(threshChgTx(:, :, 5:6, :), 3), 2), 1))');
    yval = nanmedian(yval(round(.1*length(models)):round(.9*length(models))));
    
    b = boxplot(mrange(round(.1*length(models)):round(.9*length(models)), :), 'Positions', trange);
    set(b, {'LineWidth', 'Color'}, {2, colorTxx})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 3);
    
    plot([0 101.25], [yval yval], 'color', colorTxx, 'linewidth', 2);
    
    ylim([1.75 5.7])
    xlim([-5 105]);
    set(gca, 'fontsize', 36);
    xlabel('Warm season percentile');
    set(gca, 'XTick', 5:10:95, 'XTickLabels', 5:10:95);
    set(gca, 'YTick', 1.5:.5:5.5);
    ylabel(['Change (' char(176) 'C)']);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['tx-dist-chg.eps']);
    close all;
    
    
    fig = figure('Color', [1,1,1]);
    hold on;
    pbaspect([2,1,1]);
    grid on;
    box on;

%     chgTwRange = sort(squeeze(nanmean(nanmean(chgTw,2),1)),1);
%     yval = nanmedian(chgTwRange);
%     yrange = [chgTwRange(round(.9*length(models)))-yval;
%               yval-chgTwRange(round(.1*length(models)))];
%     
%     yerr = [];
%     yerr(1,1,:)=yrange;
%     yerr(1,2,:)=yrange;
    
    
%     s = mseb([0 101.25], [yval yval], [yerr], [], 1);
%     set(s.mainLine, 'Color', colorWb, 'LineWidth', 2);
%     set(s.patch, 'FaceColor', colorWb);
%     set(s.edge, 'Color', 'w');
    
    mrange = squeeze(nanmean(nanmean(threshChgTw, 2), 1))';
    mrange = sort(mrange, 1);
    
    yval = sort(squeeze(nanmean(nanmean(nanmean(threshChgTw(:, :, 5:6, :), 3), 2), 1))');
    yval = nanmedian(yval(round(.1*length(models)):round(.9*length(models))));
    
    b = boxplot(mrange(round(.1*length(models)):round(.9*length(models)), :), 'Positions', trange);
    set(b, {'LineWidth', 'Color'}, {2, colorWb})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 3);
    
    plot([0 101.25], [yval yval], 'color', colorWb, 'linewidth', 2);
    
    ylim([1.75 5.7])
    xlim([-5 105]);
    set(gca, 'fontsize', 36);
    xlabel('Warm season percentile');
    set(gca, 'XTick', 5:10:95, 'XTickLabels', 5:10:95);
    set(gca, 'YTick', 1.5:.5:5.5);
    ylabel(['Change (' char(176) 'C)']);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['tw-dist-chg.eps']);
    close all;
    
    
    fig = figure('Color', [1,1,1]);
    hold on;
    axis square;
    grid on;
    box on;

    yval = nanmedian(nanmean(nanmean(chgTx,2),1),3);
    yrange = std(squeeze(nanmean(nanmean(chgTx,2),1)))/2;
    
    s = mseb([0 100], [yval yval], [yrange yrange], [], 1);
    set(s.mainLine, 'Color', colorTxx, 'LineWidth', 3);
    set(s.patch, 'FaceColor', colorTxx);
    set(s.edge, 'Color', 'w');
    
    yval = nanmedian(nanmean(nanmean(chgTw,2),1),3);
    yrange = std(squeeze(nanmean(nanmean(chgTw,2),1)))/2;
    
    s = mseb([0 100], [yval yval], [yrange yrange], [], 1);
    set(s.mainLine, 'Color', colorWb, 'LineWidth', 3);
    set(s.patch, 'FaceColor', colorWb);
    set(s.edge, 'Color', 'w');
    
    % yyaxis left;
    
%     for t = 1:length(trange)
%         cury = nanmedian(squeeze(nanmean(nanmean(threshChgTw(:,:,t,:),2),1)), 1);
%         curyrange = squeeze(nanmean(nanmean(threshChgTw(:,:,t,:),2),1));
%         er = errorbar(trange(t), cury, std(curyrange)/2, std(curyrange)/2);
%         p = plot(trange(t), cury, 'ok', 'linewidth', 2, 'markersize', 15, 'markerfacecolor', colorWb);
%         set(er, 'color', colorWb, 'linewidth', 2);
% 
%         cury = nanmedian(squeeze(nanmean(nanmean(threshChgTx(:,:,t,:),2),1)), 1);
%         curyrange = squeeze(nanmean(nanmean(threshChgTx(:,:,t,:),2),1));
%         er = errorbar(trange(t), cury, std(curyrange)/2, std(curyrange)/2);
%         plot(trange(t), cury, 'ok', 'linewidth', 2, 'markersize', 15, 'markerfacecolor', colorTxx);
%         set(er, 'color', colorTxx, 'linewidth', 2);
%     end
    
    yyaxis left;
    b = boxplot((squeeze(nanmean(nanmean(threshChgTw, 2), 1)))');

    ylim([0 10]);
    set(b, {'LineWidth', 'Color'}, {2, colorWb})
    lines = findobj(b, 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
    
    yyaxis right;
    b = boxplot((squeeze(nanmean(nanmean(threshChgTx, 2), 1)))');
    ylim([0 10]);
    
    ylim([1.75 5.4])
    xlim([-5 105]);
    set(gca, 'fontsize', 36);
    xlabel('Warm season percentile');
    set(gca, 'XTick', 5:10:95);
    ylabel(['Change (' char(176) 'C)']);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['txx-wb-dist-chg.png'], '-m5');
    close all;
end




