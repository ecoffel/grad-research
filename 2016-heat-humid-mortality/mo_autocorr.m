load nyMergedMortData

deaths = mortData{2}(:,5);
wbMin = mortData{2}(:,11);
wbMax = mortData{2}(:,12);
wbMean = mortData{2}(:,13);
tMin = mortData{2}(:,14);
tMax = mortData{2}(:,15);
tMean = mortData{2}(:,16);

indNotNan = find(~isnan(wbMean) & ~isnan(tMean));

deaths = deaths(indNotNan);
deathsDetrend = detrend(deaths - nanmean(deaths));

wbMean = wbMean(indNotNan);
wbMax = wbMax(indNotNan);
wbMin = wbMin(indNotNan);
tMean = tMean(indNotNan);
tMax = tMax(indNotNan);
tMin = tMin(indNotNan);

dataSources = [wbMean tMean deaths deathsDetrend];
dataTitles = {'Mean wet-bulb temperature', 'Mean temperature', 'Daily mortality', 'Detrended daily mortality'};

% 2 years
maxlag = 365*2;
figure('Color', [1, 1, 1]);


for d = 1:size(dataSources, 2)
    data = dataSources(:, d);
    [acf, lags] = xcorr(data, maxlag);

    subplot(2, 2, d);
    hold on;
    plot(lags, acf, 'k', 'LineWidth', 2);
    xlabel('Lag (days)', 'FontSize', 24);
    title(dataTitles{d}, 'FontSize', 26);
    set(gca, 'FontSize', 20);
end

s = suptitle('Autocorrelations');
set(s, 'FontSize', 30);

