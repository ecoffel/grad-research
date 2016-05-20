load nyMergedMortData

deaths = mortData{2}(:,5);
wbMin = mortData{2}(:,11);
wbMax = mortData{2}(:,12);
wbMean = mortData{2}(:,13);
tMin = mortData{2}(:,14);
tMax = mortData{2}(:,15);
tMean = mortData{2}(:,16);

% remove linear trend and mean
deathsDetrend = detrend(deaths - nanmean(deaths));

% moving average
deathsMovAvg = tsmovavg(deathsDetrend, 's', 30, 1);

% remove moving average from detrended deaths data so that we are looking
% at death anomalies for the proper season (since summer deaths are lower
% than winter)
deathsData = deathsDetrend-deathsMovAvg;

indNotNan = find(~isnan(wbMean) & ~isnan(tMean) & ~isnan(deathsData));
deathsData = deathsData(indNotNan);
wbMin = wbMin(indNotNan);
wbMean = wbMean(indNotNan);
tMean = tMean(indNotNan);
tMin = tMin(indNotNan);
tMax = tMax(indNotNan);

tempVars = [wbMean tMean wbMin tMin];
tempVarNames = {'Mean wet-bulb temperature', 'Mean temperature', 'Minimum wet-bulb temperature', 'Minimum temperature'};

figure('Color', [1,1,1]);
hold on;

for t = 1:size(tempVars, 2)
    tempVar = tempVars(:, t);

    subplot(2, 2, t);
    hold on;
	legendStr = 'legend(';
    
    % death anomalies for each percentile
    prcAnom = [];
    prcStd = [];

    % starting dates of heat waves for each n
    [heatWaveInd, prcTest] = mo_findHeatWaves(tempVar);

    colors = distinguishable_colors(length(heatWaveInd));

    for n = 1:length(heatWaveInd)
        for p = 1:length(prcTest)

            % find death anomalies during heat waves and 3 days after
            heatWaveDeaths = [];
            testLen = 0:4;
            for i = 1:length(heatWaveInd{n}{p}) - length(testLen)
                s = 0;
                for j = testLen
                    s = s + deathsData(heatWaveInd{n}{p}(i) + j);
                end
                s = s / length(testLen);
                heatWaveDeaths(i) = s;
            end

            % if there aren't enough heat waves, skip this n
            if length(	{n}{p}) < 5
                prcAnom(n, p) = NaN;
                prcStd(n, p) = NaN;
            else
                prcAnom(n, p) = mean(heatWaveDeaths);
                prcStd(n, p) = std(heatWaveDeaths);
            end
        end

        plot(prcTest(1:end), prcAnom(n, :), 'Color', colors(n, :), 'LineWidth', 2);

        if n == length(heatWaveInd)
            legendStr = [legendStr '''n = ' num2str(n) ''', ''Orientation'', ''horizontal'')'];
        else
            legendStr = [legendStr '''n = ' num2str(n) ''','];
        end

    end

    errorbar(prcTest(1:end), prcAnom(4, :), prcStd(4, :), 'Color', [0.5 0.5 0.5]);

    eval(legendStr);
    plot(0:100, zeros(length(0:100), 1), '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 2);
    xlim([0 110]);
    ylim([-10 10]);
    set(gca, 'FontSize', 20);
    xlabel('Percentile', 'FontSize', 24);
    ylabel('Daily death anomaly', 'FontSize', 24);
    title(tempVarNames{t}, 'FontSize', 30);
end


