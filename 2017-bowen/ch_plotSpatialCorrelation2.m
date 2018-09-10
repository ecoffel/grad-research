txxWarmAnom = true;

useWb = false;
var = 'huss';

load waterGrid.mat;
waterGrid = logical(waterGrid);

load lat;
load lon;

models = {'access1-0', 'access1-3', 'bcc-csm1-1-m', 'bnu-esm', ...
          'canesm2', 'cnrm-cm5', 'csiro-mk3-6-0', 'fgoals-g2', 'gfdl-esm2g', ...
          'gfdl-esm2m', 'hadgem2-cc', 'hadgem2-es', 'ipsl-cm5a-mr', ...
          'miroc5', 'mri-cgcm3', 'noresm1-m'};

showbar = false;

for m = 1:length(models)
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txxChg-' models{m}]);
    txxChgOnTxx(:, :, m) = txxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/wbTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    wbOnTxx(:,:,m) = wbTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/hussTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    hussOnTxx(:,:,m) = hussTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/efTxxChg-movingWarm-txxDays-' models{m} '.mat']);
    efOnTxx(:,:,m) = efTxxChg;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\wbChg-' models{m}]);
    wbChgOnWb(:, :, m) = wbChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/tasmaxTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    txxOnWb(:,:,m) = tasmaxTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/hussTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    hussOnWb(:,:,m) = hussTxxChg;
    
    load(['e:/data/projects/bowen/derived-chg/var-txx-amp/efTxxChg-movingWarm-wbDays-' models{m} '.mat']);
    efOnWb(:,:,m) = efTxxChg;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\txChgWarm-' models{m}]);
    txChgWarmSeason(:, :, m) = txChgWarm;
    
    load(['E:\data\projects\bowen\derived-chg\var-txx-amp\efWarmChg-movingWarm-' models{m}]);
    efChgWarmSeason(:, :, m) = efWarmChg;
    
    load(['E:\data\projects\bowen\derived-chg\var-txx-amp\hussWarmChg-movingWarm-' models{m}]);
    hussChgWarmSeason(:, :, m) = hussWarmChg;
    
    load(['E:\data\projects\bowen\derived-chg\txx-amp\wbChgWarm-' models{m}]);
    wbChgWarmSeason(:, :, m) = wbChgWarm;
end

efOnTxx(abs(efOnTxx)>.5) = NaN;
efOnWb(abs(efOnWb)>.5) = NaN;
efChgWarmSeason(abs(efChgWarmSeason)>.5) = NaN;

colorWarm = [160, 116, 46]./255.0;
colorHuss = [28, 165, 51]./255.0;
colorWb = [68, 166, 226]./255.0;
colorTxx = [216, 66, 19]./255.0;

regions = [[[-90 90], [0 360]]; ...             % world
           [[30 42], [-91 -75] + 360]; ...     % eastern us
           [[30 41], [-95 -75] + 360]; ...      % southeast us
           [[45, 55], [10, 35]]; ...            % Europe
           [[35 50], [-10+360 45]]; ...        % Med
           [[5 20], [-90 -45]+360]; ...         % Northern SA
           [[-10, 7], [-75, -62]+360]; ...      % Amazon
           [[-10 10], [15, 30]]; ...            % central africa
           [[15 30], [-4 29]]; ...              % north africa
           [[22 40], [105 122]]; ...               % china
           [[-24 -8], [14 40]]; ...                      % south africa
           [[-45 -25], [-65 -49]+360]];

region = 1;
[latInds, lonInds] = latLonIndexRange({lat, lon, []}, regions(region, [1 2]), regions(region, [3 4]));

if showbar 
    
for m = 1:length(models)

    load(['E:\data\projects\bowen\derived-chg\var-stats\efGroup-' models{m} '.mat']);
   
    efGroup(waterGrid) = NaN;
    efGroup(1:15,:) = NaN;
    efGroup(75:90,:) = NaN;
    efGroup =  reshape(efGroup, [numel(efGroup),1]);
    
    cureftxx = efOnTxx(:, :, m);
    cureftxx(waterGrid) = NaN;
    cureftxx(1:15,:) = NaN;
    cureftxx(75:90,:) = NaN;
    cureftxx =  reshape(cureftxx, [numel(cureftxx),1]);
    eftxx(:,m) = cureftxx;
    
    curefwb = efOnWb(:, :, m);
    curefwb(waterGrid) = NaN;
    curefwb(1:15,:) = NaN;
    curefwb(75:90,:) = NaN;
    curefwb =  reshape(curefwb, [numel(curefwb),1]);
    efwb(:,m) = curefwb;
    
    curefwarm = efChgWarmSeason(:, :, m);
    curefwarm(waterGrid) = NaN;
    curefwarm(1:15,:) = NaN;
    curefwarm(75:90,:) = NaN;
    curefwarm =  reshape(curefwarm, [numel(curefwarm),1]);
    efwarm(:,m) = curefwarm;
    
    curhusstxx = hussOnTxx(:, :, m);
    curhusstxx(waterGrid) = NaN;
    curhusstxx(1:15,:) = NaN;
    curhusstxx(75:90,:) = NaN;
    curhusstxx =  reshape(curhusstxx, [numel(curhusstxx),1]);
    husstxx(:,m) = curhusstxx;
    
    curhusswb = hussOnWb(:, :, m);
    curhusswb(waterGrid) = NaN;
    curhusswb(1:15,:) = NaN;
    curhusswb(75:90,:) = NaN;
    curhusswb =  reshape(curhusswb, [numel(curhusswb),1]);
    husswb(:,m) = curhusswb;
    
    curhusswarm = hussChgWarmSeason(:, :, m);
    curhusswarm(waterGrid) = NaN;
    curhusswarm(1:15,:) = NaN;
    curhusswarm(75:90,:) = NaN;
    curhusswarm =  reshape(curhusswarm, [numel(curhusswarm),1]);
    husswarm(:,m) = curhusswarm;
    
    curwbtxx = wbOnTxx(:, :, m);
    curwbtxx(waterGrid) = NaN;
    curwbtxx(1:15,:) = NaN;
    curwbtxx(75:90,:) = NaN;
    curwbtxx =  reshape(curwbtxx, [numel(curwbtxx),1]);
    wbtxx(:,m) = curwbtxx;
    
    curwbwb = wbChgOnWb(:, :, m);
    curwbwb(waterGrid) = NaN;
    curwbwb(1:15,:) = NaN;
    curwbwb(75:90,:) = NaN;
    curwbwb =  reshape(curwbwb, [numel(curwbwb),1]);
    wbwb(:,m) = curwbwb;
    
    curwbwarm = wbChgWarmSeason(:, :, m);
    curwbwarm(waterGrid) = NaN;
    curwbwarm(1:15,:) = NaN;
    curwbwarm(75:90,:) = NaN;
    curwbwarm =  reshape(curwbwarm, [numel(curwbwarm),1]);
    wbwarm(:,m) = curwbwarm;
    
    curtxxtxx = txxChgOnTxx(:, :, m);
    curtxxtxx(waterGrid) = NaN;
    curtxxtxx(1:15,:) = NaN;
    curtxxtxx(75:90,:) = NaN;
    curtxxtxx =  reshape(curtxxtxx, [numel(curtxxtxx),1]);
    txxtxx(:,m) = curtxxtxx;
    
    curtxxwb = txxOnWb(:, :, m);
    curtxxwb(waterGrid) = NaN;
    curtxxwb(1:15,:) = NaN;
    curtxxwb(75:90,:) = NaN;
    curtxxwb =  reshape(curtxxwb, [numel(curtxxwb),1]);
    txxwb(:,m) = curtxxwb;
    
    curtxxwarm = txChgWarmSeason(:, :, m);
    curtxxwarm(waterGrid) = NaN;
    curtxxwarm(1:15,:) = NaN;
    curtxxwarm(75:90,:) = NaN;
    curtxxwarm =  reshape(curtxxwarm, [numel(curtxxwarm),1]);
    txxwarm(:,m) = curtxxwarm;
end

names = {'Arid', 'Semi-arid', 'Temperate', 'Tropical', 'All'};

for e = 1:5

    % all ef vals
    if e == 5
        nn = 1:length(efGroup);
    else
        % others
        nn = find(efGroup == e);
    end
    
    cureftxx = squeeze(nanmean(eftxx(nn,:),1));
    curefwb = squeeze(nanmean(efwb(nn,:),1));
    curefwarm = squeeze(nanmean(efwarm(nn,:),1));
    curhusstxx = squeeze(nanmean(husstxx(nn,:),1));
    curhusswb = squeeze(nanmean(husswb(nn,:),1));
    curhusswarm = squeeze(nanmean(husswarm(nn,:),1));
    curwbtxx = squeeze(nanmean(wbtxx(nn,:),1));
    curwbwb = squeeze(nanmean(wbwb(nn,:),1));
    curwbwarm = squeeze(nanmean(wbwarm(nn,:),1));
    curtxxtxx = squeeze(nanmean(txxtxx(nn,:),1));
    curtxxwb = squeeze(nanmean(txxwb(nn,:),1));
    curtxxwarm = squeeze(nanmean(txxwarm(nn,:),1));
    
    fig = figure('Color', [1,1,1]);
    set(fig,'defaultAxesColorOrder',[colorTxx; colorHuss]);
    hold on;
    box on;
    axis square;
    grid on;
    yyaxis left;
    
    b = bar([1 5 9], [nanmedian(curtxxtxx) nanmedian(curtxxwarm) nanmedian(curtxxwb)], .25, 'k');
    set(b, 'facecolor', colorTxx, 'linewidth', 2);
    er = errorbar(1, nanmedian(curtxxtxx), nanmedian(curtxxtxx)-min(curtxxtxx), max(curtxxtxx)-nanmedian(curtxxtxx));
    set(er, 'color', 'k', 'linewidth', 2);
    er = errorbar(5, nanmedian(curtxxwarm), nanmedian(curtxxwarm)-min(curtxxwarm), max(curtxxwarm)-nanmedian(curtxxwarm));
    set(er, 'color', 'k', 'linewidth', 2);
    er = errorbar(9, nanmedian(curtxxwb), nanmedian(curtxxwb)-min(curtxxwb), max(curtxxwb)-nanmedian(curtxxwb));
    set(er, 'color', 'k', 'linewidth', 2);
    
    
    b = bar([3 7 11], [nanmedian(curwbtxx) nanmedian(curwbwarm) nanmedian(curwbwb)], .25, 'k');
    set(b, 'facecolor', colorWb, 'linewidth', 2);
    er = errorbar(3, nanmedian(curwbtxx), nanmedian(curwbtxx)-min(curwbtxx), max(curwbtxx)-nanmedian(curwbtxx));
    set(er, 'color', 'k', 'linewidth', 2, 'markersize', .01);
    er = errorbar(7, nanmedian(curwbwarm), nanmedian(curwbwarm)-min(curwbwarm), max(curwbwarm)-nanmedian(curwbwarm));
    set(er, 'color', 'k', 'linewidth', 2, 'markersize', .01);
    er = errorbar(11, nanmedian(curwbwb), nanmedian(curwbwb)-min(curwbwb), max(curwbwb)-nanmedian(curwbwb));
    set(er, 'color', 'k', 'linewidth', 2, 'markersize', .01);
    
    
    ylabel(['Temperature change (' char(176) 'C)']);
    ylim([0 13]);
    yyaxis right;
    b = bar([2 6 10], [nanmedian(curhusstxx) nanmedian(curhusswarm) nanmedian(curhusswb)], .25, 'k');
    set(b, 'facecolor', colorHuss, 'linewidth', 2);
    er = errorbar(2, nanmedian(curhusstxx), nanmedian(curhusstxx)-min(curhusstxx), max(curhusstxx)-nanmedian(curhusstxx));
    set(er, 'color', 'k', 'linewidth', 2, 'markersize', .01);
    er = errorbar(6, nanmedian(curhusswarm), nanmedian(curhusswarm)-min(curhusswarm), max(curhusswarm)-nanmedian(curhusswarm));
    set(er, 'color', 'k', 'linewidth', 2, 'markersize', .01);
    er = errorbar(10, nanmedian(curhusswb), nanmedian(curhusswb)-min(curhusswb), max(curhusswb)-nanmedian(curhusswb));
    set(er, 'color', 'k', 'linewidth', 2, 'markersize', .01);
    
    ylabel('Specific humidity change (g/kg)');
    set(gca, 'XTick', [2 6 10], 'XTickLabels', {'TXx day', 'Warm season', 'T_W day'});
    ylim([0 7e-3]);
    set(gca, 'YTick', 1e-3 .* [0:7], 'YTickLabels', 0:7);
    xtickangle(45);
    set(gca, 'fontsize', 30);
    title(names{e}, 'fontsize', 36);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig(['ef-wb-txx-chg-bar-' num2str(e) '.eps']);
    close all;
    
%     figure('Color', [1,1,1]);
%     hold on;
%     box on;
%     axis square;
%     grid on;
%     er = errorbar(nanmedian(curwbwb), nanmedian(curefwb), nanmedian(curefwb)-min(curefwb), max(curefwb)-nanmedian(curefwb), nanmedian(curwbwb)-min(curwbwb), max(curwbwb)-nanmedian(curwbwb));
%     set(er, 'color', colorWb, 'linewidth', 2);
%     plot(nanmedian(curwbwb), nanmedian(curefwb), 'ok', 'markersize', 15, 'markerfacecolor', colorWb, 'linewidth', 2);
% 
%     er = errorbar(nanmedian(curwbtxx), nanmedian(cureftxx), nanmedian(cureftxx)-min(cureftxx), max(cureftxx)-nanmedian(cureftxx), nanmedian(curwbtxx)-min(curwbtxx), max(curwbtxx)-nanmedian(curwbtxx));
%     set(er, 'color', colorTxx, 'linewidth', 2);
%     plot(nanmedian(curwbtxx), nanmedian(cureftxx), 'ok', 'markersize', 15, 'markerfacecolor', colorTxx, 'linewidth', 2);
% 
%     er = errorbar(nanmedian(curwbwarm), nanmedian(curefwarm), nanmedian(curefwarm)-min(curefwarm), max(curefwarm)-nanmedian(curefwarm), nanmedian(curwbwarm)-min(curwbwarm), max(curwbwarm)-nanmedian(curwbwarm));
%     set(er, 'color', colorWarm, 'linewidth', 2);
%     plot(nanmedian(curwbwarm), nanmedian(curefwarm), 'ok', 'markersize', 15, 'markerfacecolor', colorWarm, 'linewidth', 2);
% 
%     er = errorbar(nanmedian(curtxxwb), nanmedian(curefwb), nanmedian(curefwb)-min(curefwb), max(curefwb)-nanmedian(curefwb), nanmedian(curtxxwb)-min(curtxxwb), max(curtxxwb)-nanmedian(curtxxwb));
%     set(er, 'color', colorWb, 'linewidth', 2, 'linestyle', '--');
%     plot(nanmedian(curtxxwb), nanmedian(curefwb), 'sk', 'markersize', 15, 'markerfacecolor', colorWb, 'linewidth', 2);
% 
%     er = errorbar(nanmedian(curtxxtxx), nanmedian(cureftxx), nanmedian(cureftxx)-min(cureftxx), max(cureftxx)-nanmedian(cureftxx), nanmedian(curtxxtxx)-min(curtxxtxx), max(curtxxtxx)-nanmedian(curtxxtxx));
%     set(er, 'color', colorTxx, 'linewidth', 2, 'linestyle', '--');
%     plot(nanmedian(curtxxtxx), nanmedian(cureftxx), 'sk', 'markersize', 15, 'markerfacecolor', colorTxx, 'linewidth', 2);
% 
%     er = errorbar(nanmedian(curtxxwarm), nanmedian(curefwarm), nanmedian(curefwarm)-min(curefwarm), max(curefwarm)-nanmedian(curefwarm), nanmedian(curtxxwarm)-min(curtxxwarm), max(curtxxwarm)-nanmedian(curtxxwarm));
%     set(er, 'color', colorWarm, 'linewidth', 2, 'linestyle', '--');
%     plot(nanmedian(curtxxwarm), nanmedian(curefwarm), 'sk', 'markersize', 15, 'markerfacecolor', colorWarm, 'linewidth', 2);
% 
%     
%     title(names{e});
%     xlabel(['Temperature change (' char(176) 'C)']);
%     ylabel('EF change (Fraction)');
%     set(gca, 'XTick', 0:2:12);
%     set(gca, 'FontSize', 40);
%     xlim([0 12]);
%     ylim([-.1 .1]);
%     set(gcf, 'Position', get(0,'Screensize'));
%     export_fig(['ef-wb-txx-chg-' num2str(e) '.eps']);
%     close all;
% 
%     figure('Color', [1,1,1]);
%     hold on;
%     box on;
%     axis square;
%     grid on;
%     er = errorbar(nanmedian(curtxxwb), nanmedian(curefwb), nanmedian(curefwb)-min(curefwb), max(curefwb)-nanmedian(curefwb), nanmedian(curtxxwb)-min(curtxxwb), max(curtxxwb)-nanmedian(curtxxwb));
%     set(er, 'color', colorWb, 'linewidth', 2);
%     plot(nanmedian(curtxxwb), nanmedian(curefwb), 'ok', 'markersize', 15, 'markerfacecolor', colorWb, 'linewidth', 2);
% 
%     er = errorbar(nanmedian(curtxxtxx), nanmedian(cureftxx), nanmedian(cureftxx)-min(cureftxx), max(cureftxx)-nanmedian(cureftxx), nanmedian(curtxxtxx)-min(curtxxtxx), max(curtxxtxx)-nanmedian(curtxxtxx));
%     set(er, 'color', colorTxx, 'linewidth', 2);
%     plot(nanmedian(curtxxtxx), nanmedian(cureftxx), 'ok', 'markersize', 15, 'markerfacecolor', colorTxx, 'linewidth', 2);
% 
%     er = errorbar(nanmedian(curtxxwarm), nanmedian(curefwarm), nanmedian(curefwarm)-min(curefwarm), max(curefwarm)-nanmedian(curefwarm), nanmedian(curtxxwarm)-min(curtxxwarm), max(curtxxwarm)-nanmedian(curtxxwarm));
%     set(er, 'color', colorWarm, 'linewidth', 2);
%     plot(nanmedian(curtxxwarm), nanmedian(curefwarm), 'ok', 'markersize', 15, 'markerfacecolor', colorWarm, 'linewidth', 2);
% 
%     title(names{e});
%     xlabel(['TXx change (' char(176) 'C)']);
%     ylabel('EF change (Fraction)');
%     set(gca, 'XTick', 1.5:7);
%     set(gca, 'FontSize', 40);
%     xlim([1.5 7]);
%     ylim([-.07 .03]);
%     set(gcf, 'Position', get(0,'Screensize'));
%     export_fig(['ef-txx-chg-' num2str(e) '.eps']);
%     close all;
end
end
    
    
    
% eftxx = squeeze(nanmean(nanmean(efOnTxx(latInds, lonInds, :), 2), 1));
% efwb = squeeze(nanmean(nanmean(efOnWb(latInds, lonInds, :), 2), 1));
% efwarm = squeeze(nanmean(nanmean(efChgWarmSeason(latInds, lonInds, :), 2), 1));
% wbtxx = squeeze(nanmean(nanmean(wbOnTxx(latInds, lonInds, :), 2), 1));
% wbwb = squeeze(nanmean(nanmean(wbChgOnWb(latInds, lonInds, :), 2), 1));
% wbwarm = squeeze(nanmean(nanmean(wbChgWarmSeason(latInds, lonInds, :), 2), 1));
% txxtxx = squeeze(nanmean(nanmean(txxChgOnTxx(latInds, lonInds, :), 2), 1));
% txxwb = squeeze(nanmean(nanmean(txxOnWb(latInds, lonInds, :), 2), 1));
% txxwarm = squeeze(nanmean(nanmean(txChgWarmSeason(latInds, lonInds, :), 2), 1));

% figure('Color', [1,1,1]);
% hold on;
% box on;
% axis square;
% grid on;
% e = errorbar(nanmedian(wbwb), nanmedian(efwb), nanmedian(efwb)-min(efwb), max(efwb)-nanmedian(efwb), nanmedian(wbwb)-min(wbwb), max(wbwb)-nanmedian(wbwb));
% set(e, 'color', colorWb, 'linewidth', 2);
% plot(nanmedian(wbwb), nanmedian(efwb), 'ok', 'markersize', 15, 'markerfacecolor', colorWb, 'linewidth', 2);
% 
% e = errorbar(nanmedian(wbtxx), nanmedian(eftxx), nanmedian(eftxx)-min(eftxx), max(eftxx)-nanmedian(eftxx), nanmedian(wbtxx)-min(wbtxx), max(wbtxx)-nanmedian(wbtxx));
% set(e, 'color', colorTxx, 'linewidth', 2);
% plot(nanmedian(wbtxx), nanmedian(eftxx), 'ok', 'markersize', 15, 'markerfacecolor', colorTxx, 'linewidth', 2);
% 
% e = errorbar(nanmedian(wbwarm), nanmedian(efwarm), nanmedian(efwarm)-min(efwarm), max(efwarm)-nanmedian(efwarm), nanmedian(wbwarm)-min(wbwarm), max(wbwarm)-nanmedian(wbwarm));
% set(e, 'color', colorWarm, 'linewidth', 2);
% plot(nanmedian(wbwarm), nanmedian(efwarm), 'ok', 'markersize', 15, 'markerfacecolor', colorWarm, 'linewidth', 2);
% 
% title('Global');
% xlabel(['T_W change (' char(176) 'C)']);
% ylabel('EF change (Fraction)');
% set(gca, 'XTick', 1.5:1:7);
% set(gca, 'FontSize', 40);
% xlim([1.5 7]);
% ylim([-.07 .03]);
% set(gcf, 'Position', get(0,'Screensize'));
% export_fig(['ef-wb-chg-global.eps']);
% close all;
% 
% figure('Color', [1,1,1]);
% hold on;
% box on;
% axis square;
% grid on;
% e = errorbar(nanmedian(txxwb), nanmedian(efwb), nanmedian(efwb)-min(efwb), max(efwb)-nanmedian(efwb), nanmedian(txxwb)-min(txxwb), max(txxwb)-nanmedian(txxwb));
% set(e, 'color', colorWb, 'linewidth', 2);
% plot(nanmedian(txxwb), nanmedian(efwb), 'ok', 'markersize', 15, 'markerfacecolor', colorWb, 'linewidth', 2);
% 
% e = errorbar(nanmedian(txxtxx), nanmedian(eftxx), nanmedian(eftxx)-min(eftxx), max(eftxx)-nanmedian(eftxx), nanmedian(txxtxx)-min(txxtxx), max(txxtxx)-nanmedian(txxtxx));
% set(e, 'color', colorTxx, 'linewidth', 2);
% plot(nanmedian(txxtxx), nanmedian(eftxx), 'ok', 'markersize', 15, 'markerfacecolor', colorTxx, 'linewidth', 2);
% 
% e = errorbar(nanmedian(txxwarm), nanmedian(efwarm), nanmedian(efwarm)-min(efwarm), max(efwarm)-nanmedian(efwarm), nanmedian(txxwarm)-min(txxwarm), max(txxwarm)-nanmedian(txxwarm));
% set(e, 'color', colorWarm, 'linewidth', 2);
% plot(nanmedian(txxwarm), nanmedian(efwarm), 'ok', 'markersize', 15, 'markerfacecolor', colorWarm, 'linewidth', 2);
% 
% title('Global');
% xlabel(['TXx change (' char(176) 'C)']);
% ylabel('EF change (Fraction)');
% set(gca, 'XTick', 1.5:7);
% set(gca, 'FontSize', 40);
% xlim([1.5 7]);
% ylim([-.07 .03]);
% set(gcf, 'Position', get(0,'Screensize'));
% export_fig(['ef-txx-chg-global.eps']);
% close all;
% 
% wbwblin = reshape(nanmedian(wbChgOnWb, 3), [numel(nanmedian(wbChgOnWb, 3)), 1]);
% efwblin = reshape(nanmedian(efOnWb, 3), [numel(nanmedian(efOnWb, 3)), 1]);
% ind = find(~isnan(wbwblin) & ~isnan(efwblin));
% wbwblin = wbwblin(ind);
% efwblin = efwblin(ind);
% 
% fwb = fit(wbwblin, efwblin, 'poly1');
% plot([min(wbwb) max(wbwb)], [fwb(min(wbwb)) fwb(max(wbwb))], '--', 'Color', colorWb);
% 
% wbtxxlin = reshape(nanmedian(wbOnTxx, 3), [numel(nanmedian(wbOnTxx, 3)), 1]);
% eftxxlin = reshape(nanmedian(efOnTxx, 3), [numel(nanmedian(efOnTxx, 3)), 1]);
% ind = find(~isnan(wbtxxlin) & ~isnan(eftxxlin));
% wbtxxlin = wbtxxlin(ind);
% eftxxlin = eftxxlin(ind);
% 
% ftxx = fit(wbtxxlin, eftxxlin, 'poly1');
% plot([nanmedian(wbtxx)-1 nanmedian(wbtxx)+1], [ftxx(nanmedian(wbtxx)-1) ftxx(nanmedian(wbtxx)+1)], '--', 'Color', colorTxx);
% 
% wbwarmlin = reshape(nanmedian(wbChgWarmSeason, 3), [numel(nanmedian(wbChgWarmSeason, 3)), 1]);
% efwarmlin = reshape(nanmedian(efChgWarmSeason, 3), [numel(nanmedian(efChgWarmSeason, 3)), 1]);
% ind = find(~isnan(wbwarmlin) & ~isnan(efwarmlin));
% wbwarmlin = wbwarmlin(ind);
% efwarmlin = efwarmlin(ind);
% 
% fwarm = fit(wbwarmlin, efwarmlin, 'poly1');
% plot([min(wbwarm) max(wbwarm)], [fwarm(min(wbwarm)) fwarm(max(wbwarm))], '--', 'Color', colorWarm);

amp = wbChgWarmSeason;
driverRaw = efChgWarmSeason;
% amp = wbOnTxx;
% driverRaw = efOnTxx;

amp2 = txChgWarmSeason;
driverRaw2 = efChgWarmSeason;

unit = 'unit EF';

rind = 1;
efind = 1;
dslopes = [];
dslopesP = [];

dchg = [];

for m = 1:length(models)

   load(['E:\data\projects\bowen\derived-chg\var-stats\efGroup-' models{m} '.mat']);

    a = squeeze(amp(:,:,m));
    a(waterGrid) = NaN;
    a(1:15,:) = NaN;
    a(75:90,:) = NaN;
    a = reshape(a, [numel(a),1]);

    driver = squeeze(driverRaw(:,:,m));
    driver(waterGrid) = NaN;
    driver(1:15,:) = NaN;
    driver(75:90,:) = NaN;
    driver = reshape(driver, [numel(driver),1]);
    
    if length(amp2) > 0
        a2 = squeeze(amp2(:,:,m));
        a2(waterGrid) = NaN;
        a2(1:15,:) = NaN;
        a2(75:90,:) = NaN;
        a2 = reshape(a2, [numel(a2),1]);

        driver2 = squeeze(driverRaw2(:,:,m));
        driver2(waterGrid) = NaN;
        driver2(1:15,:) = NaN;
        driver2(75:90,:) = NaN;
        driver2 = reshape(driver2, [numel(driver2),1]);
    end

    efGroup(waterGrid) = NaN;
    efGroup(1:15,:) = NaN;
    efGroup(75:90,:) = NaN;
    efGroup =  reshape(efGroup, [numel(efGroup),1]);

    if length(amp2) > 0
        nn = find(isnan(a) | isnan(driver) | isnan(a2) | isnan(driver2));
        driver2(nn) = [];
        aDriver2 = a2;
        aDriver2(nn) = [];
    else
        nn = find(isnan(a) | isnan(driver));
    end

    driver(nn) = [];
    aDriver = a;
    aDriver(nn) = [];

    efGroup(nn) = [];

    for e = 1:5

        % all ef vals
        if e == 5
            nn = 1:length(driver);
        else
            % others
            nn = find(efGroup == e);
        end

        curDriver = driver(nn);
        curADriver = aDriver(nn);
        
        dchg(1, e, m) = nanmean(curADriver);

        f = fitlm(curDriver, curADriver, 'linear');
        dslopes(1, e, m) = f.Coefficients.Estimate(2);
        dslopesP(1, e, m) = f.Coefficients.pValue(2); 
        
        if length(amp2) > 0
            curDriver = driver2(nn);
            curADriver = aDriver2(nn);

            dchg(2, e, m) = nanmean(curADriver);

            f = fitlm(curDriver, curADriver, 'linear');
            dslopes(2, e, m) = f.Coefficients.Estimate(2);
            dslopesP(2, e, m) = f.Coefficients.pValue(2); 
        end

    end

end

txxslopes=squeeze(dslopes(1,5,:));
txxp=squeeze(dslopesP(1,5,:));
if length(amp2) > 0
    wbslopes=squeeze(dslopes(2,5,:))
    wbp=squeeze(dslopesP(2,5,:));
end
% 
% figure('Color',[1,1,1]);
% hold on; 
% axis square;
% box on;
% grid on;
% for m = 1:length(txxslopes)
%     t = text(txxslopes(m), wbslopes(m), num2str(m), 'HorizontalAlignment', 'center', 'Color', 'k');
%     t.FontSize = 26;
% end
% set(gca, 'XDir', 'reverse')
% xlim([-15 3])
% ylim([-3 15])
% set(gca, 'XTick', [-15 -10 -5 0 3]);
% xlabel(['TXx ' char(176) 'C / unit EF']);
% ylabel(['T_{W} ' char(176) 'C / unit EF']);
% set(gca, 'YTick', [-3 0 5 10 15]);
% plot([3 -15], [-3 15], '--k')
% set(gca, 'FontSize', 36);
% set(gcf, 'Position', get(0,'Screensize'));
% export_fig(['ef-txx-wb-slope-scatter.eps']);
% close all;


%dslopes = squeeze(dslopes);
%dslopesP = squeeze(dslopesP);

% [f,gof] = fit((1:4)', nanmedian(dslopes(1:4,:),2), 'poly3');
% fx = 1:.1:4;
% fy = f(fx);

figure('Color',[1,1,1]);
hold on;
grid on;
axis square;
box on;
%b = boxplot(dslopes','positions',1:5);

colorTxx = [160, 116, 46]./255.0;
colorWb = [68, 166, 226]./255.0;

for e = 1:size(dslopes,2)
    for m = 1:size(dslopes,3)
        
        displacement = 0;
        if length(amp2) > 0
            displacement = -.1;
        end
        
        if dslopesP(1, e, m) <= 0.05 && dslopes(1, e, m) < 0
            b = plot(e+displacement, dslopes(1, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', colorWb);
        elseif dslopesP(1, e, m) <= 0.05 && dslopes(1, e, m) > 0
            b = plot(e+displacement, dslopes(1, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', colorWb);
        else
            b = plot(e+displacement, dslopes(1, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2);
        end
        
        if length(amp2) > 0
            if dslopesP(2, e, m) <= 0.05 && dslopes(2, e, m) < 0
                b = plot(e+.1, dslopes(2, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', colorTxx);
            elseif dslopesP(2, e, m) <= 0.05 && dslopes(2, e, m) > 0
                b = plot(e+.1, dslopes(2, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', colorTxx);
            else
                b = plot(e+.1, dslopes(2, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2);
            end
        end
    end
    
    if length(amp2) > 0
        b = plot([e-.2 e], [squeeze(nanmean(dslopes(1, e,:),3)) squeeze(nanmean(dslopes(1, e,:),3))], '-b', 'Color', [224, 76, 60]./255, 'LineWidth', 3);
        b = plot([e-.2 e], [squeeze(nanmedian(dslopes(1, e,:),3)) squeeze(nanmedian(dslopes(1, e,:),3))], '-r', 'Color', [44, 158, 99]./255, 'LineWidth', 3);

        b = plot([e e+.2], [squeeze(nanmean(dslopes(2, e,:),3)) squeeze(nanmean(dslopes(2, e,:),3))], '-b', 'Color', [224, 76, 60]./255, 'LineWidth', 3);
        b = plot([e e+.2], [squeeze(nanmedian(dslopes(2, e,:),3)) squeeze(nanmedian(dslopes(2, e,:),3))], '-r', 'Color', [44, 158, 99]./255, 'LineWidth', 3);
    else
        b = plot([e-.1 e+.1], [squeeze(nanmean(dslopes(1, e,:),3)) squeeze(nanmean(dslopes(1, e,:),3))], '-b', 'Color', [224, 76, 60]./255, 'LineWidth', 3);
        b = plot([e-.1 e+.1], [squeeze(nanmedian(dslopes(1, e,:),3)) squeeze(nanmedian(dslopes(1, e,:),3))], '-r', 'Color', [44, 158, 99]./255, 'LineWidth', 3);
    end
end

plot([0 6], [0 0], '--k');
%plot(fx, fy, '--k', 'LineWidth', 2, 'Color', [.5 .5 .5]);
%ylim(yrange);
%set(gca, 'YTick', yticks);
xlim([.5 5.5]);
ylim([-25 40]);
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:5, 'XTickLabel', {'Arid', 'Semi-arid', 'Temperate', 'Tropical', 'All'});
xtickangle(45);
ylabel([char(176) 'C / ' unit]);
%set(b,{'LineWidth', 'Color'},{2, [85/255.0, 158/255.0, 237/255.0]})
%lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
%set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['spatial-ef-wb-tx-warm-season.eps']);
close all;
