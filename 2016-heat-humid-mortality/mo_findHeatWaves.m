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

% percentiles to test death anomalies
prcTest = 0:5:100;

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
                    if tempVar(i+j-1) > tempThreshHigh %|| tempVar(i+j-1) >= tempThreshHigh
                        wave = false;
                        break;
                    end
                % above the 50th percentile do the opposite, so allow for
                % hotter temperatures
                elseif prcTest(p) > 50
                    if tempVar(i+j-1) < tempThreshLow %|| tempVar(i+j-1) >= tempThreshHigh
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

            % skip to next non heat wave day
%             while tempVar(i) > tempThreshLow && i < length(tempVar)
%                 i = i + 1;
%             end

            % jump forward by n days
            %i = i + n;
        end
        
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
    
    plot(prcTest(1:end-1), prcAnom(n, :), 'Color', colors(n, :), 'LineWidth', 2);
    
    if n == length(heatLength)
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


