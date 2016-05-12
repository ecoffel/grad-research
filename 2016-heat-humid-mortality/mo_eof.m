load nyMergedMortData;
addpath('2016-heat-humid-mortality/pcatool');

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

data = deathsDetrend;
time = length(data);

[eof, pc, err] = calEeof(data, 5, 1, 49, 1);

figure('Color', [1, 1, 1]);

xAxis = linspace(1987, 2001, size(pc, 2));

subplot(2, 1, 1);
hold on;
plot(xAxis, pc(1,:), 'k', 'LineWidth', 2);
plot(xAxis, 0, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 2);
ylim([-100 150]);
for i = 1:14
    % plot jan 1 vertical bars
    plot(xAxis(round(length(xAxis)/14 * (i - 1) + 1)), -100:100, 'b--');
    
    % plot jul 15 vertical bars
    plot( xAxis( round( length(xAxis)/14 * ((i + 0.625) - 1) + 1 )), -100:100, 'r--');
end
xlabel('Year', 'FontSize', 24);
ylabel('Daily mortality anomaly', 'FontSize', 24);
title('1st PC of detrended daily NYC mortality', 'FontSize', 30);
set(gca, 'FontSize', 20);

subplot(2, 1, 2);
hold on;
plot(xAxis, pc(2,:), 'k', 'LineWidth', 2);
plot(xAxis, 0, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 2);
ylim([-100 150]);
xlabel('Year', 'FontSize', 24);
ylabel('Daily mortality anomaly', 'FontSize', 24);
title('2st PC of detrended daily NYC mortality', 'FontSize', 30);
set(gca, 'FontSize', 20);


