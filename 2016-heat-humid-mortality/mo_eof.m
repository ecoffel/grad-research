load nyMergedMortData;
addpath('2016-heat-humid-mortality/pcatool');

deaths = mortData{2}(:,5);
wbMin = mortData{2}(:,11);
wbMax = mortData{2}(:,12);
wbMean = mortData{2}(:,13);
tMin = mortData{2}(:,14);
tMax = mortData{2}(:,15);
tMean = mortData{2}(:,16);

indNotNan = find(~isnan(wbMean) & ~isnan(tMean));

% deaths = deaths(indNotNan);
% wbMean = wbMean(indNotNan);
% wbMax = wbMax(indNotNan);
% tMean = tMean(indNotNan);
% tMax = tMax(indNotNan);

deathsDetrend = detrend(deaths - nanmean(deaths));

data = deathsDetrend;
time = length(data);

pcLen = 30;
heatWaveLen = 4;
[eof, pc, err] = calEeof(data, 5, 1, pcLen, 1);

% starting dates of heat waves for each n
[heatWaveInd, prcTest] = mo_findHeatWaves(tempVar);

shouldPlot = true;

if shouldPlot
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
    
    for i = 1:length(heatWaveInd{heatWaveLen}{end})
        plot(xAxis(heatWaveInd{heatWaveLen}{end}(i)), -100:100, 'r--');
    end
    
    xlabel('Year', 'FontSize', 24);
    ylabel('Daily mortality anomaly', 'FontSize', 24);
    title('2nd PC of detrended daily NYC mortality', 'FontSize', 30);
    set(gca, 'FontSize', 20);
end


