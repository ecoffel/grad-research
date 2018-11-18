% drought 1987
% flood 

%[1988 1994 1996 1998 1999 2001 2003

wars = [[1975 1978]; ...        % 
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
regionBoundsEthiopia = regions('nile-ethiopia');
regionBoundsBlue = regions('nile-blue');

[latIndsEthiopiaUdel, lonIndsEthiopiaUdel] = latLonIndexRange({lat, lon,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
[latIndsBlueUdel, lonIndsBlueUdel] = latLonIndexRange({lat, lon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));

pdataset = squeeze(nanmean(nanmean(nansum(udelp{3}(latIndsBlueUdel, lonIndsBlueUdel, :, :), 4), 2), 1));
tdataset = squeeze(nanmean(nanmean(nanmean(udelt{3}(latIndsBlueUdel, lonIndsBlueUdel, :, :), 4), 2), 1));

load 2017-nile-climate\output\gldas_qs.mat
load 2017-nile-climate\output\gldas_qsb.mat
load 2017-nile-climate\output\gldas_pr.mat
load 2017-nile-climate\output\gldas_t.mat

latGldas = gldas_t{1};
lonGldas = gldas_t{2};
[latIndsEthiopiaGldas, lonIndsEthiopiaGldas] = latLonIndexRange({latGldas, lonGldas,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
[latIndsBlueGldas, lonIndsBlueGldas] = latLonIndexRange({latGldas, lonGldas,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));

gldasRunoff = gldas_qs{3}(:, :, :, :) + gldas_qsb{3}(:, :, :, :);
gldasRunoff = squeeze(nanmean(nanmean(nansum(gldasRunoff(latIndsBlueGldas, lonIndsBlueGldas,:,5:9),4),2),1));
gldasT = squeeze(nanmean(nanmean(nanmean(gldas_t{3}(latIndsBlueGldas, lonIndsBlueGldas,:,5:9),4),2),1));
gldasPr = squeeze(nanmean(nanmean(nanmean(gldas_pr{3}(latIndsBlueGldas, lonIndsBlueGldas,:,5:9),4),2),1));

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
ethiopiaMilletYield = importdata('2017-nile-climate\data\ethiopia-millet.txt');
ethiopiaSorghumYield = importdata('2017-nile-climate\data\ethiopia-sorghum.txt');

ethiopiaMaizeYield = importdata('2017-nile-climate\data\ethiopia-maize.txt');
ethiopiaSorghumYield = importdata('2017-nile-climate\data\ethiopia-sorghum.txt');
ethiopiaMilletYield = importdata('2017-nile-climate\data\ethiopia-millet.txt');
ethiopiaBarleyYield = importdata('2017-nile-climate\data\ethiopia-barley.txt');
ethiopiaWheatYield = importdata('2017-nile-climate\data\ethiopia-wheat.txt');
ethiopiaPulsesYield = importdata('2017-nile-climate\data\ethiopia-pulses.txt');
ethiopiaCerealsYield = importdata('2017-nile-climate\data\ethiopia-cereals.txt');

bpMaize = findchangepts(ethiopiaMaizeYield)
yieldMaize_dt = detrend(ethiopiaMaizeYield, 'linear', bpMaize);% - smooth(ethiopiaMaizeYield, smoothingLen);

bpMillet = findchangepts(ethiopiaMilletYield)
yieldMillet_dt = detrend(ethiopiaMilletYield, 'linear', bpMillet);% - smooth(ethiopiaMilletYield, smoothingLen);

bpSorghum = findchangepts(ethiopiaSorghumYield)
yieldSorghum_dt = detrend(ethiopiaSorghumYield, 'linear', bpSorghum);% - smooth(ethiopiaSorghumYield, smoothingLen);

bpWheat = findchangepts(ethiopiaWheatYield)
yieldWheat_dt = detrend(ethiopiaWheatYield, 'linear', bpWheat);% - smooth(ethiopiaSorghumYield, smoothingLen);

bpBarley = findchangepts(ethiopiaBarleyYield)
yieldBarley_dt = detrend(ethiopiaBarleyYield, 'linear', bpBarley);

bpPulses = findchangepts(ethiopiaPulsesYield)
yieldPulses_dt = detrend(ethiopiaPulsesYield, 'linear', bpPulses);

meanYield = nanmean([normc(yieldMaize_dt), normc(yieldMillet_dt), normc(yieldSorghum_dt), normc(yieldWheat_dt), normc(yieldBarley_dt), normc(yieldPulses_dt)], 2);
%meanYield = nanmean([normc(yieldPulses_dt)], 2);
tpcorr = corr(annualTPrc, annualPPrc)
pcorr = corr(annualPPrc, meanYield)
tcorr = corr(annualTPrc, meanYield)

x = 1961:2014;

yhd = [];
yd = [];
tind = 1;

for t = 10:20:90
    pind = 1;
    for p = 10:20:90
        yhd(tind, pind) = nanmean(meanYield(find(annualTPrc>t & annualPPrc < p)));
        yd(tind, pind) = nanmean(meanYield(find(annualTPrc<t & annualPPrc < p)));
        pind = pind+1;
    end
    tind=tind+1;
end
        

colorD = [160, 116, 46]./255.0;
colorHd = [216, 66, 19]./255.0;
colorH = [255, 91, 206]./255.0;
colorW = [68, 166, 226]./255.0;

figure('Color',[1,1,1]);
hold on;
box on;
grid on;
pbaspect([2 1 1])

plot(x, meanYield, 'k', 'linewidth', 2);

tprc = 74;
pprc = 34;

hdSuperYears = [];
for d = 1:size(annualTPrcSuper, 2)
    hdSuperYears(:,d) = annualTPrcSuper(:, d) >= tprc & annualPPrcSuper(:, d) <= pprc;
    dSuperYears(:,d) = annualTPrcSuper(:, d) <= tprc & annualPPrcSuper(:, d) <= pprc;
end

for i = 1:size(hdSuperYears, 1)
    hd = sum(hdSuperYears(i,:)) >= .5*size(hdSuperYears,2);
    d = sum(dSuperYears(i,:)) >= .5*size(dSuperYears,2);
    
    if hd
        plot(x(i+21), meanYield(i+21), 'om', 'markersize', 15, 'linewidth', 4, 'color', colorHd);
    elseif d
        plot(x(i+21), meanYield(i+21), 'og', 'markersize', 15, 'linewidth', 4, 'color', colorD);
    end
end

% for i = 1:length(x)
%     
% 
%     if annualPPrc(i) <= pprc & annualTPrc(i) >= tprc
%         plot(x(i), meanYield(i), 'om', 'markersize', 15, 'linewidth', 4, 'color', colorHd);
%     elseif annualPPrc(i) <= pprc & annualTPrc(i) <= tprc
%         plot(x(i), meanYield(i), 'og', 'markersize', 15, 'linewidth', 4, 'color', colorD);
%     end
%     
% end

yieldhd = nanmean(meanYield(find(annualTPrc>=tprc & annualPPrc <= pprc)))
yieldd = nanmean(meanYield(find(annualTPrc<=tprc & annualPPrc <= pprc)))

indBad = find(meanYield <= -std(meanYield));
indGood = find(meanYield >= std(meanYield));
indNormal = find(meanYield > -std(meanYield) & meanYield < std(meanYield));

indBad(indBad>50) = [];
indGood(indGood>50) = [];
indNormal(indNormal>50) = [];

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
    set(s.mainLine, 'Color', 'W', 'LineWidth', 1);
    set(s.patch, 'FaceColor', [.4 .4 .4]);
    set(s.edge, 'Color', 'w');
end

% plot([x(1) x(end)], [yieldhd yieldhd], '-', 'color', colorHd, 'linewidth', 2);
% plot([x(1) x(end)], [yieldd yieldd], '-', 'color', colorD, 'linewidth', 2);

%ylim([-5100 7100]);
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
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(b(:,2), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(b(:,3), {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b(:, 3), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

plot([.7 4], [nanmean(pgood) nanmean(pgood)], '--', 'color', colorW, 'linewidth', 2);
plot([1.7 4], [nanmean(tgood) nanmean(tgood)], '--', 'color', colorHd, 'linewidth', 2);
plot([2.6 4], [nanmean(rgood) nanmean(rgood)], '--', 'color', colorD, 'linewidth', 2);

ylim([0 100]);
set(gca, 'fontsize', 36);
set(gca, 'XTickLabels', {'P', 'T', 'R'});
set(gca, 'YTick', [0 20 40 50 60 80 100]);
ylabel('Percentile');
set(gcf, 'Position', get(0,'Screensize'));
export_fig tp-good.eps;
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
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(b(:,2), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(b(:,3), {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b(:, 3), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

plot([.7 4], [nanmean(pbad) nanmean(pbad)], '--', 'color', colorW, 'linewidth', 2);
plot([1.7 4], [nanmean(tbad) nanmean(tbad)], '--', 'color', colorHd, 'linewidth', 2);
plot([2.6 4], [nanmean(rbad) nanmean(rbad)], '--', 'color', colorD, 'linewidth', 2);

ylim([0 100]);
set(gca, 'fontsize', 36);
set(gca, 'XTickLabels', {'P', 'T', 'R'});
set(gca, 'YTick', [0 20 40 50 60 80 100]);
ylabel('Percentile');
set(gcf, 'Position', get(0,'Screensize'));
export_fig tp-bad.eps;
close all;


figure('Color',[1,1,1]);
hold on;
box on;
grid on;
pbaspect([1 3 1])

plot([0 4], [50 50], 'k', 'linewidth', 2);
b = boxplot([pnormal tnormal rnormal], 'widths', [.8 .8]);

set(b(:,1), {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(b(:,2), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(b(:,3), {'LineWidth', 'Color'}, {3, colorD})
lines = findobj(b(:, 3), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

plot([.6 4], [nanmean(pnormal) nanmean(pnormal)], '--', 'color', colorW, 'linewidth', 2);
plot([1.6 4], [nanmean(tnormal) nanmean(tnormal)], '--', 'color', colorHd, 'linewidth', 2);
plot([2.6 4], [nanmean(rnormal) nanmean(rnormal)], '--', 'color', colorD, 'linewidth', 2);


ylim([0 100]);
set(gca, 'fontsize', 36);
set(gca, 'XTickLabels', {'P', 'T', 'R'});
set(gca, 'YTick', [0 20 40 50 60 80 100]);
ylabel('Percentile');
set(gcf, 'Position', get(0,'Screensize'));
export_fig tp-normal.eps;
close all;

% subplot(2,1,2);
% hold on;
% plot(x, annualPPrc, 'b');
% plot(x, annualTPrc, 'r');

