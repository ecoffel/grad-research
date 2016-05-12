load nyMergedMortData

deaths = mortData{2}(:,5);
wbMax = mortData{2}(:,14);
wbMin = mortData{2}(:,15);
wbMean = mortData{2}(:,16);
tMin = mortData{2}(:,12);
tMax = mortData{2}(:,11);
tMean = mortData{2}(:,13);

indNotNan = find(~isnan(wbMean) & ~isnan(tMean));

deaths = deaths(indNotNan);
deathsDetrend = detrend(deaths - nanmean(deaths));

wbMean = wbMean(indNotNan);
wbMax = wbMax(indNotNan);
wbMin = wbMin(indNotNan);
tMean = tMean(indNotNan);
tMax = tMax(indNotNan);
tMin = tMin(indNotNan);

data = tMean;

% 2 years
maxlag = 365*2;

[acf, lags] = xcorr(data, maxlag);

figure('Color', [1, 1, 1]);
hold on;
plot(lags, acf, 'k', 'LineWidth', 2);

xlabel('Lag (days)', 'FontSize', 26);
%ylabel('Daily death anomaly', 'FontSize', 20);
title('Daily mean temperature autocorrelation', 'FontSize', 30);
set(gca, 'FontSize', 24);

