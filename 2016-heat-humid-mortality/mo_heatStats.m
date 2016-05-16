load nyMergedMortData

wbMin = mortData{2}(:,11);
wbMax = mortData{2}(:,12);
wbMean = mortData{2}(:,13);
tMin = mortData{2}(:,14);
tMax = mortData{2}(:,15);
tMean = mortData{2}(:,16);

% calculate month of year for each day
date = datenum('1987-01-01','yyyy-mm-dd');
moy = [];
for d = 1:length(wbMin)
    moy(d,1) = month(date);
    date = addtodate(date, 1, 'day');
end

indNotNan = find(~isnan(wbMean));
wbMean = wbMean(indNotNan);
wbMax = wbMax(indNotNan);
wbMin = wbMin(indNotNan);

tMean = tMean(indNotNan);
tMax = tMax(indNotNan);
tMin = tMin(indNotNan);
moy = moy(indNotNan);

x = 1:length(wbMean);
wbMeanFit = fit(x', wbMean, 'poly1');
wbMeanFitCi = confint(wbMeanFit, .95);

wbMaxFit = fit(x', wbMax, 'poly1');
wbMaxFitCi = confint(wbMaxFit, .95);

wbMinFit = fit(x', wbMin, 'poly1');
wbMinFitCi = confint(wbMinFit, .95);

wbMeanFitY = wbMeanFit(x);
wbMaxFitY = wbMaxFit(x);
wbMinFitY = wbMinFit(x);

tMeanFit = fit(x', tMean, 'poly1');
tMeanFitCi = confint(tMeanFit, .95);

tMaxFit = fit(x', tMax, 'poly1');
tMaxFitCi = confint(tMaxFit, .95);

tMinFit = fit(x', tMin, 'poly1');
tMinFitCi = confint(tMinFit, .95);

tMeanFitY = tMeanFit(x);
tMaxFitY = tMaxFit(x);
tMinFitY = tMinFit(x);

% deg C/year
wbMeanFitInc = roundn(wbMeanFit.p1 * 365, -3);
wbMeanFitIncCi = wbMeanFitInc - roundn(wbMeanFitCi(1, 1) * 365, -2);

wbMaxFitInc = roundn(wbMaxFit.p1 * 365, -3);
wbMaxFitIncCi = wbMaxFitInc - roundn(wbMaxFitCi(1, 1) * 365, -2);

wbMinFitInc = roundn(wbMinFit.p1 * 365, -3);
wbMinFitIncCi = wbMinFitInc - roundn(wbMinFitCi(1, 1) * 365, -2);

tMeanFitInc = roundn(tMeanFit.p1 * 365, -3);
tMeanFitIncCi = tMeanFitInc - roundn(tMeanFitCi(1, 1) * 365, -2);

tMaxFitInc = roundn(tMaxFit.p1 * 365, -3);
tMaxFitIncCi = tMaxFitInc - roundn(tMaxFitCi(1, 1) * 365, -2);

tMinFitInc = roundn(tMinFit.p1 * 365, -3);
tMinFitIncCi = tMinFitInc - roundn(tMinFitCi(1, 1) * 365, -2);

xAxis = linspace(1987, 2001, length(x));

plotTrends = false;

if plotTrends
    figure('Color', [1,1,1]);
    s = suptitle('NYC temperature trends');
    set(s, 'FontSize', 30);

    subplot(1, 2, 1);
    hold on;
    plot(xAxis, wbMean,'k');
    plot(xAxis, wbMinFitY, 'b', 'LineWidth', 2);
    plot(xAxis, wbMeanFitY, 'g', 'LineWidth', 2);
    plot(xAxis, wbMaxFitY, 'r', 'LineWidth', 2);
    xlim([1986 2001]);
    xlabel('Year', 'FontSize', 24);
    ylabel('Deg C', 'FontSize', 24);
    set(gca, 'FontSize', 20);
    legend('mean wet-bulb', ...
           ['min wet-bulb fit (' num2str(wbMinFitInc) ' +/- ' num2str(wbMinFitIncCi) ' deg C/yr)'], ...
           ['mean wet-bulb fit (' num2str(wbMeanFitInc) ' +/- ' num2str(wbMeanFitIncCi) ' deg C/yr)'], ...
           ['max wet-bulb fit (' num2str(wbMaxFitInc) ' +/- ' num2str(wbMaxFitIncCi) ' deg C/yr)']);

    subplot(1, 2, 2);
    hold on;
    plot(xAxis, tMean,'k');
    plot(xAxis, tMinFitY, 'b', 'LineWidth', 2);
    plot(xAxis, tMeanFitY, 'g', 'LineWidth', 2);
    plot(xAxis, tMaxFitY, 'r', 'LineWidth', 2);
    xlim([1986 2001]);
    xlabel('Year', 'FontSize', 24);
    ylabel('Deg C', 'FontSize', 24);
    set(gca, 'FontSize', 20);
    legend('mean temperature', ...
           ['min temperature fit (' num2str(tMinFitInc) ' +/- ' num2str(tMinFitIncCi) ' deg C/yr)'], ...
           ['mean temperature fit (' num2str(tMeanFitInc) ' +/- ' num2str(tMeanFitIncCi) ' deg C/yr)'], ...
           ['max temperature fit (' num2str(tMaxFitInc) ' +/- ' num2str(wbMaxFitIncCi) ' deg C/yr)']);
end

plotMonthlyTrends = false;

if plotMonthlyTrends
    curMonth = 1;
    curTSum = 0;
    curWbSum = 0;
    monthLen = 0;
    
    monthlyTMeans = {};
    monthlyWbMeans = {}
    for m = 1:12
        monthlyTMeans{m} = [];
        monthlyWbMeans{m} = [];
    end
    
    monthlyTTrends = [];
    monthlyTCi = [];
    monthlyWbTrends = [];
    monthlyWbCi = [];
    
    for d = 1:length(moy)
        if moy(d) ~= curMonth || d == length(moy)
            monthlyTMeans{curMonth}(end+1) = curTSum / monthLen;
            monthlyWbMeans{curMonth}(end+1) = curWbSum / monthLen;
            monthLen = 0;
            curTSum = 0;
            curWbSum = 0;
            curMonth = moy(d);
        end
        
        curTSum = curTSum + tMean(d);
        curWbSum = curWbSum + wbMean(d);
        monthLen = monthLen + 1;
    end
    
    for m = 1:12
        x = 1:length(monthlyTMeans{m});
        fT = fit(x', monthlyTMeans{m}', 'poly1');
        fWb = fit(x', monthlyWbMeans{m}', 'poly1');
        monthlyTTrends(m) = fT.p1;
        ci = confint(fT);
        monthlyTCi(m, :) = ci(:, 1);
        
        monthlyWbTrends(m) = fWb.p1;
        ci = confint(fWb);
        monthlyWbCi(m, :) = ci(:, 1);
    end
    
    djfT = (monthlyTTrends(12)+monthlyTTrends(1)+monthlyTTrends(2))/3;
    djfTCi = (monthlyTCi(12,:)+monthlyTCi(1,:)+monthlyTCi(2,:))./3;
    
    mamT = (monthlyTTrends(3)+monthlyTTrends(4)+monthlyTTrends(5))/3;
    mamTCi = (monthlyTCi(3,:)+monthlyTCi(4,:)+monthlyTCi(5,:))./3;
    
    jjaT = (monthlyTTrends(6)+monthlyTTrends(7)+monthlyTTrends(8))/3;
    jjaTCi = (monthlyTCi(6,:)+monthlyTCi(7,:)+monthlyTCi(8,:))./3;
    
    sonT = (monthlyTTrends(9)+monthlyTTrends(10)+monthlyTTrends(11))/3;
    sonTCi = (monthlyTCi(9,:)+monthlyTCi(10,:)+monthlyTCi(11,:))./3;
    
    djfWb = (monthlyWbTrends(12)+monthlyWbTrends(1)+monthlyWbTrends(2))/3;
    djfWbCi = (monthlyWbCi(12,:)+monthlyWbCi(1,:)+monthlyWbCi(2,:))./3;
    
    mamWb = (monthlyWbTrends(3)+monthlyWbTrends(4)+monthlyWbTrends(5))/3;
    mamWbCi = (monthlyWbCi(3,:)+monthlyWbCi(4,:)+monthlyWbCi(5,:))./3;
    
    jjaWb = (monthlyWbTrends(6)+monthlyWbTrends(7)+monthlyWbTrends(8))/3;
    jjaWbCi = (monthlyWbCi(6,:)+monthlyWbCi(7,:)+monthlyWbCi(8,:))./3;
    
    sonWb = (monthlyWbTrends(9)+monthlyWbTrends(10)+monthlyWbTrends(11))/3;
    sonWbCi = (monthlyWbCi(9,:)+monthlyWbCi(10,:)+monthlyWbCi(11,:))./3;
    
    %figure('Color', [1,1,1]);
    subplot(1,2,2);
    hold on;
    f1 = plot([1 2 3 4], [djfT mamT jjaT sonT], 'k', 'LineWidth', 3);
    plot([1 2 3 4], [djfTCi(1) mamTCi(1) jjaTCi(1) sonTCi(1)], ':k', 'LineWidth', 2);
    plot([1 2 3 4], [djfTCi(2) mamTCi(2) jjaTCi(2) sonTCi(2)], ':k', 'LineWidth', 2);
    
    f2 = plot([1 2 3 4], [djfWb mamWb jjaWb sonWb], 'b', 'LineWidth', 3);
    plot([1 2 3 4], [djfWbCi(1) mamWbCi(1) jjaWbCi(1) sonWbCi(1)], ':b', 'LineWidth', 2);
    plot([1 2 3 4], [djfWbCi(2) mamWbCi(2) jjaWbCi(2) sonWbCi(2)], ':b', 'LineWidth', 2);
    
    plot([1 2 3 4], [0 0 0 0], 'Color', [0.5 0.5 0.5], 'LineStyle', '--', 'LineWidth', 2);
    
    ylim([-0.3 0.6]);
    set(gca, 'xtick', [1 2 3 4], 'xticklabel', {'DJF', 'MAM', 'JJA', 'SON'});
    xlabel('Season', 'FontSize', 24);
    ylabel('Deg C/yr', 'FontSize', 24);
    legend([f1,f2], {'Temperature', 'Wet-bulb'});
    set(gca, 'FontSize', 20);
    title('Seasonal temperature trends', 'FontSize', 30);
    
end

prc = 0:10:90;
prcTrends = [];
tempVars = [tMin tMean tMax];
colors = {'b', 'g', 'r'};
figure('Color', [1,1,1]);
hold on;
for t = 1:size(tempVars, 2)
    tempVar = tempVars(:, t);
    for p = 1:length(prc)
        thresh = prctile(tempVar, prc(p));
        tempsSel = [];
        if p < length(prc)
            threshUp = prctile(tempVar, prc(p+1));
            ind = find(tempVar >= thresh & tempVar < threshUp);
            tempsSel = tempVar(ind);
        else
            ind = find(tempVar >= thresh);
            tempsSel = tempVar(ind);
        end

        x = 1:length(ind);
        f = fit(x', tempsSel, 'poly1');
        prcTrends(p) = f.p1*365;
    end
    plot(prc, prcTrends, colors{t}, 'LineWidth', 2);
end

plot(prc, zeros(length(prc), 1), 'Color', [0.5 0.5 0.5], 'LineStyle', ':', 'LineWidth', 2);
xlabel('Percentile', 'FontSize', 24);
ylabel('Deg C/yr', 'FontSize', 24);
title('Trends in the temperature distribution', 'FontSize', 30);
set(gca, 'FontSize', 20);
legend('Daily minimum temperature', 'Daily mean temperature', 'Daily maximum temperature');






