models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

load waterGrid.mat;
waterGrid = logical(waterGrid);

plotDistChg = false;
plotSlopes = true;
      
threshChgTw = [];
threshChgTx = [];
threshChgTwTx = [];
threshChgTxTw = [];

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
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-thresh-range-' num2str(t) '-wb-davies-jones-full-' models{m} '-rcp85-2061-2085-all-txx.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTw(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-thresh-range-' num2str(t) '-tasmax-' models{m} '-rcp85-2061-2085-warm-season.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTx(:, :, tind, m) = chgData;
        
        tind = tind+1;
    end
    
end

colorWb = [68, 166, 226]./255.0;
colorTxx = [216, 66, 19]./255.0;

slopesTxTw = [];
sigTxTw = [];
slopesTwTx = [];
sigTwTx = [];

for m = 1:length(models)
    for t = 1:10
        tx = reshape(threshChgTx(:, :, t, m), [numel(threshChgTx(:, :, t, m)), 1]);
        txtw = reshape(threshChgTxTw(:, :, t, m), [numel(threshChgTxTw(:, :, t, m)), 1]);
        
        nn = find(~isnan(tx) & ~isnan(txtw));
        tx = tx(nn);
        txtw = txtw(nn);
        
        f = fit(tx, txtw, 'poly1');
        slopesTwTx(m, t) = f.p1;
        c = confint(f);
        sigTwTx(m, t) = sign(c(1,1))==sign(c(2,1));
        
        tw = reshape(threshChgTw(:, :, t, m), [numel(threshChgTw(:, :, t, m)), 1]);
        twtx = reshape(threshChgTwTx(:, :, t, m), [numel(threshChgTwTx(:, :, t, m)), 1]);
        
        nn = find(~isnan(tw) & ~isnan(twtx));
        tw = tw(nn);
        twtx = twtx(nn);
        
        f = fit(twtx, tw, 'poly1');
        slopesTxTw(m, t) = f.p1;
        c = confint(f);
        sigTxTw(m, t) = sign(c(1,1))==sign(c(2,1));
    end
end

figure('Color', [1,1,1]);
hold on;
axis square;
grid on;
box on;

b = boxplot(slopesTwTx);

for bind = 1:size(b, 2)
    set(b(:,bind), {'LineWidth', 'Color'}, {2, colorTxx})
    lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
end
plot([0 100], [0 0], '--k', 'linewidth', 2);
xlabel('Warm season Tx percentile');
ylabel([char(176) 'C T_W per ' char(176) 'C Tx']);
set(gca, 'fontsize', 36);
set(gca, 'ytick', -.1:.1:.7);
set(gca, 'xticklabels', 5:10:95);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['tx-tw-tx-slopes.eps']);
close all;



figure('Color', [1,1,1]);
hold on;
axis square;
grid on;
box on;

b = boxplot(slopesTxTw);

for bind = 1:size(b, 2)
    set(b(:,bind), {'LineWidth', 'Color'}, {2, colorWb})
    lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
end

ylim([-.15 .4]);
set(gca, 'ytick', -.1:.1:.4);
plot([0 100], [0 0], '--k', 'linewidth', 2);
xlabel('Warm season T_W percentile');
ylabel([char(176) 'C T_W per ' char(176) 'C Tx']);
set(gca, 'fontsize', 36);
set(gca, 'xticklabels', 5:10:95);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['tx-tw-tw-slopes.eps']);
close all;

