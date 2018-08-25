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

efOnTxx(abs(efOnTxx)>1) = NaN;

amp = wbChgWarmSeason;
driverRaw = efChgWarmSeason;
% amp = wbOnTxx;
% driverRaw = efOnTxx;

amp2 = [];%wbChgOnWb;
driverRaw2 = [];%efOnWb;

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
                b = plot(e+.1, dslopes(2, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', colorWb);
            elseif dslopesP(2, e, m) <= 0.05 && dslopes(2, e, m) > 0
                b = plot(e+.1, dslopes(2, e, m), 'ok', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', colorWb);
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
set(gca, 'FontSize', 40);
set(gca, 'XTick', 1:5, 'XTickLabel', {'Arid', 'Semi-arid', 'Temperate', 'Tropical', 'All'});
xtickangle(45);
ylabel([char(176) 'C / ' unit]);
%set(b,{'LineWidth', 'Color'},{2, [85/255.0, 158/255.0, 237/255.0]})
%lines = findobj(gcf, 'type', 'line', 'Tag', 'Median');
%set(lines, 'Color', [249, 153, 57]./255, 'LineWidth', 2);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['spatial-ef-wb-warm-season.eps']);
close all;
