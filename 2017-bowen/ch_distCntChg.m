models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

load waterGrid.mat;
waterGrid = logical(waterGrid);

plotDistChg = false;
      
threshChgTw27 = [];
threshChgTwNoTxAmp27 = [];
threshChgTw28 = [];
threshChgTwNoTxAmp28 = [];
threshChgTw29 = [];
threshChgTwNoTxAmp29 = [];
threshChgTw30 = [];
threshChgTwNoTxAmp30 = [];

for m = 1:length(models)
    tind = 1;
    for t = 5:10:95
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-tw-count-chg-no-tx-amp-pred-huss-' num2str(t) '-27-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTwNoTxAmp27(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-tw-count-chg-' num2str(t) '-27-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTw27(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-tw-count-chg-no-tx-amp-pred-huss-' num2str(t) '-28-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTwNoTxAmp28(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-tw-count-chg-' num2str(t) '-28-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTw28(:, :, tind, m) = chgData;
%         
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-tw-count-chg-no-tx-amp-pred-huss-' num2str(t) '-29-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTwNoTxAmp29(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-tw-count-chg-' num2str(t) '-29-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTw29(:, :, tind, m) = chgData;
%         
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-tw-count-chg-no-tx-amp-pred-huss-' num2str(t) '-30-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTwNoTxAmp30(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-tw-count-chg-' num2str(t) '-30-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTw30(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-tw-count-chg-no-tx-amp-pred-huss-' num2str(t) '-31-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTwNoTxAmp31(:, :, tind, m) = chgData;
        
        load(['E:\data\projects\bowen\temp-chg-data\chgData-cmip5-tw-count-chg-' num2str(t) '-31-tasmax-wb-davies-jones-full-' models{m} '-rcp85-2061-2085.mat']);
        chgData(waterGrid) = NaN;
        chgData(1:15,:) = NaN;
        chgData(75:90,:) = NaN;
        threshChgTw31(:, :, tind, m) = chgData;
        
        tind = tind+1;
    end
end

data27 = squeeze(sum(threshChgTw27,3))-squeeze(sum(threshChgTwNoTxAmp27,3));
data28 = squeeze(sum(threshChgTw28,3))-squeeze(sum(threshChgTwNoTxAmp28,3));
data29 = squeeze(sum(threshChgTw29,3))-squeeze(sum(threshChgTwNoTxAmp29,3));
data30 = squeeze(sum(threshChgTw30,3))-squeeze(sum(threshChgTwNoTxAmp30,3));
data31 = squeeze(sum(threshChgTw31,3))-squeeze(sum(threshChgTwNoTxAmp31,3));

colorWb = [68, 166, 226]./255.0;
colorTxx = [216, 66, 19]./255.0;

figure('Color', [1,1,1]);
hold on;
box on;
axis square;
grid on;

d27 = squeeze(nanmean(nanmean(data27)));
d28 = squeeze(nanmean(nanmean(data28)));
d29 = squeeze(nanmean(nanmean(data29)));
d30 = squeeze(nanmean(nanmean(data30)));
d31 = squeeze(nanmean(nanmean(data31)));

plot([0 100], [0 0], '--k', 'linewidth', 2);

b = boxplot([d27 d28 d29 d30 d31]);

for bind = 1:size(b, 2)
    set(b(:,bind), {'LineWidth', 'Color'}, {2, colorTxx})
    lines = findobj(b(:, bind), 'type', 'line', 'Tag', 'Median');
    set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);
end

xlim([.5 5.5]);
set(gca, 'fontsize', 36, 'xtick', [1 2 3 4 5], 'xticklabels', [27 28 29 30 31]);
ylabel('Change (# days per year)');
xlabel(['T_W threshold (' char(176) 'C)']);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['thresh-cnt-boxplots.eps']);
close all;


data = squeeze(sum(threshChgTw27,3))-squeeze(sum(threshChgTwNoTxAmp27,3));
plotData = [];
for xlat = 1:size(lat, 1)
    for ylon = 1:size(lat, 2)
        if waterGrid(xlat, ylon)
            plotData(xlat, ylon) = NaN;
            sigChg(xlat, ylon) = 0;
            continue;
        end
        med = nanmedian(data(xlat, ylon, :), 3);
        if ~isnan(med)
            plotData(xlat, ylon) = nanmedian(data(xlat, ylon, :), 3);
            sigChg(xlat, ylon) = length(find(sign(data(xlat, ylon, :)) == sign(plotData(xlat, ylon)))) < .66*size(data, 3);
        else
            sigChg(xlat, ylon) = 1;
        end
    end
end

sigChg(1:15,:) = 0;
sigChg(75:90,:) = 0;
plotData(1:15,:) = NaN;
plotData(75:90,:) = NaN;

result = {lat, lon, plotData};

saveData = struct('data', {result}, ...
                  'plotRegion', 'world', ...
                  'plotRange', [-10 10], ...
                  'cbXTicks', -10:2:10, ...
                  'plotTitle', [], ...
                  'fileTitle', ['tw-cnt-27-tx-amp.eps'], ...
                  'plotXUnits', ['# days per warm season above a T_W of 27' char(176) 'C'], ...
                  'blockWater', true, ...
                  'colormap', brewermap([],'*RdBu'), ...
                  'statData', sigChg);
plotFromDataFile(saveData);
