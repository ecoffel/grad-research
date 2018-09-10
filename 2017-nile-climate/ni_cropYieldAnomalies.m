% drought 1987
% flood 

regionBoundsEthiopia = [[5.5 14.8]; [31, 40]];
regionBoundsEgypt = [[22 31.4]; [25, 37]];
regionBoundsSudan = [[4 12]; [24, 34.5]];

if ~exist('udelp')
    udelp = loadMonthlyData('E:\data\udel\output\precip\monthly\1900-2014', 'precip', 'startYear', 1901, 'endYear', 2014);
    udelt = loadMonthlyData('E:\data\udel\output\air\monthly\1900-2014', 'air', 'startYear', 1901, 'endYear', 2014);
    
    %cmip5p = loadMonthlyData(['e:/data/cmip5/output/access1-0/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', 1901, 'endYear', 2005); 
    %cmip5t = loadMonthlyData(['e:/data/cmip5/output/access1-0/mon/r1i1p1/historical/tas/regrid/world'], 'tas', 'startYear', 1901, 'endYear', 2005); 
end

lat=udelt{1};
lon=udelt{2};

[latIndsEthiopiaUdel, lonIndsEthiopiaUdel] = latLonIndexRange({lat,lon,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));
[latIndsSudanUdel, lonIndsSudanUdel] = latLonIndexRange({lat,lon,[]}, regionBoundsSudan(1,:), regionBoundsSudan(2,:));

udelpAnnualEthiopiaOrig = squeeze(nanmean(nanmean(nanmean(udelp{3}(latIndsEthiopiaUdel, lonIndsEthiopiaUdel, :, [5 6 7 8 9]), 4), 2), 1));
udeltAnnualEthiopiaOrig = squeeze(nanmean(nanmean(nanmean(udelt{3}(latIndsEthiopiaUdel, lonIndsEthiopiaUdel, :, [5 6 7 8 9]), 4), 2), 1));

udelpAnnualSudan = squeeze(nanmean(nanmean(nanmean(udelp{3}(latIndsSudanUdel, lonIndsSudanUdel, :, 5:9), 4), 2), 1));
udeltAnnualSudan = squeeze(nanmean(nanmean(nanmean(udelt{3}(latIndsSudanUdel, lonIndsSudanUdel, :, 5:9), 4), 2), 1));


ethiopiaMaizeYield = importdata('2017-nile-climate\data\ethiopia-maize.txt');
ethiopiaSorghumYield = importdata('2017-nile-climate\data\ethiopia-sorghum.txt');
ethiopiaMilletYield = importdata('2017-nile-climate\data\ethiopia-millet.txt');
ethiopiaBarleyYield = importdata('2017-nile-climate\data\ethiopia-barley.txt');
ethiopiaWheatYield = importdata('2017-nile-climate\data\ethiopia-wheat.txt');
ethiopiaPulsesYield = importdata('2017-nile-climate\data\ethiopia-pulses.txt');
ethiopiaCerealsYield = importdata('2017-nile-climate\data\ethiopia-cereals.txt');

ethiopiaCattle = importdata('2017-nile-climate\data\ethiopia-cattle.txt');
ethiopiaGoats = importdata('2017-nile-climate\data\ethiopia-goats.txt');
ethiopiaChicken = importdata('2017-nile-climate\data\ethiopia-chicken.txt');
ethiopiaCamels = importdata('2017-nile-climate\data\ethiopia-camels.txt');
ethiopiaSheep = importdata('2017-nile-climate\data\ethiopia-sheep.txt');
ethiopiaHorses = importdata('2017-nile-climate\data\ethiopia-horses.txt');
ethiopiaAsses = importdata('2017-nile-climate\data\ethiopia-asses.txt');

ethiopiaMaizeCal = importdata('2017-nile-climate\data\ethiopia-cal-maize.txt');
ethiopiaSorghumCal = importdata('2017-nile-climate\data\ethiopia-cal-sorghum.txt');
ethiopiaMilletCal = importdata('2017-nile-climate\data\ethiopia-cal-millet.txt');
ethiopiaBarleyCal = importdata('2017-nile-climate\data\ethiopia-cal-barley.txt');
ethiopiaWheatCal = importdata('2017-nile-climate\data\ethiopia-cal-wheat.txt');
ethiopiaPulsesCal = importdata('2017-nile-climate\data\ethiopia-cal-pulses.txt');
ethiopiaCerealsCal = importdata('2017-nile-climate\data\ethiopia-cal-cereals.txt');

ethiopiaMeanLivestock1 = nanmean([normc(ethiopiaCattle(1:32)), normc(ethiopiaGoats(1:32)), normc(ethiopiaChicken(1:32)), normc(ethiopiaCamels(1:32)), normc(ethiopiaSheep(1:32)), normc(ethiopiaHorses(1:32)), normc(ethiopiaAsses(1:32))], 2);
ethiopiaMeanLivestock2 = nanmean([normc(ethiopiaCattle(33:end)), normc(ethiopiaGoats(33:end)), normc(ethiopiaChicken(33:end)), normc(ethiopiaCamels(33:end)), normc(ethiopiaSheep(33:end)), normc(ethiopiaHorses(33:end)), normc(ethiopiaAsses(33:end))], 2);
ethiopiaMeanYield = nanmean([normc(ethiopiaMaizeYield) normc(ethiopiaSorghumYield) normc(ethiopiaMilletYield) normc(ethiopiaWheatYield) normc(ethiopiaCerealsYield) normc(ethiopiaPulsesYield)], 2);
ethiopiaMeanCal = nanmean([normc(ethiopiaMaizeCal) normc(ethiopiaSorghumCal) normc(ethiopiaMilletCal) normc(ethiopiaBarleyCal) normc(ethiopiaWheatCal) normc(ethiopiaPulsesCal) normc(ethiopiaCerealsCal)], 2);

yieldMaizeEthiopia_dt = ethiopiaMaizeYield - smooth(ethiopiaMaizeYield, 10); 
yieldMilletEthiopia_dt = ethiopiaMilletYield - smooth(ethiopiaMilletYield, 10); 
yieldBarleyEthiopia_dt = ethiopiaBarleyYield - smooth(ethiopiaBarleyYield, 10); 
yieldWheatEthiopia_dt = ethiopiaWheatYield - smooth(ethiopiaWheatYield, 10); 
yieldSorghumEthiopia_dt = ethiopiaSorghumYield - smooth(ethiopiaSorghumYield, 10);
yieldCerealsEthiopia_dt = ethiopiaCerealsYield - smooth(ethiopiaCerealsYield, 10);
yieldMeanEthiopia_dt = ethiopiaMeanYield - smooth(ethiopiaMeanYield, 15);

cattleEthiopia_dt = ethiopiaCattle - smooth(ethiopiaCattle, 10);
goatsEthiopia_dt = ethiopiaGoats - smooth(ethiopiaGoats, 10);
livestockEthiopia1_dt = ethiopiaMeanLivestock1- smooth(ethiopiaMeanLivestock1, 15);
livestockEthiopia2_dt = ethiopiaMeanLivestock2- smooth(ethiopiaMeanLivestock2, 15);
calEthiopia_dt = ethiopiaMeanCal- smooth(ethiopiaMeanCal, 10);

cnt = 0;
cnthd = 0;
cntd = 0;
cnth = 0;
cntw = 0;

for ph = 75%1:99
    for pl = 50%1:99
prcHigh = ph;
prcLow = pl;

threshTEthiopiaHigh = prctile(udeltAnnualEthiopiaOrig(1:60), prcHigh);
threshTEthiopiaLow = prctile(udeltAnnualEthiopiaOrig(1:60), prcLow);
threshPAnnualEthiopiaLow = prctile(udelpAnnualEthiopiaOrig(1:60), prcLow);
threshPAnnualEthiopiaHigh = prctile(udelpAnnualEthiopiaOrig(1:60), prcHigh);

udeltAnnualEthiopia = udeltAnnualEthiopiaOrig(61:end-1);
udelpAnnualEthiopia = udelpAnnualEthiopiaOrig(61:end-1);

udeltAnnualSudan = udeltAnnualSudan(61:end-3);
udelpAnnualSudan = udelpAnnualSudan(61:end-3);

threshTSudan = prctile(udeltAnnualSudan, prcHigh);
threshTSudanLow = prctile(udeltAnnualSudan, prcLow);
threshPAnnualSudanLow = prctile(udelpAnnualSudan, prcLow);
threshPAnnualSudanHigh = prctile(udelpAnnualSudan, prcHigh);

wYearsEthiopia = find(udelpAnnualEthiopia > threshPAnnualEthiopiaHigh);
hYearsEthiopia = find(udeltAnnualEthiopia > threshTEthiopiaHigh);
cYearsEthiopia = find(udeltAnnualEthiopia  < threshTEthiopiaLow);
dYearsEthiopia = find(udelpAnnualEthiopia < threshPAnnualEthiopiaLow & udeltAnnualEthiopia < threshTEthiopiaHigh);
cdYearsEthiopia = find(udelpAnnualEthiopia < threshPAnnualEthiopiaLow & udeltAnnualEthiopia < threshTEthiopiaLow);
hdYearsEthiopia = find(udelpAnnualEthiopia < threshPAnnualEthiopiaLow & udeltAnnualEthiopia > threshTEthiopiaHigh);
cwYearsEthiopia = find(udelpAnnualEthiopia > threshPAnnualEthiopiaHigh & udeltAnnualEthiopia < threshTEthiopiaLow);

if length(dYearsEthiopia) < 8 || length(hdYearsEthiopia) < 8 || abs(length(hdYearsEthiopia)-length(dYearsEthiopia)) > 2
    continue;
end


nanmean(yieldMeanEthiopia_dt(hdYearsEthiopia));
nanmean(yieldMeanEthiopia_dt(dYearsEthiopia));
% nanmean(yieldMeanEthiopia_dt(hYearsEthiopia))
% nanmean(yieldMeanEthiopia_dt(wYearsEthiopia))
[h_hd,p] = ttest(yieldMeanEthiopia_dt(hdYearsEthiopia))
[h_d,p] = ttest(yieldMeanEthiopia_dt(dYearsEthiopia))
[h_h,p] = ttest(yieldMeanEthiopia_dt(hYearsEthiopia));
[h_w,p] = ttest(yieldMeanEthiopia_dt(wYearsEthiopia));

cnt = cnt + 1;
if h_hd
    cnthd = cnthd + 1;
end
if h_d
    cntd = cntd + 1;
end
if h_h
    cnth = cnth + 1;
end
if h_w
    cntw = cntw + 1;
end
%continue;
live_hd = nanmean([livestockEthiopia1_dt(hdYearsEthiopia(hdYearsEthiopia<=32)); livestockEthiopia2_dt(hdYearsEthiopia(hdYearsEthiopia>32)-32)])
live_d = nanmean([livestockEthiopia1_dt(dYearsEthiopia(dYearsEthiopia<=32)); livestockEthiopia2_dt(dYearsEthiopia(dYearsEthiopia>32)-32)])
live_h = nanmean([livestockEthiopia1_dt(hYearsEthiopia(hYearsEthiopia<=32)); livestockEthiopia2_dt(hYearsEthiopia(hYearsEthiopia>32)-32)])
live_w = nanmean([livestockEthiopia1_dt(wYearsEthiopia(wYearsEthiopia<=32)); livestockEthiopia2_dt(wYearsEthiopia(wYearsEthiopia>32)-32)])
[h_lhd,p] = ttest([livestockEthiopia1_dt(hdYearsEthiopia(hdYearsEthiopia<=32)); livestockEthiopia2_dt(hdYearsEthiopia(hdYearsEthiopia>32)-32)])
[h_ld,p] = ttest([livestockEthiopia1_dt(dYearsEthiopia(dYearsEthiopia<=32)); livestockEthiopia2_dt(dYearsEthiopia(dYearsEthiopia>32)-32)])
[h_lh,p] = ttest([livestockEthiopia1_dt(hYearsEthiopia(hYearsEthiopia<=32)); livestockEthiopia2_dt(hYearsEthiopia(hYearsEthiopia>32)-32)])
[h_lw,p] = ttest([livestockEthiopia1_dt(wYearsEthiopia(wYearsEthiopia<=32)); livestockEthiopia2_dt(wYearsEthiopia(wYearsEthiopia>32)-32)])
% 
% length(hdYearsEthiopia)
% length(dYearsEthiopia)
% length(hYearsEthiopia)
% length(wYearsEthiopia)


figure('Color', [1,1,1]);
hold on;
grid on;
box on;
axis square;

colorD = [160, 116, 46]./255.0;
colorHd = [216, 66, 19]./255.0;
colorH = [255, 91, 206]./255.0;
colorW = [68, 166, 226]./255.0;

b = bar([1], [nanmean(yieldMeanEthiopia_dt(hdYearsEthiopia))], .75, 'k');
if h_hd
    set(b, 'facecolor', colorHd, 'linewidth', 6);
else
    set(b, 'facecolor', colorHd);
end

b = bar([2], [nanmean(yieldMeanEthiopia_dt(dYearsEthiopia))], .75, 'k');
if h_d
    set(b, 'facecolor', colorD, 'linewidth', 6);
else
    set(b, 'facecolor', colorD);
end

b = bar([3], [nanmean(yieldMeanEthiopia_dt(hYearsEthiopia))], .75, 'k');
if h_h
    set(b, 'facecolor', colorH, 'linewidth', 6);
else
    set(b, 'facecolor', colorH);
end

b = bar([4], [nanmean(yieldMeanEthiopia_dt(wYearsEthiopia))], .75, 'k');
if h_w
    set(b, 'facecolor', colorW, 'linewidth', 6);
else
    set(b, 'facecolor', colorW);
end

title('T: 75%, P: 50%');
set(gca, 'fontsize', 36);
set(gca, 'XTick', [1 2 3 4], 'XTickLabels', {'Hot + Dry', 'Dry', 'Hot', 'Wet'});
ylim([-10 4] .* 1e-3);
set(gca, 'YTick', [-10:2:4] .* 1e-3, 'YTickLabels', -10:2:4);
ylabel('Normalized yield anomaly');
xtickangle(45);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['crop-anomalies-75-50.eps']);
close all;

figure('Color', [1,1,1]);
hold on;
grid on;
box on;
axis square;

b = bar([1], live_hd, .75, 'k');
if h_lhd
    set(b, 'facecolor', colorHd, 'linewidth', 6);
else
    set(b, 'facecolor', colorHd);
end

b = bar([2], live_d, .75, 'k');
if h_ld
    set(b, 'facecolor', colorD, 'linewidth', 6);
else
    set(b, 'facecolor', colorD);
end

b = bar([3], live_h, .75, 'k');
if h_lh
    set(b, 'facecolor', colorH, 'linewidth', 6);
else
    set(b, 'facecolor', colorH);
end

b = bar([4], live_w, .75, 'k');
if h_lw
    set(b, 'facecolor', colorW, 'linewidth', 6);
else
    set(b, 'facecolor', colorW);
end

title('T: 75%, P: 50%');
set(gca, 'fontsize', 36);
set(gca, 'XTick', [1 2 3 4], 'XTickLabels', {'Hot + Dry', 'Dry', 'Hot', 'Wet'});
ylim([-10 4] .* 1e-3);
set(gca, 'YTick', [-10:2:4] .* 1e-3, 'YTickLabels', -10:2:4);
ylabel('Normalized livestock anomaly');
xtickangle(45);
set(gcf, 'Position', get(0,'Screensize'));
export_fig(['livestock-anomalies-75-50.eps']);
close all;
    end
end