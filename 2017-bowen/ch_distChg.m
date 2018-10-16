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
threshChgTx = [];
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
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-wb-davies-jones-full-' models{m} '-rcp85-2061-2085.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTw(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-percentile-chg-' num2str(t) '-tasmax-' models{m} '-rcp85-2061-2085.mat']);
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
    trange = [5:10:95 100];
    for t = 1:length(trange)
        cury = nanmedian(squeeze(nanmean(nanmean(threshChgTw(:,:,t,:),2),1)), 1);
        curyrange = squeeze(nanmean(nanmean(threshChgTw(:,:,t,:),2),1));
        er = errorbar(trange(t), cury, std(curyrange)/2, std(curyrange)/2);
        p = plot(trange(t), cury, 'ok', 'linewidth', 2, 'markersize', 15, 'markerfacecolor', colorWb);
        set(er, 'color', colorWb, 'linewidth', 2);

        cury = nanmedian(squeeze(nanmean(nanmean(threshChgTx(:,:,t,:),2),1)), 1);
        curyrange = squeeze(nanmean(nanmean(threshChgTx(:,:,t,:),2),1));
        er = errorbar(trange(t), cury, std(curyrange)/2, std(curyrange)/2);
        plot(trange(t), cury, 'ok', 'linewidth', 2, 'markersize', 15, 'markerfacecolor', colorTxx);
        set(er, 'color', colorTxx, 'linewidth', 2);
    end
    
    ylim([2 5.4])
    xlim([-5 105]);
    set(gca, 'fontsize', 36);
    xlabel('Warm season percentile');
    set(gca, 'XTick', 5:10:95);
    ylabel(['Change (' char(176) 'C)']);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['txx-wb-dist-chg.png'], '-m5');
    close all;
end




