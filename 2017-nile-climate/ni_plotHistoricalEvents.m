% drought 1987
% flood 

%[1988 1994 1996 1998 1999 2001 2003

wars = [[1975 1978]; ...        % 
        [1982 1983]; ...
        [1984 1986];    ...    % resettlement of 1.5M peasants
        [1991 1992]; ...
        [1998 2000]; ...
        [2006 2009]];

regionBounds = [[2 32]; [25, 44]];
%regionBoundsSouth = [[2 13]; [25, 42]];
regionBoundsHighlands = [[8 13]; [34, 40]];
regionBoundsNorth = [[13 32]; [29, 34]];

regionBoundsBlue = [[9 14]; [34, 37.5]];
regionBoundsWhite = [[9 14]; [30, 34]];
regionBoundsEthiopia = [[3.4 14.8]; [31, 45.5]];

if ~exist('udelp')
    udelp = loadMonthlyData('E:\data\udel\output\precip\monthly\1900-2014', 'precip', 'startYear', 1901, 'endYear', 2014);
    udelp = {udelp{1}, udelp{2}, flipud(udelp{3})};
    udelt = loadMonthlyData('E:\data\udel\output\air\monthly\1900-2014', 'air', 'startYear', 1901, 'endYear', 2014);
    udelt = {udelt{1}, udelt{2}, flipud(udelt{3})};
    
    %cmip5p = loadMonthlyData(['e:/data/cmip5/output/access1-0/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', 1901, 'endYear', 2005); 
    %cmip5t = loadMonthlyData(['e:/data/cmip5/output/access1-0/mon/r1i1p1/historical/tas/regrid/world'], 'tas', 'startYear', 1901, 'endYear', 2005); 
end
% 
% c = [];
% for xlat = 1:size(lat,1)
%     for ylon = 1:size(lat,2)
%         t = squeeze(nanmean(udelt{3}(xlat, ylon, :, 5:9),4));
%         p = squeeze(nanmean(udelp{3}(xlat, ylon, :, 5:9),4));
%         c(xlat, ylon) = corr(t,p);
%     end
% end

lat=udelt{1};
lon=udelt{2};
[latIndsBlueUdel, lonIndsBlueUdel] = latLonIndexRange({lat,lon,[]}, regionBoundsBlue(1,:), regionBoundsBlue(2,:));
[latIndsWhiteUdel, lonIndsWhiteUdel] = latLonIndexRange({lat,lon,[]}, regionBoundsWhite(1,:), regionBoundsWhite(2,:));
[latIndsEthiopiaUdel, lonIndsEthiopiaUdel] = latLonIndexRange({lat,lon,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));

pdataset = squeeze(nanmean(nanmean(nansum(udelp{3}(latIndsEthiopiaUdel, lonIndsEthiopiaUdel, 61:end, :), 4), 2), 1));
tdataset = squeeze(nanmean(nanmean(nanmean(udelt{3}(latIndsEthiopiaUdel, lonIndsEthiopiaUdel, 61:end, :), 4), 2), 1));

% pdataset = detrend(pdataset);
% tdataset = detrend(tdataset);

thresh = 0:5:100;

prcT = prctile(tdataset(1:40), thresh);
prcP = prctile(pdataset(1:40), thresh);

annualPPrc = [];
annualTPrc = [];

for y = 1:length(pdataset)
    prc = find(abs(pdataset(y)-prcP) == min(abs(pdataset(y)-prcP)));
    annualPPrc(y, 1) = thresh(prc);
    
    prc = find(abs(tdataset(y)-prcT) == min(abs(tdataset(y)-prcT)));
    annualTPrc(y, 1) = thresh(prc);
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

for i = 1:length(x)
    if annualPPrc(i) <= pprc & annualTPrc(i) >= tprc
        plot(x(i), meanYield(i), 'om', 'markersize', 15, 'linewidth', 4, 'color', colorHd);
    elseif annualPPrc(i) <= pprc & annualTPrc(i) <= tprc
        plot(x(i), meanYield(i), 'og', 'markersize', 15, 'linewidth', 4, 'color', colorD);
    end
    
end

yieldhd = nanmean(meanYield(find(annualTPrc>=tprc & annualPPrc <= pprc)))
yieldd = nanmean(meanYield(find(annualTPrc<=tprc & annualPPrc <= pprc)))

tbad = annualTPrc(find(meanYield <= -std(meanYield)));
pbad = annualPPrc(find(meanYield <= -std(meanYield)));

tnormal = annualTPrc(find(meanYield > -std(meanYield) & meanYield < std(meanYield)));
pnormal = annualPPrc(find(meanYield > -std(meanYield) & meanYield < std(meanYield)));

tgood = annualTPrc(find(meanYield >= std(meanYield)));
pgood = annualPPrc(find(meanYield >= std(meanYield)));

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

plot([0 3], [50 50], '--k', 'linewidth', 2);
b = boxplot([pgood tgood], 'widths', [.8 .8]);

set(b(:,1), {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(b(:,2), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

plot([.6 3], [nanmean(pgood) nanmean(pgood)], '--', 'color', colorW, 'linewidth', 2);
plot([1.6 3], [nanmean(tgood) nanmean(tgood)], '--', 'color', colorHd, 'linewidth', 2);

ylim([0 100]);
set(gca, 'fontsize', 36);
set(gca, 'XTickLabels', {'P', 'T'});
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

plot([.1 3], [50 50], '--k', 'linewidth', 2);
b = boxplot([pbad tbad], 'widths', [.8 .8]);

set(b(:,1), {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(b(:,2), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

plot([.6 3], [nanmean(pbad) nanmean(pbad)], '--', 'color', colorW, 'linewidth', 2);
plot([1.6 3], [nanmean(tbad) nanmean(tbad)], '--', 'color', colorHd, 'linewidth', 2);


ylim([0 100]);
set(gca, 'fontsize', 36);
set(gca, 'XTickLabels', {'P', 'T'});
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

plot([.1 3], [50 50], '--k', 'linewidth', 2);
b = boxplot([pnormal tnormal], 'widths', [.8 .8]);

set(b(:,1), {'LineWidth', 'Color'}, {3, colorW})
lines = findobj(b(:, 1), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

set(b(:,2), {'LineWidth', 'Color'}, {3, colorHd})
lines = findobj(b(:, 2), 'type', 'line', 'Tag', 'Median');
set(lines, 'Color', [100 100 100]./255, 'LineWidth', 2);

plot([.6 3], [nanmean(pnormal) nanmean(pnormal)], '--', 'color', colorW, 'linewidth', 2);
plot([1.6 3], [nanmean(tnormal) nanmean(tnormal)], '--', 'color', colorHd, 'linewidth', 2);


ylim([0 100]);
set(gca, 'fontsize', 36);
set(gca, 'XTickLabels', {'P', 'T'});
set(gca, 'YTick', [0 20 40 50 60 80 100]);
ylabel('Percentile');
set(gcf, 'Position', get(0,'Screensize'));
export_fig tp-normal.eps;
close all;

% subplot(2,1,2);
% hold on;
% plot(x, annualPPrc, 'b');
% plot(x, annualTPrc, 'r');

