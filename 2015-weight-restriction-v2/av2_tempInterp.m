airports = {'LGA'};

obsDir = 'e:\data\flight\wx\output\daily';
obsPeriod = 2010;

for a = 1:length(airports)

    for y = obsPeriod
        tempsMin = loadDailyData([obsDir '\tasmin'], 'yearStart', y, 'yearEnd', y, 'obs', 'daily', 'obsAirport', airports{a});
        tempsMax = loadDailyData([obsDir '\tasmax'], 'yearStart', y, 'yearEnd', y, 'obs', 'daily', 'obsAirport', airports{a});
    end
    
    tempsMax = reshape(tempsMax, [size(tempsMax, 2)*size(tempsMax, 3), 1]);
    
end

% sample a/c at LGA
elevation = 0;
runway = 7000;

maxWeights = [];

nanInd = find(isnan(tempsMax));
tempsMax(nanInd) = [];

for t = 1:length(tempsMax)
    if ~isnan(tempsMax(t))
        curTemp = tempsMax(t);
        
        % performance data starts at 15C
        if curTemp < 15
            curTemp = 15;
        end
        maxWeights(end+1) = av2_findMaxWeight(curTemp, runway, elevation);
    end
end

figure('Color', [1,1,1]);
hold on;
x = 1:length(maxWeights);
plot(x, maxWeights, 'k', 'LineWidth', 2);
ylim([140 180]);
xlabel('Day', 'FontSize', 26);
ylabel('Max takeoff weight', 'FontSize', 26);
title('Take off weight at highest daily temperature (LGA, 2010)', 'FontSize', 30);
set(gca, 'FontSize', 24);