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
wbMin = wbMin(indNotNan);
tMean = tMean(indNotNan);
tMax = tMax(indNotNan);
tMin = tMin(indNotNan);

tempVar = wbMax;

% remove linear trend and mean
deathsDetrend = detrend(deaths - nanmean(deaths));

% death anomalies for each percentile
prcAnom = [];

figure('Color', [1,1,1]);
hold on;
legendStr = 'legend(';

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
                s = s + deathsDetrend(heatWaveInd{n}{p}(i) + j);
            end
            s = s / length(testLen);
            heatWaveDeaths(i) = s;
        end

        % if there aren't enough heat waves, skip this n
        if length(heatWaveInd{n}{p}) < 30
            prcAnom(n, p) = NaN;
        else
            prcAnom(n, p) = mean(heatWaveDeaths);
        end
    end
    
    plot(prcTest(1:end), prcAnom(n, :), 'Color', colors(n, :), 'LineWidth', 2);
    
    if n == length(heatWaveInd)
        legendStr = [legendStr '''n = ' num2str(n) ''')'];
    else
        legendStr = [legendStr '''n = ' num2str(n) ''','];
    end
    
end

eval(legendStr);
ylim([-3 8]);
xlabel('Percentile', 'FontSize', 20);
ylabel('Daily death anomaly', 'FontSize', 20);
title('Daily maximum wet-bulb temperature', 'FontSize', 24);


