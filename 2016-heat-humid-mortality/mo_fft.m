load nyMergedMortData

deaths = mortData{2}(:,5);
wbMax = mortData{2}(:,14);
wbMean = mortData{2}(:,16);
tMax = mortData{2}(:,11);
tMean = mortData{2}(:,13);

indNotNan = find(~isnan(wbMean) & ~isnan(tMean));

deaths = deaths(indNotNan);
wbMean = wbMean(indNotNan);
wbMax = wbMax(indNotNan);
tMean = tMean(indNotNan);
tMax = tMax(indNotNan);

deathsDetrend = detrend(deaths - nanmean(deaths));

tempLag = mo_laggedTemp(tMean, 0:3, ones(length(0:3),1) ./ 4.0);
wbLag = mo_laggedTemp(wbMean, 0:4, ones(length(0:4),1) ./ 5.0);

data = wbMean;

Fs = 1;
t = 1:length(data);
L = length(data);

freq = Fs*(0:(L/2))/L*365;
f = fft(data, length(data));
p2 = abs(f/L);
p1 = p2(1:L/2+1);
p1(2:end-1) = 2*p1(2:end-1);

s = std(p1);

figure('Color', [1, 1, 1]);
hold on;
plot(freq, p1, 'k', 'LineWidth', 2);
plot(freq, s, 'k--', 'LineWidth', 2);
plot(freq, 2*s, 'k:', 'LineWidth', 2);
xlim([0 5]);
ylim([0 12]);
xlabel('Frequency (years)', 'FontSize', 26);
ylabel('Power (deg C)', 'FontSize', 26);
title('FFT of NYC daily mean wet-bulb temperature', 'FontSize', 30);
set(gca, 'FontSize', 24);
