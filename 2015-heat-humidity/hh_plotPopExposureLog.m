
temps = 30:35;

% total explosure in 2070-2080
exposureTotals45 = [];
exposureTotals85 = [];

% error bars for above exposure totals (relative to 0)
exposureErr45 = [];
exposureErr85 = [];

for temp = temps
    load(['heatExposure-ncep-wb-' num2str(temp) '-rcp85-ssp5-world.mat']);
    
    exposureTotals85(end+1) = saveData.futureDecY(end,end);
    exposureErr85(end+1, :) = abs(saveData.futureDecYerr(end,end,:));
    
    % make sure no errors go below 10^0
    for i = 1:length(exposureTotals85)
        if exposureTotals85(i) - exposureErr85(i, 1) <= 0
            exposureErr85(i, 1) = exposureTotals85(i) - 1;
        end
    end
    
    load(['heatExposure-ncep-wb-' num2str(temp) '-rcp45-ssp5-world.mat']);
    
    exposureTotals45(end+1) = saveData.futureDecY(end,end);
    exposureErr45(end+1, :) = abs(saveData.futureDecYerr(end,end,:));
    
    % make sure no errors go below 10^0
    for i = 1:length(exposureTotals45)
        if exposureTotals45(i) - exposureErr45(i, 1) <= 0
            exposureErr45(i, 1) = exposureTotals45(i) - 1;
        end
    end
    
end

mSize = 15;

figure('Color', [1,1,1]);
hold on; box on; axis square; grid on;

e1 = errorbar(temps, exposureTotals85, exposureErr85(:,1)', exposureErr85(:,2)', ...
              'o', 'MarkerSize', mSize, 'LineWidth', 2, 'Color', [221/255.0, 53/255.0, 67/255.0], 'MarkerFaceColor', [221/255.0, 53/255.0, 67/255.0]);
p1 = plot(temps, exposureTotals85, 'ko', 'MarkerSize', mSize, 'LineWidth', 3);

e2 = errorbar(temps, exposureTotals45, exposureErr45(:,1)', exposureErr45(:,2)', ...
              'o', 'MarkerSize', mSize, 'LineWidth', 2, 'Color', [66/255.0, 170/255.0, 244/255.0], 'MarkerFaceColor', [66/255.0, 170/255.0, 244/255.0]);
p2 = plot(temps, exposureTotals45, 'ko', 'MarkerSize', mSize, 'LineWidth', 3);
%p2 = plot(temps, exposureTotals45, 'ko', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', [66/255.0, 170/255.0, 244/255.0]);


set(gca, 'YScale', 'log');
set(gca,'YMinorGrid','Off');
ylim([1, 1e10]);
xlim([29.5 35.5]);
legend([e1, e2], 'RCP 8.5', 'RCP 4.5');

set(gca, 'FontSize', 24);
xlabel(['Wet bulb temperature (' char(176) 'C)'], 'FontSize', 24);
ylabel(['Exposure (person-days)'], 'FontSize', 24);