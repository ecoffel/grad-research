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
wbMean = wbMean(indNotNan);
wbMax = wbMax(indNotNan);
tMean = tMean(indNotNan);
tMax = tMax(indNotNan);

deathsDetrend = detrend(deaths - nanmean(deaths));

tempLag = mo_laggedTemp(tMean, 3);
wbLag = mo_laggedTemp(wbMean, 3);

dataSets = [tempLag wbLag deaths(4:end) deathsDetrend(4:end)];
dataTitles = {'3-day lagged daily mean temperature', '3-day lagged daily mean wet-bulb temperature', 'Daily mortality', 'Detrended mortality anomalies'};
dataYLabels = {'Power (deg C)', 'Power (deg C)', 'Power (deaths/day)', 'Power (deaths/day)'};

figure('Color', [1, 1, 1]);

for d = 1:size(dataSets, 2)
    data = dataSets(:, d);
    
    Fs = 1;
    t = 1:length(data);
    L = length(data);

    freq = Fs*(0:(L/2))/L*365;
    f = fft(data, length(data));
    p2 = abs(f/L);
    p1 = p2(1:L/2+1);
    p1(2:end-1) = 2*p1(2:end-1);

    s = std(p1);

    subplot(2, 2, d);
    hold on;
    plot(freq, p1, 'k', 'LineWidth', 2);
    plot(freq, s, 'k--', 'LineWidth', 2);
    plot(freq, 2*s, 'k:', 'LineWidth', 2);
    xlim([0 5]);
    ylim([0 12]);
    xlabel('Frequency (years)', 'FontSize', 24);
    ylabel(dataYLabels{d}, 'FontSize', 24);
    title(dataTitles{d}, 'FontSize', 26);
    set(gca, 'FontSize', 24);
end

s = suptitle('FFT');
set(s, 'FontSize', 30);
