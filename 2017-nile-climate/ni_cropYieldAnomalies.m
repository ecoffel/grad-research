% drought 1987
% flood 

regionBoundsEthiopia = [[5.5 14.8]; [31, 40]];
regionBoundsEthiopia = [[4.5 11.5]; [34, 39]];
regionBoundsEgypt = [[22 31.4]; [25, 37]];
regionBoundsSudan = [[4 12]; [24, 34.5]];

if ~exist('udelt')
    udelp = loadMonthlyData('E:\data\udel\output\precip\monthly\1900-2014', 'precip', 'startYear', 1901, 'endYear', 2014);
    udelp = {udelp{1}, udelp{2}, flipud(udelp{3})};
    udelt = loadMonthlyData('E:\data\udel\output\air\monthly\1900-2014', 'air', 'startYear', 1901, 'endYear', 2014);
    udelt = {udelt{1}, udelt{2}, flipud(udelt{3})};

    %cmip5p = loadMonthlyData(['e:/data/cmip5/output/access1-0/mon/r1i1p1/historical/pr/regrid/world'], 'pr', 'startYear', 1901, 'endYear', 2005); 
    %cmip5t = loadMonthlyData(['e:/data/cmip5/output/access1-0/mon/r1i1p1/historical/tas/regrid/world'], 'tas', 'startYear', 1901, 'endYear', 2005); 
end

lat=udelt{1};
lon=udelt{2};

[latIndsEthiopiaUdel, lonIndsEthiopiaUdel] = latLonIndexRange({lat,lon,[]}, regionBoundsEthiopia(1,:), regionBoundsEthiopia(2,:));

udelpAnnualEthiopia = squeeze(nanmean(nanmean(nansum(udelp{3}(latIndsEthiopiaUdel, lonIndsEthiopiaUdel, :, :), 4), 2), 1));
udeltAnnualEthiopia = squeeze(nanmean(nanmean(nanmean(udelt{3}(latIndsEthiopiaUdel, lonIndsEthiopiaUdel, :, :), 4), 2), 1));

ethiopiaMaizeYield = detrend(importdata('2017-nile-climate\data\ethiopia-maize.txt'));
ethiopiaSorghumYield = detrend(importdata('2017-nile-climate\data\ethiopia-sorghum.txt'));
ethiopiaMilletYield = detrend(importdata('2017-nile-climate\data\ethiopia-millet.txt'));
ethiopiaBarleyYield = detrend(importdata('2017-nile-climate\data\ethiopia-barley.txt'));
ethiopiaWheatYield = detrend(importdata('2017-nile-climate\data\ethiopia-wheat.txt'));
ethiopiaPulsesYield = detrend(importdata('2017-nile-climate\data\ethiopia-pulses.txt'));
%ethiopiaCerealsYield = detrend(importdata('2017-nile-climate\data\ethiopia-cereals.txt'));

ethiopiaCattle = detrend(importdata('2017-nile-climate\data\ethiopia-cattle.txt'));
ethiopiaGoats = detrend(importdata('2017-nile-climate\data\ethiopia-goats.txt'));
ethiopiaChicken = detrend(importdata('2017-nile-climate\data\ethiopia-chicken.txt'));
ethiopiaCamels = detrend(importdata('2017-nile-climate\data\ethiopia-camels.txt'));
ethiopiaSheep = detrend(importdata('2017-nile-climate\data\ethiopia-sheep.txt'));
ethiopiaHorses = detrend(importdata('2017-nile-climate\data\ethiopia-horses.txt'));
ethiopiaAsses = detrend(importdata('2017-nile-climate\data\ethiopia-asses.txt'));

ethiopiaMaizeCal = importdata('2017-nile-climate\data\ethiopia-cal-maize.txt');
ethiopiaSorghumCal = importdata('2017-nile-climate\data\ethiopia-cal-sorghum.txt');
ethiopiaMilletCal = importdata('2017-nile-climate\data\ethiopia-cal-millet.txt');
ethiopiaBarleyCal = importdata('2017-nile-climate\data\ethiopia-cal-barley.txt');
ethiopiaWheatCal = importdata('2017-nile-climate\data\ethiopia-cal-wheat.txt');
ethiopiaPulsesCal = importdata('2017-nile-climate\data\ethiopia-cal-pulses.txt');
ethiopiaCerealsCal = importdata('2017-nile-climate\data\ethiopia-cal-cereals.txt');

ethiopiaMeanLivestock1 = nanmean([normc(ethiopiaCattle(1:32)), normc(ethiopiaGoats(1:32)), normc(ethiopiaChicken(1:32)), normc(ethiopiaCamels(1:32)), normc(ethiopiaSheep(1:32)), normc(ethiopiaHorses(1:32)), normc(ethiopiaAsses(1:32))], 2);
ethiopiaMeanLivestock2 = nanmean([normc(ethiopiaCattle(33:end)), normc(ethiopiaGoats(33:end)), normc(ethiopiaChicken(33:end)), normc(ethiopiaCamels(33:end)), normc(ethiopiaSheep(33:end)), normc(ethiopiaHorses(33:end)), normc(ethiopiaAsses(33:end))], 2);
ethiopiaMeanYield = nanmean([normc(ethiopiaMaizeYield) normc(ethiopiaSorghumYield) normc(ethiopiaMilletYield) normc(ethiopiaWheatYield) normc(ethiopiaPulsesYield)], 2);
%ethiopiaMeanYield = nanmean([ethiopiaMaizeYield ethiopiaSorghumYield ethiopiaMilletYield ethiopiaWheatYield ethiopiaPulsesYield], 2);
ethiopiaMeanCal = nanmean([normc(ethiopiaMaizeCal) normc(ethiopiaSorghumCal) normc(ethiopiaMilletCal) normc(ethiopiaBarleyCal) normc(ethiopiaWheatCal) normc(ethiopiaPulsesCal) normc(ethiopiaCerealsCal)], 2);

% yieldMaizeEthiopia_dt = ethiopiaMaizeYield - smooth(ethiopiaMaizeYield, 10); 
% yieldMilletEthiopia_dt = ethiopiaMilletYield - smooth(ethiopiaMilletYield, 10); 
% yieldBarleyEthiopia_dt = ethiopiaBarleyYield - smooth(ethiopiaBarleyYield, 10); 
% yieldWheatEthiopia_dt = ethiopiaWheatYield - smooth(ethiopiaWheatYield, 10); 
% yieldSorghumEthiopia_dt = ethiopiaSorghumYield - smooth(ethiopiaSorghumYield, 10);
% yieldCerealsEthiopia_dt = ethiopiaCerealsYield - smooth(ethiopiaCerealsYield, 10);

% cattleEthiopia_dt = ethiopiaCattle - smooth(ethiopiaCattle, 10);
% goatsEthiopia_dt = ethiopiaGoats - smooth(ethiopiaGoats, 10);
% calEthiopia_dt = ethiopiaMeanCal- smooth(ethiopiaMeanCal, 10);

cnt = 0;
cnthd_neg = 0;
cnthd_pos = 0;
cntd = 0;
cnth = 0;
cntw = 0;

for ph = 75
    for pl = 25
        prcHigh = ph;
        prcLow = pl;
        
        threshTEthiopiaHigh = prctile(udeltAnnualEthiopia(1:60), prcHigh);
        threshTEthiopiaLow = prctile(udeltAnnualEthiopia(1:60), prcLow);
        threshPAnnualEthiopiaLow = prctile(udelpAnnualEthiopia(1:60), prcLow);
        threshPAnnualEthiopiaHigh = prctile(udelpAnnualEthiopia(1:60), prcHigh);

        wYearsEthiopia = find(udelpAnnualEthiopia(61:end) > threshPAnnualEthiopiaHigh);
        hYearsEthiopia = find(udeltAnnualEthiopia(61:end) > threshTEthiopiaHigh & udelpAnnualEthiopia(61:end) > threshPAnnualEthiopiaLow);
        dYearsEthiopia = find(udelpAnnualEthiopia(61:end) < threshPAnnualEthiopiaLow & udeltAnnualEthiopia(61:end) < threshTEthiopiaHigh);
        hdYearsEthiopia = find(udelpAnnualEthiopia(61:end) < threshPAnnualEthiopiaLow & udeltAnnualEthiopia(61:end) > threshTEthiopiaHigh);


        [h_hd,p_hd, ci_hd] = ttest(ethiopiaMeanYield(hdYearsEthiopia));
        [h_d,p, ci_d] = ttest(ethiopiaMeanYield(dYearsEthiopia));
        [h_h,p, ci_h] = ttest(ethiopiaMeanYield(hYearsEthiopia));
        [h_w,p, ci_w] = ttest(ethiopiaMeanYield(wYearsEthiopia));

        
        live_hd = nanmean([ethiopiaMeanLivestock1(hdYearsEthiopia(hdYearsEthiopia<=32)); ethiopiaMeanLivestock2(hdYearsEthiopia(hdYearsEthiopia>32)-32)]);
        live_d = nanmean([ethiopiaMeanLivestock1(dYearsEthiopia(dYearsEthiopia<=32)); ethiopiaMeanLivestock2(dYearsEthiopia(dYearsEthiopia>32)-32)]);
        live_h = nanmean([ethiopiaMeanLivestock1(hYearsEthiopia(hYearsEthiopia<=32)); ethiopiaMeanLivestock2(hYearsEthiopia(hYearsEthiopia>32)-32)]);
        live_w = nanmean([ethiopiaMeanLivestock1(wYearsEthiopia(wYearsEthiopia<=32)); ethiopiaMeanLivestock2(wYearsEthiopia(wYearsEthiopia>32)-32)]);
        [h_lhd,p, ci_lhd] = ttest([livestockEthiopia1_dt(hdYearsEthiopia(hdYearsEthiopia<=32)); livestockEthiopia2_dt(hdYearsEthiopia(hdYearsEthiopia>32)-32)]);
        [h_ld,p, ci_ld] = ttest([livestockEthiopia1_dt(dYearsEthiopia(dYearsEthiopia<=32)); livestockEthiopia2_dt(dYearsEthiopia(dYearsEthiopia>32)-32)]);
        [h_lh,p, ci_lh] = ttest([livestockEthiopia1_dt(hYearsEthiopia(hYearsEthiopia<=32)); livestockEthiopia2_dt(hYearsEthiopia(hYearsEthiopia>32)-32)]);
        [h_lw,p, ci_lw] = ttest([livestockEthiopia1_dt(wYearsEthiopia(wYearsEthiopia<=32)); livestockEthiopia2_dt(wYearsEthiopia(wYearsEthiopia>32)-32)]);

        
        figure('Color', [1,1,1]);
        hold on;
        grid on;
        box on;
        axis square;

        colorD = [160, 116, 46]./255.0;
        colorHd = [216, 66, 19]./255.0;
        colorH = [255, 91, 206]./255.0;
        colorW = [68, 166, 226]./255.0;

        b = bar([1], [nanmean(ethiopiaMeanYield(hdYearsEthiopia))], .75, 'k');
        if h_hd
            set(b, 'facecolor', colorHd, 'linewidth', 6);
        else
            set(b, 'facecolor', colorHd);
        end
        plot(1, nanmean(ethiopiaMeanYield(hdYearsEthiopia)), 'ko', 'markersize', 15, 'markerfacecolor', 'k');
        e = errorbar(1, nanmean(ethiopiaMeanYield(hdYearsEthiopia)), nanmean(ethiopiaMeanYield(hdYearsEthiopia))-min(ci_hd), max(ci_hd)-nanmean(ethiopiaMeanYield(hdYearsEthiopia)));
        set(e, 'color', 'k', 'linewidth', 2);

        b = bar([2], [nanmean(ethiopiaMeanYield(dYearsEthiopia))], .75, 'k');
        if h_d
            set(b, 'facecolor', colorD, 'linewidth', 6);
        else
            set(b, 'facecolor', colorD);
        end
        plot(2, nanmean(ethiopiaMeanYield(dYearsEthiopia)), 'ko', 'markersize', 15, 'markerfacecolor', 'k');
        e = errorbar(2, nanmean(ethiopiaMeanYield(dYearsEthiopia)), nanmean(ethiopiaMeanYield(dYearsEthiopia))-min(ci_d), max(ci_d)-nanmean(ethiopiaMeanYield(dYearsEthiopia)));
        set(e, 'color', 'k', 'linewidth', 2);

        b = bar([3], [nanmean(ethiopiaMeanYield(hYearsEthiopia))], .75, 'k');
        if h_h
            set(b, 'facecolor', colorH, 'linewidth', 6);
        else
            set(b, 'facecolor', colorH);
        end
        plot(3, nanmean(ethiopiaMeanYield(hYearsEthiopia)), 'ko', 'markersize', 15, 'markerfacecolor', 'k');
        e = errorbar(3, nanmean(ethiopiaMeanYield(hYearsEthiopia)), nanmean(ethiopiaMeanYield(hYearsEthiopia))-min(ci_h), max(ci_h)-nanmean(ethiopiaMeanYield(hYearsEthiopia)));
        set(e, 'color', 'k', 'linewidth', 2);

        b = bar([4], [nanmean(ethiopiaMeanYield(wYearsEthiopia))], .75, 'k');
        if h_w
            set(b, 'facecolor', colorW, 'linewidth', 6);
        else
            set(b, 'facecolor', colorW);
        end
        plot(4, nanmean(ethiopiaMeanYield(wYearsEthiopia)), 'ko', 'markersize', 15, 'markerfacecolor', 'k');
        e = errorbar(4, nanmean(ethiopiaMeanYield(wYearsEthiopia)), nanmean(ethiopiaMeanYield(wYearsEthiopia))-min(ci_w), max(ci_w)-nanmean(ethiopiaMeanYield(wYearsEthiopia)));
        set(e, 'color', 'k', 'linewidth', 2);

        title(['T: ' num2str(ph) '%, P: ' num2str(pl) '%']);
        set(gca, 'fontsize', 36);
        set(gca, 'XTick', [1 2 3 4], 'XTickLabels', {'Hot + Dry', 'Dry', 'Hot', 'Wet'});
        %ylim([-40 15] .* 1e-3);
        %set(gca, 'YTick', [-20:5:15] .* 1e-3, 'YTickLabels', -20:5:15);
        ylabel('Normalized yield anomaly');%
        xtickangle(45);
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig(['crop-anomalies-' num2str(ph) '-' num2str(pl) '.eps']);
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
        plot(1, live_hd, 'ko', 'markersize', 15, 'markerfacecolor', 'k');
        e = errorbar(1, live_hd, live_hd-min(ci_lhd), max(ci_lhd)-live_hd);
        set(e, 'color', 'k', 'linewidth', 2);

        b = bar([2], live_d, .75, 'k');
        if h_ld
            set(b, 'facecolor', colorD, 'linewidth', 6);
        else
            set(b, 'facecolor', colorD);
        end
        plot(2, live_d, 'ko', 'markersize', 15, 'markerfacecolor', 'k');
        e = errorbar(2, live_d, live_d-min(ci_ld), max(ci_ld)-live_d);
        set(e, 'color', 'k', 'linewidth', 2);

        b = bar([3], live_h, .75, 'k');
        if h_lh
            set(b, 'facecolor', colorH, 'linewidth', 6);
        else
            set(b, 'facecolor', colorH);
        end
        plot(3, live_h, 'ko', 'markersize', 15, 'markerfacecolor', 'k');
        e = errorbar(3, live_h, live_h-min(ci_lh), max(ci_lh)-live_h);
        set(e, 'color', 'k', 'linewidth', 2);

        b = bar([4], live_w, .75, 'k');
        if h_lw
            set(b, 'facecolor', colorW, 'linewidth', 6);
        else
            set(b, 'facecolor', colorW);
        end
        plot(4, live_w, 'ko', 'markersize', 15, 'markerfacecolor', 'k');
        e = errorbar(4, live_w, live_w-min(ci_lw), max(ci_lw)-live_w);
        set(e, 'color', 'k', 'linewidth', 2);

        title(['T: ' num2str(ph) '%, P: ' num2str(pl) '%']);
        set(gca, 'fontsize', 36);
        set(gca, 'XTick', [1 2 3 4], 'XTickLabels', {'Hot + Dry', 'Dry', 'Hot', 'Wet'});
        ylim([-20 15] .* 1e-3);
        set(gca, 'YTick', [-20:5:15] .* 1e-3, 'YTickLabels', -20:5:15);
        ylabel('Normalized livestock anomaly');
        xtickangle(45);
        set(gcf, 'Position', get(0,'Screensize'));
        export_fig(['livestock-anomalies-' num2str(ph) '-' num2str(pl) '.eps']);
        close all;
        end
end