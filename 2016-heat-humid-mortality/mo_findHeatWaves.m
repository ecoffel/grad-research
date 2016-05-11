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

tempVar = wbMax;

% remove linear trend and mean
deathsDetrend = detrend(deaths - nanmean(deaths));

% percentiles to test death anomalies
prcTest = 5:5:95;

% death anomalies for each percentile
prcAnom = [];

figure('Color', [1,1,1]);
hold on;
legendStr = 'legend(';

% heat wave length
heatLength = 1:7;

colors = distinguishable_colors(length(heatLength));

% starting dates of heat waves for each n
heatWaveInd = {};

for n = heatLength
    heatWaveInd{n} = {};
    for p = 1:length(prcTest)
            
        % define heat wave as 3 consec days above 90th percentile of tMax
        tempThresh = prctile(tempVar, prcTest(p));

        % find starting dates of heat waves
        heatWaveInd{n}{p} = [];
        for i = 1:length(tempVar)-(n-1)

            % search for a heat wave
            wave = true;

            for j = 1:n
                if tempVar(i+j-1) < tempThresh
                    wave = false;
                    break;
                end
            end

            if wave
                heatWaveInd{n}{p}(end+1) = i;
            end

            % skip to next non heat wave day
            while tempVar(i) >= tempThresh && i < length(tempVar)
                i = i + 1;
            end
        end
        
        % find death anomalies during heat waves and 2 days after
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
    
    plot(prcTest, prcAnom(n, :), 'Color', colors(n, :), 'LineWidth', 2);
    
    if n == length(heatLength)
        legendStr = [legendStr '''n = ' num2str(n) ''')'];
    else
        legendStr = [legendStr '''n = ' num2str(n) ''','];
    end
    
end

eval(legendStr);
ylim([-3 6]);
xlabel('Percentile', 'FontSize', 20);
ylabel('Daily death anomaly', 'FontSize', 20);
title('Daily maximum wet-bulb temperature', 'FontSize', 24);


