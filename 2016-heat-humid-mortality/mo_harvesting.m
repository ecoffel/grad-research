addpath('2016-heat-humid-mortality/pcatool');
load nyMergedMortData

deaths = mortData{2}(:,5);
wbMin = mortData{2}(:,11);
wbMax = mortData{2}(:,12);
wbMean = mortData{2}(:,13);
tMin = mortData{2}(:,14);
tMax = mortData{2}(:,15);
tMean = mortData{2}(:,16);

% deaths = deaths(indNotNan);
% wbMean = wbMean(indNotNan);
% wbMax = wbMax(indNotNan);
% wbMin = wbMin(indNotNan);
% tMean = tMean(indNotNan);
% tMax = tMax(indNotNan);
% tMin = tMin(indNotNan);

tempVar = wbMean;

% remove linear trend and mean
deathsDetrend = detrend(deaths - nanmean(deaths));

% moving average
deathsMovAvg = tsmovavg(deathsDetrend, 's', 30, 1);

% remove moving average from detrended deaths data so that we are looking
% at death anomalies for the proper season (since summer deaths are lower
% than winter)
deathsData = deathsDetrend-deathsMovAvg;

indNotNan = find(~isnan(wbMean) & ~isnan(tMean) & ~isnan(deathsData));

figure('Color', [1,1,1]);
s = suptitle('Death data');
set(s, 'FontSize', 30);

s1 = subplot(2,1,1);
hold on;
p1 = plot(deathsDetrend, 'k');
p2 = plot(deathsMovAvg, 'r','LineWidth',2);
xlim([0 5500]);
ylim([-40 50]);
legend(s1, 'detrended mortality', '30 day moving average');
set(gca, 'FontSize', 20);
xlabel('Days', 'FontSize', 24);
ylabel('Daily death anomaly', 'FontSize', 24);

s2 = subplot(2,1,2);
hold on;
p3 = plot(deathsData, 'k');
xlim([0 5500]);
ylim([-40 50]);
legend(s2, 'detrended mortality minus moving average');
set(gca, 'FontSize', 20);
xlabel('Days', 'FontSize', 24);
ylabel('Daily death anomaly', 'FontSize', 24);



% heat wave length
heatLengths = [2 3 4 5];

% starting dates of heat waves for each n
[heatWaveInd, prcTest] = mo_findHeatWaves(tempVar);

% how far on either side of the heat wave to look at death anomalies
testLen = -10:heatLength+10;

prc = length(prcTest)-4:length(prcTest);

figure('Color', [1,1,1]);

for l = 1:length(heatLengths)
    heatLength = heatLengths(l);
    heatWaveDeaths = [];
    
    for p = prc

        if length(heatWaveInd{heatLength}{p}) < 5
            continue;
        end

        % find daily death anomalies 3 days before, during, and after heat
        % event
        curHeatWaveDeaths = [];

        % loop over all heat events for this percentile
        for h = 1:length(heatWaveInd{heatLength}{p})
            curHeatInd = heatWaveInd{heatLength}{p}(h);

            % if we are too close to the end of the deaths list
            if curHeatInd + testLen(1) < 1 || curHeatInd + testLen(end) > length(deathsData)
                continue;
            end

            for i = 1:length(testLen)
                ind = curHeatInd + testLen(i);
                curHeatWaveDeaths(i, h) = deathsData(ind);
            end

        end

        heatWaveDeaths = [heatWaveDeaths squeeze(nanmean(curHeatWaveDeaths, 2))];
        %heatWaveDeathsStd = [heatWaveDeathsStd squeeze(nanmean(curHeatWaveDeathsStd, 2))];

    end

    colors = distinguishable_colors(size(heatWaveDeaths,2));

    subplot(2, 2, l);
    hold on;
    legendStr = 'legend(';
    for i = 1:size(heatWaveDeaths, 2)
        plot(testLen, heatWaveDeaths(:, i), 'Color', colors(i, :), 'LineWidth', 2);

        if i == size(heatWaveDeaths, 2)
            legendStr = [legendStr '''percentile = ' num2str(prcTest(prc(i))) ''')'];
        else
            legendStr = [legendStr '''percentile = ' num2str(prcTest(prc(i))) ''','];
        end
    end

    %plot(testLen, deathsDetrendStd, 'k--', 'LineWidth', 2);
    %plot(testLen, -deathsDetrendStd, 'k--', 'LineWidth', 2);
    plot(testLen, zeros(length(testLen), 1), '--', 'LineWidth', 2, 'Color', [0.5 0.5 0.5]);
    plot(zeros(length(-10:10),1), -10:10, '--', 'LineWidth', 2, 'Color', [0.5 0.5 0.5]);
    
    ylim([-10 10]);
    xlabel('Offset from start of heat wave (days)', 'FontSize', 20);
    ylabel('Daily death anomaly', 'FontSize', 20);
    title(['Daily mean wet-bulb temperature, n = ' num2str(heatLength)], 'FontSize', 24);
    eval(legendStr);
end



