models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

load waterGrid.mat;
waterGrid = logical(waterGrid);
      
threshChgTw = [];
threshChgTx = [];
threshChgEf = [];

for m = 1:length(models)
    tind = 1;
    for t = 0:5:100
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-thresh-range-' num2str(t) '-wb-davies-jones-full-' models{m} '-rcp85-2061-2085-all-txx.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTw(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-thresh-range-' num2str(t) '-tasmax-' models{m} '-rcp85-2061-2085-all-txx.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTx(:, :, tind, m) = chgData;
        
        tind = tind+1;
    end
end

colorWb = [68, 166, 226]./255.0;
colorTxx = [216, 66, 19]./255.0;

threshChgEf(abs(threshChgEf)>1) = NaN;

figure('Color', [1,1,1]);
hold on;
axis square;
grid on;
box on;

% yyaxis left;
trange = 0:5:100;
for t = 1:length(trange)
    cury = squeeze(nanmean(nanmean(nanmedian(threshChgTw(:,:,t,:),4),2),1));
    curyrange = squeeze(nanmean(nanmean(threshChgTw(:,:,t,:),2),1));
    er = errorbar(trange(t), cury, std(curyrange)/2, std(curyrange)/2);
    plot(trange(t), cury, 'ok', 'linewidth', 2, 'markersize', 15, 'markerfacecolor', colorWb);
    set(er, 'color', colorWb, 'linewidth', 2);
    
    cury = squeeze(nanmean(nanmean(nanmedian(threshChgTx(:,:,t,:),4),2),1));
    curyrange = squeeze(nanmean(nanmean(threshChgTx(:,:,t,:),2),1));
    er = errorbar(trange(t), cury, std(curyrange)/2, std(curyrange)/2);
    plot(trange(t), cury, 'ok', 'linewidth', 2, 'markersize', 15, 'markerfacecolor', colorTxx);
    set(er, 'color', colorTxx, 'linewidth', 2);
end
% yyaxis right;
% plot(0:5:100, squeeze(nanmean(nanmean(nanmedian(threshChgEf,4),2),1)), 'ok', 'linewidth', 3);
% ylim([-.05 .05]);
ylim([2 5])
xlim([-5 105]);
set(gca, 'fontsize', 36);
xlabel('Percentile');
set(gca, 'XTick', [0 25 50 75 100]);
ylabel(['Change (' char(176) 'C)']);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['txx-wb-dist-chg.eps']);
close all;
