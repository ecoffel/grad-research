
temps = 30:35;

% total explosure in 2070-2080
exposureTotals45 = [];
exposureTotals85 = [];

% error bars for above exposure totals (relative to 0)
exposureErr45 = [];
exposureErr85 = [];

for temp = temps
    load(['2015-heat-humidity/heat-exposure/heatExposure-ncep-wb-davies-jones-full-' num2str(temp) '-rcp85-ssp5-world.mat']);
    
    exposureTotals85(end+1) = saveData.futureDecY(end,end);
    exposureErr85(end+1, :) = abs(saveData.futureDecYerr(end,end,:));
    
    % make sure no errors go below 10^0
    for i = 1:length(exposureTotals85)
        if exposureTotals85(i) - exposureErr85(i, 1) <= 0
            exposureErr85(i, 1) = exposureTotals85(i) - 1;
        end
    end
    
    load(['2015-heat-humidity/heat-exposure/heatExposure-ncep-wb-davies-jones-full-' num2str(temp) '-rcp45-ssp5-world.mat']);
    
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

e1 = errorbar(temps+0.1, exposureTotals85, exposureErr85(:,1)', exposureErr85(:,2)', ...
              'o', 'MarkerSize', mSize, 'LineWidth', 2, 'Color', [221/255.0, 53/255.0, 67/255.0], 'MarkerFaceColor', [221/255.0, 53/255.0, 67/255.0]);
p1 = plot(temps+0.1, exposureTotals85, 'ko', 'MarkerSize', mSize, 'LineWidth', 3);

e2 = errorbar(temps-0.1, exposureTotals45, exposureErr45(:,1)', exposureErr45(:,2)', ...
              'o', 'MarkerSize', mSize, 'LineWidth', 2, 'Color', [66/255.0, 170/255.0, 244/255.0], 'MarkerFaceColor', [66/255.0, 170/255.0, 244/255.0]);
p2 = plot(temps-0.1, exposureTotals45, 'ko', 'MarkerSize', mSize, 'LineWidth', 3);
%p2 = plot(temps, exposureTotals45, 'ko', 'MarkerSize', 10, 'LineWidth', 2, 'MarkerFaceColor', [66/255.0, 170/255.0, 244/255.0]);


set(gca, 'YScale', 'log');
set(gca,'YMinorGrid','Off');
ylim([0, 1e10]);
set(gca, 'xtick', 30:35);
set(gca, 'ytick', [1 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10], ...
         'yticklabels', {'1', '10,000', '100,000', '1M', '10M', '100M', '1B', '10B'});
xlim([29.5 35.5]);
legend([e1, e2], 'RCP 8.5', 'RCP 4.5', 'location', 'southwest');
legend boxoff;

set(gca, 'FontSize', 40);
xlabel(['T_{W} (' char(176) 'C)']);
ylabel(['Exposure (person-days/year)']);

set(gcf, 'Position', get(0,'Screensize'));
export_fig pop-log.png -m5;
close all;