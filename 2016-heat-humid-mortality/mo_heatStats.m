load nyMergedMortData

wbMin = mortData{2}(:,11);
wbMax = mortData{2}(:,12);
wbMean = mortData{2}(:,13);
tMin = mortData{2}(:,14);
tMax = mortData{2}(:,15);
tMean = mortData{2}(:,16);

indNotNan = find(~isnan(wbMean));
wbMean = wbMean(indNotNan);
wbMax = wbMax(indNotNan);
wbMin = wbMin(indNotNan);

tMean = tMean(indNotNan);
tMax = tMax(indNotNan);
tMin = tMin(indNotNan);

x = 1:length(wbMean);
wbMeanFit = fit(x', wbMean, 'poly1');
wbMaxFit = fit(x', wbMax, 'poly1');
wbMinFit = fit(x', wbMin, 'poly1');
wbMeanFitY = wbMeanFit(x);
wbMaxFitY = wbMaxFit(x);
wbMinFitY = wbMinFit(x);

tMeanFit = fit(x', tMean, 'poly1');
tMaxFit = fit(x', tMax, 'poly1');
tMinFit = fit(x', tMin, 'poly1');
tMeanFitY = tMeanFit(x);
tMaxFitY = tMaxFit(x);
tMinFitY = tMinFit(x);

% deg C/year
wbMeanFitInc = roundn(wbMeanFit.p1 * 365, -3);
wbMaxFitInc = roundn(wbMaxFit.p1 * 365, -3);
wbMinFitInc = roundn(wbMinFit.p1 * 365, -3);

tMeanFitInc = roundn(tMeanFit.p1 * 365, -3);
tMaxFitInc = roundn(tMaxFit.p1 * 365, -3);
tMinFitInc = roundn(tMinFit.p1 * 365, -3);

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
           ['min wet-bulb fit (' num2str(wbMinFitInc) ' deg C/yr'], ...
           ['mean wet-bulb fit (' num2str(wbMeanFitInc) ' deg C/yr'], ...
           ['max wet-bulb fit (' num2str(wbMaxFitInc) ' deg C/yr']);

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
           ['min temperature fit (' num2str(tMinFitInc) ' deg C/yr'], ...
           ['mean temperature fit (' num2str(tMeanFitInc) ' deg C/yr'], ...
           ['max temperature fit (' num2str(tMaxFitInc) ' deg C/yr']);
end


heatWaveInd = mo_findHeatWaves(





