 
wars = [[1973 1974]; ...
        [1974 1975]; ...        % 
        [1977 1979]; ...
        [1982 1983]; ...
        [1984 1986];    ...    % resettlement of 1.5M peasants
        [1991 1992]; ...
        [1998 2000]; ...
        [2006 2009]];

if ~exist('udelp')
    udelp = loadMonthlyData('E:\data\udel\output\precip\monthly\1900-2014', 'precip', 'startYear', 1961, 'endYear', 2014);
    udelp = {udelp{1}, udelp{2}, flipud(udelp{3})};
    udelt = loadMonthlyData('E:\data\udel\output\air\monthly\1900-2014', 'air', 'startYear', 1961, 'endYear', 2014);
    udelt = {udelt{1}, udelt{2}, flipud(udelt{3})};
    
    load nile-super-ensemble-blue.mat;
    superTDatasets = superEnsemble{1};
    superTPrc = superEnsemble{2};
    superPDatasets = superEnsemble{3};
    superPPrc = superEnsemble{4};
    
    superT = [];
    superP = [];
    
    ind = 1;
    for t = 1:size(superTDatasets, 2)
        for p = 1:size(superPDatasets, 2)
            superT(:, ind) = superTDatasets(:, t);
            superP(:, ind) = superPDatasets(:, p);
            ind = ind+1;
        end
    end
end

lat=udelt{1};
lon=udelt{2};

[regionInds, regions, regionNames] = ni_getRegions();
regionBoundsBlue = regions('nile-blue');

[latIndsBlueUdel, lonIndsBlueUdel] = latLonIndexRange({lat, lon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));

pdataset = squeeze(nanmean(nanmean(nansum(udelp{3}(latIndsBlueUdel, lonIndsBlueUdel, :, :), 4), 2), 1));
tdataset = squeeze(nanmean(nanmean(nanmean(udelt{3}(latIndsBlueUdel, lonIndsBlueUdel, :, :), 4), 2), 1));

load 2017-nile-climate\output\gldas_qs.mat
load 2017-nile-climate\output\gldas_qsb.mat
load 2017-nile-climate\output\gldas_pr.mat
load 2017-nile-climate\output\gldas_t.mat

latGldas = gldas_t{1};
lonGldas = gldas_t{2};
[latIndsBlueGldas, lonIndsBlueGldas] = latLonIndexRange({latGldas, lonGldas,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));

gldasRunoff = gldas_qs{3}(:, :, :, :) + gldas_qsb{3}(:, :, :, :);
gldasRunoff = squeeze(nanmean(nanmean(nansum(gldasRunoff(latIndsBlueGldas, lonIndsBlueGldas,:,:),4),2),1));
gldasT = squeeze(nanmean(nanmean(nanmean(gldas_t{3}(latIndsBlueGldas, lonIndsBlueGldas,:,:),4),2),1));
gldasPr = squeeze(nanmean(nanmean(nanmean(gldas_pr{3}(latIndsBlueGldas, lonIndsBlueGldas,:,:),4),2),1));

thresh = 0:5:100;

prcTUdel = prctile(tdataset(1:40), thresh);
prcPUdel = prctile(pdataset(1:40), thresh);

prcTGldas = prctile(gldasT(1:40), thresh);
prcPGldas = prctile(gldasPr(1:40), thresh);
prcRGldas = prctile(gldasRunoff(1:40), thresh);

annualPPrc = [];
annualTPrc = [];

for y = 1:length(pdataset)
    prc = find(abs(pdataset(y)-prcPUdel) == min(abs(pdataset(y)-prcPUdel)));
    annualPPrc(y, 1) = thresh(prc);
    
    prc = find(abs(tdataset(y)-prcTUdel) == min(abs(tdataset(y)-prcTUdel)));
    annualTPrc(y, 1) = thresh(prc);
end

annualPPrcSuper = [];
annualTPrcSuper = [];

prcTSuper = [];
for d = 1:size(superT, 2)
    prcTSuper(:,d) = prctile(superT(:,d), thresh);
end

prcPSuper = [];
for d = 1:size(superP, 2)
    prcPSuper(:,d) = prctile(superP(:,d), thresh);
end

for y = 1:size(superT, 1)
    for d = 1:size(superT, 2)
        prc = find(abs(superT(y, d)-prcTSuper(:,d)) == min(abs(superT(y, d)-prcTSuper(:,d))));
        annualTPrcSuper(y, d) = thresh(prc);
    end
end

for y = 1:size(superP, 1)
    for d = 1:size(superP, 2)
        prc = find(abs(superP(y, d)-prcPSuper(:,d)) == min(abs(superP(y, d)-prcPSuper(:,d))));
        annualPPrcSuper(y, d) = thresh(prc);
    end
end

annualPPrcGldas = [];
annualTPrcGldas = [];
annualRPrcGldas = [];

for y = 1:length(gldasT)
    prc = find(abs(gldasT(y)-prcTGldas) == min(abs(gldasT(y)-prcTGldas)));
    annualTPrcGldas(y, 1) = thresh(prc);
    
    prc = find(abs(gldasPr(y)-prcPGldas) == min(abs(gldasPr(y)-prcPGldas)));
    annualPPrcGldas(y, 1) = thresh(prc);
    
    prc = find(abs(gldasRunoff(y)-prcRGldas) == min(abs(gldasRunoff(y)-prcRGldas)));
    annualRPrcGldas(y, 1) = thresh(prc);
end

ethiopiaMaizeYield = importdata('2017-nile-climate\data\ethiopia-maize.txt');
ethiopiaSorghumYield = importdata('2017-nile-climate\data\ethiopia-sorghum.txt');
ethiopiaMilletYield = importdata('2017-nile-climate\data\ethiopia-millet.txt');
ethiopiaBarleyYield = importdata('2017-nile-climate\data\ethiopia-barley.txt');
ethiopiaWheatYield = importdata('2017-nile-climate\data\ethiopia-wheat.txt');
ethiopiaPulsesYield = importdata('2017-nile-climate\data\ethiopia-pulses.txt');
ethiopiaCerealsYield = importdata('2017-nile-climate\data\ethiopia-cereals.txt');

smoothingLen = 15;

linearDetrend = true;

if linearDetrend
    bpMaize = findchangepts(ethiopiaMaizeYield);
    yieldMaize_dt = detrend(ethiopiaMaizeYield, 'linear', bpMaize);% - smooth(ethiopiaMaizeYield, smoothingLen);

    bpMillet = findchangepts(ethiopiaMilletYield);
    yieldMillet_dt = detrend(ethiopiaMilletYield, 'linear', bpMillet);% - smooth(ethiopiaMilletYield, smoothingLen);

    bpSorghum = findchangepts(ethiopiaSorghumYield);
    yieldSorghum_dt = detrend(ethiopiaSorghumYield, 'linear', bpSorghum);% - smooth(ethiopiaSorghumYield, smoothingLen);

    bpWheat = findchangepts(ethiopiaWheatYield);
    yieldWheat_dt = detrend(ethiopiaWheatYield, 'linear', bpWheat);% - smooth(ethiopiaSorghumYield, smoothingLen);

    bpBarley = findchangepts(ethiopiaBarleyYield);
    yieldBarley_dt = detrend(ethiopiaBarleyYield, 'linear', bpBarley);

    bpPulses = findchangepts(ethiopiaPulsesYield);
    yieldPulses_dt = detrend(ethiopiaPulsesYield, 'linear', bpPulses);
else
    yieldBarley_dt = ethiopiaBarleyYield - smooth(ethiopiaBarleyYield, smoothingLen);
    yieldWheat_dt = ethiopiaWheatYield - smooth(ethiopiaSorghumYield, smoothingLen);
    yieldSorghum_dt = ethiopiaSorghumYield - smooth(ethiopiaSorghumYield, smoothingLen);
    yieldMillet_dt = ethiopiaMilletYield - smooth(ethiopiaMilletYield, smoothingLen);
    yieldMaize_dt = ethiopiaMaizeYield - smooth(ethiopiaMaizeYield, smoothingLen);
    yieldPulses_dt = ethiopiaPulsesYield - smooth(ethiopiaPulsesYield, smoothingLen);
end


meanYield = nanmean([normc(yieldMaize_dt), normc(yieldMillet_dt), normc(yieldSorghum_dt), normc(yieldWheat_dt), normc(yieldBarley_dt), normc(yieldPulses_dt)], 2);


colorD = [160, 116, 46]./255.0;
colorHd = [216, 66, 19]./255.0;
colorH = [255, 91, 206]./255.0;
colorW = [68, 166, 226]./255.0;

smoothingTest = false;
if smoothingTest
    figure('Color',[1,1,1]);
    hold on;
    box on;
    grid on;
    axis square;
    %pbaspect([1 2 1])

    alltgood = [];
    alltbad = [];
    allpgood = [];
    allpbad = [];
    
    tmean = 0;
    pmean = 0;
    
    plot([0 7], [50 50], 'k', 'linewidth', 2);
    ind = 1;
    for smoothingLen = 5:5:30
        yieldMaize_dt_tmp = ethiopiaMaizeYield - smooth(ethiopiaMaizeYield, smoothingLen);
        yieldMillet_dt_tmp = ethiopiaMilletYield - smooth(ethiopiaMilletYield, smoothingLen);
        yieldSorghum_dt_tmp = ethiopiaSorghumYield - smooth(ethiopiaSorghumYield, smoothingLen);
        yieldWheat_dt_tmp = ethiopiaWheatYield - smooth(ethiopiaSorghumYield, smoothingLen);
        yieldBarley_dt_tmp = ethiopiaBarleyYield - smooth(ethiopiaBarleyYield, smoothingLen);
        yieldPulses_dt_tmp = ethiopiaPulsesYield - smooth(ethiopiaPulsesYield, smoothingLen);
        meanYield_tmp = nanmean([normc(yieldMaize_dt_tmp), normc(yieldMillet_dt_tmp), normc(yieldSorghum_dt_tmp), normc(yieldWheat_dt_tmp), normc(yieldBarley_dt_tmp), normc(yieldPulses_dt_tmp)], 2);

        indBad = find(meanYield_tmp <= mean(meanYield_tmp)-std(meanYield_tmp));
        indGood = find(meanYield_tmp >= mean(meanYield_tmp)+std(meanYield_tmp));

        indBad(indBad>50) = [];
        indGood(indGood>50) = [];

        tbad = annualTPrc(indBad);
        pbad = annualPPrc(indBad);
        tgood = annualTPrc(indGood);
        pgood = annualPPrc(indGood);

        tmean = tmean + nanmedian(tgood);
        pmean = pmean + nanmedian(pgood);
        
        alltgood = [alltgood; tgood];
        alltbad = [alltbad; tbad];
        allpgood = [allpgood; pgood];
        allpbad = [allpbad; pbad];
        
        b = boxplot([pbad tbad], 'widths', [.1 .1], 'position', [ind-.1 ind+.1]);

        set(b(:,1), {'LineWidth', 'Color'}, {3, colorW})
        lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
        set(lines, 'Color', colorW, 'LineWidth', 2);

        set(b(:,2), {'LineWidth', 'Color'}, {3, colorHd})
        lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
        set(lines, 'Color', colorHd, 'LineWidth', 2);
        ind = ind+1;
    end

    plot([0 7], [mean(alltbad) mean(alltbad)], '--', 'color', colorHd);
    plot([0 7], [mean(allpbad) mean(allpbad)], '--', 'color', colorW);
    
    ylim([0 100])
    xlim([0 7]);
    set(gca, 'xtick', 1:6, 'xticklabel', 5:5:30);
    xlabel('Smoothing length (years)');
    ylabel('Percentile');
    set(gca, 'fontsize', 36);
    set(gcf, 'Position', get(0,'Screensize'));
    export_fig smoothing-test-bad.eps;
    close all;
end

x = 1961:2014;


        

% [bootstat, bootsam] = bootstrp(1000, @median, yieldPulses_dt);
% 
% bootTbad = [];
% bootPbad = [];
% bootTgood = [];
% bootPgood = [];
% bootRbad = [];
% bootRgood = [];
% 
% for s = 1:size(bootsam, 2)
%     bootyield = yieldPulses_dt(bootsam(:,s));
%     bootT = annualTPrc(bootsam(:,s));
%     bootP = annualPPrc(bootsam(:,s));
%     
%     indBad = find(bootyield <= mean(bootyield)-std(bootyield));
%     indGood = find(bootyield >= mean(bootyield)+std(bootyield));
%     indNormal = find(bootyield > mean(bootyield)-std(bootyield) & bootyield < mean(bootyield)+std(bootyield));
% 
%     %indBad(indBad>50) = [];
%     %indGood(indGood>50) = [];
%     %indNormal(indNormal>50) = [];
% 
%     bootTbad(s) = nanmedian(bootT(indBad));
%     bootPbad(s) = nanmedian(bootP(indBad));
%     bootTgood(s) = nanmedian(bootT(indGood));
%     bootPgood(s) = nanmedian(bootP(indGood));
%     
%     curbootRbad = [];
%     for i = 1:length(indBad)
%         % find inds with the same p percentile as in the bad year
%         possibleP = find(abs(bootP(indBad(i))-annualPPrcGldas) == min(abs(bootP(indBad(i))-annualPPrcGldas)));
% 
%         %now out of those years with the right precip, find the T that is
%         %closest to the obs
%         curbootRbad(i) = nanmean(annualRPrcGldas(possibleP(find(abs(bootT(indBad(i))-annualTPrcGldas(possibleP)) == min(abs(bootT(indBad(i))-annualTPrcGldas(possibleP)))))));
%     end
%     bootRbad(s) = nanmedian(curbootRbad);
%     
%     curbootRgood = [];
%     for i = 1:length(indGood)
%         % find inds with the same p percentile as in the bad year
%         possibleP = find(abs(bootP(indGood(i))-annualPPrcGldas) == min(abs(bootP(indGood(i))-annualPPrcGldas)));
% 
%         %now out of those years with the right precip, find the T that is
%         %closest to the obs
%         curbootRgood(i) = nanmean(annualRPrcGldas(possibleP(find(abs(bootT(indGood(i))-annualTPrcGldas(possibleP)) == min(abs(bootT(indGood(i))-annualTPrcGldas(possibleP)))))));
%     end
%     bootRgood(s) = nanmedian(curbootRgood);
% end

% figure('Color', [1,1,1]);
% hold on;
% box on;
% grid on;
% pbaspect([1,3,1]);
% b=boxplot([bootPbad', bootPgood']);
% 
% set(b(:,1), {'LineWidth', 'Color'}, {3, colorHd})
% lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
% set(lines, 'Color', [.6 .6 .6], 'LineWidth', 2);
% 
% set(b(:,2), {'LineWidth', 'Color'}, {3, colorW})
% lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
% set(lines, 'Color', [.6 .6 .6], 'LineWidth', 2);
% 
% plot([0 3], [50 50], '-k', 'linewidth', 2);
% xlim([.5 2.5]);
% ylim([0 100]);
% set(gca, 'xtick', []);
% ylabel('Percentile');
% set(gca, 'FontSize', 40);
% set(gcf, 'Position', get(0,'Screensize'));
% export_fig bootstrp-box-p.eps;
% close all;
% 
% 
% figure('Color', [1,1,1]);
% hold on;
% box on;
% grid on;
% pbaspect([1,3,1]);
% b=boxplot([bootTbad', bootTgood']);
% 
% set(b(:,1), {'LineWidth', 'Color'}, {3, colorHd})
% lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
% set(lines, 'Color', [.6 .6 .6], 'LineWidth', 2);
% 
% set(b(:,2), {'LineWidth', 'Color'}, {3, colorW})
% lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
% set(lines, 'Color', [.6 .6 .6], 'LineWidth', 2);
% 
% plot([0 3], [50 50], '-k', 'linewidth', 2);
% xlim([.5 2.5]);
% ylim([0 100]);
% set(gca, 'xtick', []);
% ylabel('Percentile');
% set(gca, 'FontSize', 40);
% set(gcf, 'Position', get(0,'Screensize'));
% export_fig bootstrp-box-t.eps;
% close all;
% 
% 
% 
% figure('Color', [1,1,1]);
% hold on;
% box on;
% grid on;
% pbaspect([1,3,1]);
% b=boxplot([bootRbad', bootRgood']);
% 
% set(b(:,1), {'LineWidth', 'Color'}, {3, colorHd})
% lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
% set(lines, 'Color', [.6 .6 .6], 'LineWidth', 2);
% 
% set(b(:,2), {'LineWidth', 'Color'}, {3, colorW})
% lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
% set(lines, 'Color', [.6 .6 .6], 'LineWidth', 2);
% 
% plot([0 3], [50 50], '-k', 'linewidth', 2);
% xlim([.5 2.5]);
% ylim([0 100]);
% set(gca, 'xtick', []);
% ylabel('Percentile');
% set(gca, 'FontSize', 40);
% set(gcf, 'Position', get(0,'Screensize'));
% export_fig bootstrp-box-r.eps;
% close all;
% 
% 
% 
% figure('Color', [1,1,1]);
% hold on;
% box on;
% grid on;
% axis square;
% p1=cdfplot(bootPbad);
% set(p1,'color',colorHd,'linewidth',4);
% p2=cdfplot(bootPgood);
% set(p2,'color',colorW,'linewidth',4);
% xlim([0 100]);
% xlabel('Percentile');
% ylabel('Probability');
% set(gca, 'FontSize', 40);
% set(gca, 'xtick', [0 25 50 75 100]);
% set(gca, 'ytick', [0 .2 .4 .5 .6 .8 1]);
% title([]);
% legend('Poor yields', 'Good yields', 'location', 'southeast');
% legend boxoff;
% set(gcf, 'Position', get(0,'Screensize'));
% export_fig bootstrp-cdf-p.eps;
% close all;
% 
% figure('Color', [1,1,1]);
% hold on;
% box on;
% grid on;
% axis square;
% p1=cdfplot(bootTbad);
% set(p1,'color',colorHd,'linewidth',4);
% p2=cdfplot(bootTgood);
% set(p2,'color',colorW,'linewidth',4);
% xlim([0 100]);
% xlabel('Percentile');
% ylabel('Probability');
% set(gca, 'FontSize', 40);
% set(gca, 'xtick', [0 25 50 75 100]);
% set(gca, 'ytick', [0 .2 .4 .5 .6 .8 1]);
% title([]);
% set(gcf, 'Position', get(0,'Screensize'));
% export_fig bootstrp-cdf-t.eps;
% close all;
% 
% 
% figure('Color', [1,1,1]);
% hold on;
% box on;
% grid on;
% axis square;
% p1=cdfplot(bootRbad);
% set(p1,'color',colorHd,'linewidth',4);
% p2=cdfplot(bootRgood);
% set(p2,'color',colorW,'linewidth',4);
% xlim([0 100]);
% xlabel('Percentile');
% ylabel('Probability');
% set(gca, 'FontSize', 40);
% set(gca, 'xtick', [0 25 50 75 100]);
% set(gca, 'ytick', [0 .2 .4 .5 .6 .8 1]);
% title([]);
% set(gcf, 'Position', get(0,'Screensize'));
% export_fig bootstrp-cdf-r.eps;
% close all;

indBad = find(meanYield <= mean(meanYield)-std(meanYield));
indGood = find(meanYield >= mean(meanYield)+std(meanYield));
indNormal = find(meanYield > mean(meanYield)-std(meanYield) & meanYield < mean(meanYield)+std(meanYield));
% 
% indBad(indBad>50) = [];
% indGood(indGood>50) = [];
% indNormal(indNormal>50) = [];

tbad = annualTPrc(indBad);
pbad = annualPPrc(indBad);
rbad = [];
for i = 1:length(indBad)
    % find inds with the same p percentile as in the bad year
    possibleP = find(abs(annualPPrc(indBad(i))-annualPPrcGldas) == min(abs(annualPPrc(indBad(i))-annualPPrcGldas)));
    
    %now out of those years with the right precip, find the T that is
    %closest to the obs
    rbad(i) = nanmean(annualRPrcGldas(possibleP(find(abs(annualTPrc(indBad(i))-annualTPrcGldas(possibleP)) == min(abs(annualTPrc(indBad(i))-annualTPrcGldas(possibleP)))))));
end

tnormal = annualTPrc(indNormal);
pnormal = annualPPrc(indNormal);
rnormal = [];
for i = 1:length(indNormal)
    % find inds with the same p percentile as in the bad year
    possibleP = find(abs(annualPPrc(indNormal(i))-annualPPrcGldas) == min(abs(annualPPrc(indNormal(i))-annualPPrcGldas)));
    
    %now out of those years with the right precip, find the T that is
    %closest to the obs
    rnormal(i) = nanmean(annualRPrcGldas(possibleP(find(abs(annualTPrc(indNormal(i))-annualTPrcGldas(possibleP)) == min(abs(annualTPrc(indNormal(i))-annualTPrcGldas(possibleP)))))));
end

tgood = annualTPrc(indGood);
pgood = annualPPrc(indGood);
rgood = [];
for i = 1:length(indGood)
    % find inds with the same p percentile as in the bad year
    possibleP = find(abs(annualPPrc(indGood(i))-annualPPrcGldas) == min(abs(annualPPrc(indGood(i))-annualPPrcGldas)));
    
    %now out of those years with the right precip, find the T that is
    %closest to the obs
    rgood(i) = nanmean(annualRPrcGldas(possibleP(find(abs(annualTPrc(indGood(i))-annualTPrcGldas(possibleP)) == min(abs(annualTPrc(indGood(i))-annualTPrcGldas(possibleP)))))));
end



figure('Color',[1,1,1]);
hold on;
box on;
grid on;
pbaspect([2 1 1])

plot(x, meanYield, 'k', 'linewidth', 2);


plot([x(1) x(end)], [0 0], '--k','linewidth', 2);
% plot([x(1) x(end)], [-std(meanYield) -std(meanYield)], '--','linewidth', 2, 'color', colorHd);
% plot([x(1) x(end)], [std(meanYield) std(meanYield)], '--','linewidth', 2, 'color', colorW);

yv = (min(meanYield) + -std(meanYield))/2;
yrange = abs(-std(meanYield)-yv);
s = mseb([x(1) x(end)], [yv yv], [yrange yrange], [], 1);
set(s.mainLine, 'Color', colorHd, 'LineWidth', 1);
set(s.patch, 'FaceColor', colorHd);
set(s.edge, 'Color', 'w');

yv = (max(meanYield) + std(meanYield))/2;
yrange = abs(std(meanYield)-yv);
s = mseb([x(1) x(end)], [yv yv], [yrange yrange], [], 1);
set(s.mainLine, 'Color', colorW, 'LineWidth', 1);
set(s.patch, 'FaceColor', colorW);
set(s.edge, 'Color', 'w');

for w = 1:size(wars,1)
    s = shadedErrorBar([wars(w,1) wars(w,2)], [0 0], [1 1], [], 1);
    set(s.mainLine, 'Color', 'none', 'LineWidth', 1);
    set(s.patch, 'FaceColor', [.4 .4 .4]);
    set(s.edge, 'Color', 'w');
end

set(gca, 'YTick', -.3:.1:.3);
xlim([1960 2015]);
ylim([-.3 .3]);
set(gca, 'fontsize', 36);
ylabel('Normalized yield anomaly');
set(gcf, 'Position', get(0,'Screensize'));
export_fig historical-yields.png -m4;
close all;



figure('Color',[1,1,1]);
hold on;
box on;
grid on;
pbaspect([1 3 1])

plot([0 4], [50 50], 'k', 'linewidth', 2);
b = boxplot([pgood tgood rgood'], 'widths', [.6 .6]);

set(b(:,1), {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', colorW, 'LineWidth', 2);

set(b(:,2), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', colorHd, 'LineWidth', 2);

set(b(:,3), {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b(:, 3), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', colorD, 'LineWidth', 2);

plot([.7 4], [nanmedian(pgood) nanmedian(pgood)], '--', 'color', colorW, 'linewidth', 2);
plot([1.7 4], [nanmedian(tgood) nanmedian(tgood)], '--', 'color', colorHd, 'linewidth', 2);
plot([2.6 4], [nanmedian(rgood) nanmedian(rgood)], '--', 'color', colorD, 'linewidth', 2);

ylim([0 100]);
set(gca, 'fontsize', 36);
set(gca,'TickLabelInterpreter', 'tex');
set(gca, 'XTickLabels', {'P^*', 'T^*', 'R^*'});
set(gca, 'YTick', [0 20 40 50 60 80 100]);
ylabel('Percentile');
set(gcf, 'Position', get(0,'Screensize'));
export_fig tp-good-pulses.eps;
close all;


figure('Color',[1,1,1]);
hold on;
box on;
grid on;
pbaspect([1 3 1])

plot([0 4], [50 50], 'k', 'linewidth', 2);
b = boxplot([pbad tbad rbad'], 'widths', [.6 .6]);

set(b(:,1), {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', colorW, 'LineWidth', 2);

set(b(:,2), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', colorHd, 'LineWidth', 2);

set(b(:,3), {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b(:, 3), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', colorD, 'LineWidth', 2);

plot([.7 4], [nanmedian(pbad) nanmedian(pbad)], '--', 'color', colorW, 'linewidth', 2);
plot([1.7 4], [nanmedian(tbad) nanmedian(tbad)], '--', 'color', colorHd, 'linewidth', 2);
plot([2.7 4], [nanmedian(rbad) nanmedian(rbad)], '--', 'color', colorD, 'linewidth', 2);

ylim([0 100]);
set(gca, 'fontsize', 36);
set(gca,'TickLabelInterpreter', 'tex');
set(gca, 'XTickLabels', {'P^*', 'T^*', 'R^*'});
set(gca, 'YTick', [0 20 40 50 60 80 100]);
ylabel('Percentile');
set(gcf, 'Position', get(0,'Screensize'));
export_fig tp-bad-pulses.eps;
close all;


figure('Color',[1,1,1]);
hold on;
box on;
grid on;
pbaspect([1 3 1])

plot([0 4], [50 50], 'k', 'linewidth', 2);
b = boxplot([pnormal tnormal rnormal'], 'widths', [.8 .8]);

set(b(:,1), {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(b(:,2), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(b(:,3), {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b(:, 3), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

plot([.6 4], [nanmedian(pnormal) nanmedian(pnormal)], '--', 'color', colorW, 'linewidth', 2);
plot([1.6 4], [nanmedian(tnormal) nanmedian(tnormal)], '--', 'color', colorHd, 'linewidth', 2);
plot([2.6 4], [nanmedian(rnormal) nanmedian(rnormal)], '--', 'color', colorD, 'linewidth', 2);


ylim([0 100]);
set(gca, 'fontsize', 36);
set(gca,'TickLabelInterpreter', 'tex');
set(gca, 'XTickLabels', {'P^*', 'T^*', 'R^*'});
set(gca, 'YTick', [0 20 40 50 60 80 100]);
ylabel('Percentile');
set(gcf, 'Position', get(0,'Screensize'));
export_fig tp-normal.eps;
close all;

% subplot(2,1,2);
% hold on;
% plot(x, annualPPrc, 'b');
% plot(x, annualTPrc, 'r');

