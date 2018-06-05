models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

load lat;
load lon;

load waterGrid.mat;
waterGrid = logical(waterGrid);
      
txxChgOnTxx = [];
wbOnTxx = [];
hussOnTxx = [];
efOnTxx = [];

wbChgOnWb = [];
txxOnWb = [];
hussOnWb = [];
efOnWb = [];

wbChgWarmSeason = [];
txxChgWarmSeason = [];

sEfTxx = [];
pEfTxx = [];
sEfWb = [];
pEfWb = [];

for m = 1:length(models)
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txChgWarm-' models{m}]);
    txChgWarm(waterGrid) = NaN;
    txChgWarm(1:15,:) = NaN;
    txChgWarm(75:90,:) = NaN;
    txxChgWarmSeason(:, :, m) = txChgWarm;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txxChg-' models{m}]);
    txxChg(waterGrid) = NaN;
    txxChg(1:15,:) = NaN;
    txxChg(75:90,:) = NaN;
    txxChgOnTxx(:, :, m) = txxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/wbTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    wbTxxChg(waterGrid) = NaN;
    wbTxxChg(1:15,:) = NaN;
    wbTxxChg(75:90,:) = NaN;
    wbOnTxx(:,:,m) = wbTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/hussTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    hussTxxChg(waterGrid) = NaN;
    hussTxxChg(1:15,:) = NaN;
    hussTxxChg(75:90,:) = NaN;
    hussOnTxx(:,:,m) = hussTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/efTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    efTxxChg(waterGrid) = NaN;
    efTxxChg(1:15,:) = NaN;
    efTxxChg(75:90,:) = NaN;
    efOnTxx(:,:,m) = efTxxChg;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\wbChg-' models{m}]);
    wbChgOnWb(:, :, m) = wbChg;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\wbChgWarm-' models{m}]);
    wbChgWarmSeason(:, :, m) = wbChgWarm;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/tasmaxTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    txxOnWb(:,:,m) = tasmaxTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/hussTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    hussOnWb(:,:,m) = hussTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/efTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    efOnWb(:,:,m) = efTxxChg;
end

t = reshape(txxChgOnTxx,[numel(txxChgOnTxx),1]);
a = reshape(wbOnTxx,[numel(wbOnTxx),1]);
e = reshape(efOnTxx,[numel(efOnTxx),1]);
h = reshape(hussOnTxx,[numel(hussOnTxx),1]);

nn = find(isnan(e) | isnan(a) | isnan(h) | e>.5 | e < -.5);

a(nn)=[];
e(nn)=[];
h(nn)=[];
t(nn)=[];

cmap = 'Reds';
[ampSort,ind] = sort(a);
e = e(ind);
h = h(ind);
t = t(ind);
cmap = brewermap(200, cmap);
cmapRange = [2 5.5];

% loop over all models
colors = (ampSort-cmapRange(1)) ./ (cmapRange(2)-cmapRange(1));
colors(colors>1) = 1;
colors(colors<-1) = -1;
colors = round(colors*100)+100;
colors(colors==0)=1;
colors = cmap(colors,:);

figure('Color',[1,1,1]);
hold on;
box on;
axis square;
grid on;
scatter(e,h,15,colors,'filled');
xlabel('EF change (Fraction)');

xlim([-.5 .5]);
set(gca, 'XTick', -.5:.25:.5);

ylim([-.01 .015]);
set(gca, 'YTick', -.01:.005:.015);

ylabel('HUSS change (kg/kg)');
set(gca, 'FontSize', 36);

plot([-1 1], [0 0], '--k', 'LineWidth', 2);
plot([0 0], [-1 1], '--k', 'LineWidth', 2);


colormap(cmap);
caxis(cmapRange);
cb = colorbar();
ylabel(cb, 'T_{W} change on TXx day');

set(gcf, 'Position', get(0,'Screensize'));
export_fig(['ef-huss-wb-on-txx-scatter.eps']);
close all;

