load nyMergedMortData;

deaths = mortData{2}(:,5);
wbMin = mortData{2}(:,11);
wbMax = mortData{2}(:,12);
wbMean = mortData{2}(:,13);
tMin = mortData{2}(:,14);
tMax = mortData{2}(:,15);
tMean = mortData{2}(:,16);

indNotNan = find(~isnan(wbMean) & ~isnan(tMean));

deaths = deaths(indNotNan);
wbMean = wbMean(indNotNan);
wbMax = wbMax(indNotNan);
wbMin = wbMin(indNotNan);
tMean = tMean(indNotNan);
tMax = tMax(indNotNan);
tMin = tMin(indNotNan);

deathsDetrend = detrend(deaths - nanmean(deaths));

tempVar = wbMean;

lags = 2:5

figure('Color', [1, 1, 1]);

for l = 1:length(lags)
    lag = lags(l);
    laggedDeaths = [];
    laggedTemps = [];

    for i = 1:length(tempVar) - lag(end)

        meanDeaths = 0;
        meanTemp = 0;
        for j = i:i+lag(end)
            meanDeaths = meanDeaths + deathsDetrend(j);
            meanTemp = meanTemp + tempVar(j);
        end

        meanDeaths = meanDeaths/(lag + 1);
        meanTemp = meanTemp/(lag + 1);
        laggedDeaths(i) = meanDeaths;
        laggedTemps(i) = meanTemp;

    end

    f = fit(laggedTemps', laggedDeaths', 'poly6');
    fCi = predint(f, laggedTemps', 0.95, 'functional','on');
    
    subplot(length(lags)/2, length(lags)/2, l);
    hold on;
    p1 = plot(laggedTemps, laggedDeaths, 'k*');
    fitLine = plot(f);
    plot(laggedTemps, fCi, '--b');
    xlim([-10 40]);
    ylim([-20 40]);
    set(fitLine, 'Color', [1, 0, 0], 'LineWidth', 2);
    xlabel('Temperature (deg C)', 'FontSize', 20);
    ylabel('Daily mortality anomaly', 'FontSize', 20);
    title([num2str(lags(l)) '-day lagged average'], 'FontSize', 24);
    set(gca, 'FontSize', 18);
    b = gca; legend(b,'off');
    %legend([fitLine], ['6-order polynomial fit']);
end

s = suptitle('Daily mean wet-bulb temperature');
set(s, 'FontSize', 30);


