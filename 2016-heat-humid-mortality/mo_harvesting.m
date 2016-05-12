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

tempVar = tMean;

% remove linear trend and mean
deathsDetrend = detrend(deaths - nanmean(deaths));

% heat wave length
heatLength = 5;

% percentiles to test death anomalies
prcTest = 80:5:100

% starting dates of heat waves for each n
heatWaveInd = {};

heatWaveDeaths = [];

for n = heatLength
    
    heatWaveInd{n} = {};
    testLen = -3:n+10;
    
    for p = 1:length(prcTest)-1
            
        % define heat wave as 3 consec days above 90th percentile of tMax
        tempThreshLow = prctile(tempVar, prcTest(p));
        tempThreshHigh = prctile(tempVar, prcTest(p+1));

        % find starting dates of heat waves
        heatWaveInd{n}{p} = [];
        for i = 1:length(tempVar)-(n-1)

            % search for a heat wave
            wave = true;

            for j = 1:n
                
                % if < 50th percentile end the cold snap when temps rise
                % above the upper end of the percentile bin (so allow
                % colder temps)
                if prcTest(p) < 50
                    if tempVar(i+j-1) > tempThreshHigh
                        wave = false;
                        break;
                    end
                % above the 50th percentile do the opposite, so allow for
                % hotter temperatures
                elseif prcTest(p) > 50
                    if tempVar(i+j-1) < tempThreshLow
                        wave = false;
                        break;
                    end
                elseif prcTest(p) == 50
                    wave = false;
                    break;
                end
            end

            if wave
                heatWaveInd{n}{p}(end+1) = i;
            end
        end
        
        if length(heatWaveInd{n}{p}) < 30
            continue;
        end
        
        % find daily death anomalies 3 days before, during, and after heat
        % event
        
        curHeatWaveDeaths = [];
        
        % loop over all heat events for this percentile
        for h = 1:length(heatWaveInd{n}{p})
            curHeatInd = heatWaveInd{n}{p}(h);
            
            
            % if we are too close to the end of the deaths list
            if curHeatInd + testLen(1) < 1 || curHeatInd + testLen(n) > length(deathsDetrend)
                continue;
            end
            
            for i = 1:length(testLen)
                ind = curHeatInd + testLen(i);
                curHeatWaveDeaths(i, h) = deathsDetrend(ind);
            end
            
        end
        
        heatWaveDeaths = [heatWaveDeaths squeeze(nanmean(curHeatWaveDeaths, 2))];
        
    end
    
end

colors = distinguishable_colors(size(heatWaveDeaths,2));

figure('Color', [1,1,1]);
hold on;
legendStr = 'legend(';
for i = 1:size(heatWaveDeaths, 2)
    plot(testLen, heatWaveDeaths(:, i), 'Color', colors(i, :), 'LineWidth', 2);
    
    if i == size(heatWaveDeaths, 2)
        legendStr = [legendStr '''percentile = ' num2str(prcTest(i)) ''')'];
    else
        legendStr = [legendStr '''percentile = ' num2str(prcTest(i)) ''','];
    end
end
xlabel('Offset from start of heat wave (days)', 'FontSize', 20);
ylabel('Daily death anomaly', 'FontSize', 20);
title('Daily mean temperature, n = 5', 'FontSize', 24);
eval(legendStr);




